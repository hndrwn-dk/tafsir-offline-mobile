/// Segment types for parsed text
enum SegmentType {
  paragraph, // LTR paragraph text
  arabicQuote, // RTL Arabic quote block
}

/// A parsed segment of text
class TextSegment {
  final SegmentType type;
  final String text;

  const TextSegment({
    required this.type,
    required this.text,
  });

  TextSegment copyWith({SegmentType? type, String? text}) {
    return TextSegment(
      type: type ?? this.type,
      text: text ?? this.text,
    );
  }

  @override
  String toString() => 'TextSegment(type: $type, text: "${text.substring(0, text.length > 30 ? 30 : text.length)}...")';
}

/// Parser for guillemet-quoted Arabic text
/// Extracts «...» quoted sections and splits text into ordered segments
class GuillemetParser {
  /// Pattern to match full guillemet pairs: «...»
  static final _guillemetPattern = RegExp(r'«([\s\S]*?)»', multiLine: true);

  /// Parse text into segments by guillemet quotes
  /// Returns ordered list: [paragraph, arabicQuote, paragraph, ...]
  static List<TextSegment> parseGuillemetQuotes(String input) {
    if (input.trim().isEmpty) {
      return [];
    }

    final segments = <TextSegment>[];
    final matches = _guillemetPattern.allMatches(input);
    
    if (matches.isEmpty) {
      // No guillemet quotes found - check for orphan markers and clean them
      final cleaned = _removeOrphanMarkers(input);
      if (cleaned.trim().isNotEmpty) {
        segments.add(TextSegment(type: SegmentType.paragraph, text: cleaned));
      }
      return segments;
    }

    int lastIndex = 0;

    for (final match in matches) {
      // Add paragraph segment before this quote
      if (match.start > lastIndex) {
        final beforeText = input.substring(lastIndex, match.start);
        final cleaned = _cleanParagraphText(beforeText);
        if (cleaned.trim().isNotEmpty) {
          segments.add(TextSegment(type: SegmentType.paragraph, text: cleaned));
        }
      }

      // Extract Arabic quote content (group 1)
      final quoteText = match.group(1) ?? '';
      final cleanedQuote = quoteText.trim();
      if (cleanedQuote.isNotEmpty) {
        segments.add(TextSegment(type: SegmentType.arabicQuote, text: cleanedQuote));
      }

      lastIndex = match.end;
    }

    // Add remaining text after last quote
    if (lastIndex < input.length) {
      final remainingText = input.substring(lastIndex);
      final cleaned = _cleanParagraphText(remainingText);
      if (cleaned.trim().isNotEmpty) {
        segments.add(TextSegment(type: SegmentType.paragraph, text: cleaned));
      }
    }

    // Post-process: clean punctuation around segment boundaries
    return _cleanSegmentBoundaries(segments);
  }

  /// Remove orphan guillemet markers (no matching pair)
  static String _removeOrphanMarkers(String text) {
    return text.replaceAll('«', '').replaceAll('»', '');
  }

  /// Clean paragraph text: remove any guillemet markers and normalize
  static String _cleanParagraphText(String text) {
    // Remove any stray guillemet markers
    var cleaned = text.replaceAll('«', '').replaceAll('»', '');
    
    // Normalize whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    return cleaned.trim();
  }

  /// Clean punctuation around segment boundaries for better readability
  static List<TextSegment> _cleanSegmentBoundaries(List<TextSegment> segments) {
    if (segments.length <= 1) return segments;

    final cleaned = <TextSegment>[];

    for (int i = 0; i < segments.length; i++) {
      final current = segments[i];
      
      if (current.type == SegmentType.paragraph) {
        var text = current.text;
        
        // General cleanup for English text before Arabic blocks
        if (i + 1 < segments.length && segments[i + 1].type == SegmentType.arabicQuote) {
          text = cleanBeforeArabicBlock(text);
        }
        
        // If previous segment was a quote and this starts with "(", ensure space before it
        if (i > 0 && segments[i - 1].type == SegmentType.arabicQuote) {
          text = text.replaceAll(RegExp(r'^\('), ' (');
        }
        
        cleaned.add(TextSegment(type: SegmentType.paragraph, text: text.trim()));
      } else {
        // Arabic quote - keep as is
        cleaned.add(current);
      }
    }

    return cleaned;
  }

  /// General clean-up for English text before Arabic blocks
  /// Removes artifacts like trailing commas, guillemets, parentheses, etc.
  static String cleanBeforeArabicBlock(String text) {
    var t = text.trimRight();

    // 1) Remove quote artifacts
    t = t
        .replaceAll('«', '')
        .replaceAll('»', '')
        .replaceAll('<<', '')
        .replaceAll('>>', '')
        .trimRight();

    // 2) Remove trailing spaces
    t = t.replaceAll(RegExp(r'[ \t]+$'), '');

    // 3) Remove hanging punctuation at the end (common for transitions before Arabic quotes)
    //    Examples: "... said," / "... Companion," / "... ("
    t = t.replaceAllMapped(RegExp(r'[\s,;–—\-:]+$'), (m) {
      // Note: ":" is sometimes valid, but if it's just a single ":" keep it
      final s = m.group(0)!.trim();
      if (s == ':') {
        return ':'; // Keep single colon
      }
      return ''; // Remove others (including multiple colons, which will be normalized in step 5)
    });

    // 4) If after step 3 it still ends with "(" or "[" or "{" or quotes -> remove
    t = t.replaceAll(RegExp(r'[\(\[\{\"\u201C\u201D""]+$'), '');

    // 5) Normalize: if t ends with a word and no punctuation, leave it
    //    But if it ends with double colon " ::" or " :" clean it to ":"
    t = t.replaceAll(RegExp(r'\s*:\s*$'), ':');

    return t.trimRight();
  }

  /// Convert segments back to HTML string
  /// Paragraphs become <p> tags, Arabic quotes become <arabic> tags
  static String segmentsToHtml(List<TextSegment> segments) {
    final buffer = StringBuffer();
    
    for (final segment in segments) {
      switch (segment.type) {
        case SegmentType.paragraph:
          if (segment.text.trim().isNotEmpty) {
            // Escape HTML entities
            final escaped = segment.text
                .replaceAll('&', '&amp;')
                .replaceAll('<', '&lt;')
                .replaceAll('>', '&gt;');
            buffer.write('<p>$escaped</p>');
          }
          break;
        case SegmentType.arabicQuote:
          if (segment.text.trim().isNotEmpty) {
            // Escape HTML entities
            final escaped = segment.text
                .replaceAll('&', '&amp;')
                .replaceAll('<', '&lt;')
                .replaceAll('>', '&gt;');
            buffer.write('<arabic>$escaped</arabic>');
          }
          break;
      }
    }
    
    return buffer.toString();
  }
}

