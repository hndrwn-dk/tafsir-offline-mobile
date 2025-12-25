import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'arabic_quote_card.dart';
import '../utils/guillemet_parser.dart';

/// TafsirRenderer
/// Renders HTML tafsir content with proper headings, lists, and Arabic blocks
class TafsirRenderer extends StatelessWidget {
  final String raw;
  final EdgeInsetsGeometry padding;
  final double latinFontSize;
  final String arabicFontFamily;

  const TafsirRenderer({
    super.key,
    required this.raw,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 28),
    this.latinFontSize = 16,
    this.arabicFontFamily = 'UthmanicHafs',
  });

  @override
  Widget build(BuildContext context) {
    if (raw.trim().isEmpty) {
      return _EmptyState(padding: padding);
    }

    final cleanedHtml = TafsirSanitizer.toCleanHtml(raw);

    if (cleanedHtml.trim().isEmpty) {
      return _EmptyState(padding: padding);
    }

    return SelectionArea(
      child: SingleChildScrollView(
        padding: padding,
        child: _ArabicBlockWrapper(
          html: _processArabicTags(cleanedHtml),
          styles: _buildStyles(context),
          arabicFontFamily: arabicFontFamily,
        ),
      ),
    );
  }

  /// Convert <arabic> tags to styled divs that flutter_html can render
  String _processArabicTags(String html) {
    return html.replaceAllMapped(
      RegExp(r'<arabic>(.*?)</arabic>', dotAll: true),
      (match) {
        final text = match.group(1) ?? '';
        if (text.trim().isEmpty) return '';
        // Convert to div - use CSS class only, no inline styles to avoid constraint issues
        final escaped = text.trim()
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;');
        return '<div class="arabic-block">$escaped</div>';
      },
    );
  }

  Map<String, Style> _buildStyles(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return {
      'html': Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
      ),
      'body': Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        fontSize: FontSize(latinFontSize),
        lineHeight: const LineHeight(1.85),
        color: cs.onSurface.withValues(alpha: 0.88),
        letterSpacing: 0.1,
      ),
      // Hide headings - render as normal paragraphs for reading-first UI
      'h1': Style(
        fontSize: FontSize(latinFontSize),
        fontWeight: FontWeight.normal,
        margin: Margins.only(top: 16, bottom: 12),
        lineHeight: const LineHeight(1.75),
        color: cs.onSurface,
        display: Display.block,
      ),
      'h2': Style(
        fontSize: FontSize(latinFontSize),
        fontWeight: FontWeight.normal,
        margin: Margins.only(top: 16, bottom: 12),
        lineHeight: const LineHeight(1.75),
        color: cs.onSurface,
        display: Display.block,
      ),
      'h3': Style(
        fontSize: FontSize(latinFontSize),
        fontWeight: FontWeight.normal,
        margin: Margins.only(top: 16, bottom: 12),
        lineHeight: const LineHeight(1.75),
        color: cs.onSurface,
        display: Display.block,
      ),
      'p': Style(
        fontSize: FontSize(latinFontSize),
        lineHeight: const LineHeight(1.85),
        margin: Margins.only(top: 14, bottom: 18),
        display: Display.block,
      ),
      'ul': Style(
        margin: Margins.only(top: 4, bottom: 12),
        padding: HtmlPaddings.only(left: 18),
      ),
      'ol': Style(
        margin: Margins.only(top: 4, bottom: 12),
        padding: HtmlPaddings.only(left: 18),
      ),
      'li': Style(
        margin: Margins.only(bottom: 8),
        lineHeight: const LineHeight(1.6),
      ),
      // Render <strong> as normal text (no bold inference)
      'strong': Style(
        fontWeight: FontWeight.normal,
      ),
      'em': Style(
        fontStyle: FontStyle.italic,
      ),
      // Arabic blocks styling - will be replaced by custom premium card widget
      '.arabic-block': Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        display: Display.block,
      ),
    };
  }
}

/// Wrapper widget that replaces Arabic blocks with custom premium cards
class _ArabicBlockWrapper extends StatelessWidget {
  final String html;
  final Map<String, Style> styles;
  final String arabicFontFamily;

  const _ArabicBlockWrapper({
    required this.html,
    required this.styles,
    required this.arabicFontFamily,
  });

  @override
  Widget build(BuildContext context) {
    // Extract Arabic blocks and replace with custom widgets
    final arabicPattern = RegExp(r'<div class="arabic-block">(.*?)</div>', dotAll: true);
    final matches = arabicPattern.allMatches(html);

    if (matches.isEmpty) {
      // No Arabic blocks, render normally
      return Html(
        data: html,
        style: styles,
      );
    }

    // Build widget tree with custom Arabic cards
    final widgets = <Widget>[];
    int lastIndex = 0;

    for (final match in matches) {
      // Add content before Arabic block
      if (match.start > lastIndex) {
        final beforeHtml = html.substring(lastIndex, match.start);
        if (beforeHtml.trim().isNotEmpty) {
          widgets.add(
            Html(
              data: beforeHtml,
              style: styles,
            ),
          );
        }
      }

      // Extract Arabic text
      final arabicText = match.group(1) ?? '';
      if (arabicText.trim().isNotEmpty) {
        // Decode HTML entities
        final decoded = arabicText
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'");

        widgets.add(
          ArabicQuoteCard(
            arabic: decoded,
            fontFamily: arabicFontFamily,
            fontSize: 24,
            lineHeight: 2.15,
          ),
        );
      }

      lastIndex = match.end;
    }

    // Add remaining content
    if (lastIndex < html.length) {
      final remainingHtml = html.substring(lastIndex);
      if (remainingHtml.trim().isNotEmpty) {
        widgets.add(
          Html(
            data: remainingHtml,
            style: styles,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}

/// Empty State Widget
class _EmptyState extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  const _EmptyState({required this.padding});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Text(
          "Tafsir tidak tersedia untuk ayat ini.",
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
        ),
      ),
    );
  }
}

/// Sanitizer for Tafsir HTML content
class TafsirSanitizer {
  // Arabic Unicode ranges
  static final _arabicPattern = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]+');

  static String toCleanHtml(String input) {
    var s = input;

    if (s.trim().isEmpty) return '';

    s = s.replaceAll('\r\n', '\n');

    // Check if input is plain text (no HTML tags) or HTML
    final hasHtmlTags = RegExp(r'<[^>]+>').hasMatch(s);
    
    // If plain text, wrap in <p> tags (NO auto-heading detection)
    if (!hasHtmlTags) {
      s = _plainTextToHtml(s);
    }

    // a) Remove artifacts like $1, $12
    s = s.replaceAll(RegExp(r'\$\d+'), '');

    // b) Normalize &nbsp and \u00A0 to spaces
    s = s.replaceAll('&nbsp;', ' ').replaceAll('\u00A0', ' ');

    // c) Convert <div class="arabic ...">...</div> to <arabic>...</arabic>
    s = s.replaceAllMapped(
      RegExp(
        r'<div[^>]*class="[^"]*\barabic\b[^"]*"[^>]*>(.*?)</div>',
        caseSensitive: false,
        dotAll: true,
      ),
      (m) => '<arabic>${m[1] ?? ''}</arabic>',
    );

    // d) Process guillemet quotes BEFORE other processing
    // This ensures «...» quoted Arabic is extracted cleanly
    s = _processGuillemetQuotes(s);

    // e) Fix punctuation spacing (only in text content, not HTML tags)
    s = s.replaceAllMapped(
      RegExp(r'>([^<]+)<', dotAll: true),
      (match) {
        var text = match.group(1) ?? '';
        if (text.trim().isEmpty) return match.group(0) ?? '';

        // Fix missing spaces after punctuation and between lowercase->Uppercase
        // Pattern 1: ([A-Za-z])\.([A-Z]) => "$1. $2" (e.g., "scholars.In" -> "scholars. In")
        text = text.replaceAllMapped(
          RegExp(r'([A-Za-z])\.([A-Z])'),
          (m) => '${m[1]}. ${m[2]}',
        );

        // Pattern 2: ([A-Za-z])([,;:!?])([A-Za-z]) => "$1$2 $3"
        text = text.replaceAllMapped(
          RegExp(r'([A-Za-z])([,;:!?])([A-Za-z])'),
          (m) => '${m[1]}${m[2]} ${m[3]}',
        );

        // Pattern 3: Fix lowercase->Uppercase boundaries (e.g., "FatihahWhich" -> "Fatihah Which")
        text = text.replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => '${m[1]} ${m[2]}',
        );

        // Pattern 4: Fix missing space after punctuation followed by capital
        // (e.g., "MakkahThe" -> "Makkah The" - but this is already covered by pattern 3)

        return '>$text<';
      },
    );

    // f) Extract INLINE Arabic runs from inside <p>...</p> (but skip if already processed as guillemet quotes)
    s = _extractInlineArabicFromParagraphs(s);

    // g) Split sentences ONLY within <p> tags (not in headings, lists, or arabic blocks)
    s = _splitSentencesInParagraphs(s);

    // h) Ensure heading spacing
    s = s.replaceAll('</h2><p', '</h2><p></p><p');
    s = s.replaceAll('</h1><h2', '</h1><p></p><h2');
    s = s.replaceAll('</h1><p', '</h1><p></p><p');
    s = s.replaceAll('</h3><p', '</h3><p></p><p');

    // Normalize excessive spaces
    s = s.replaceAll(RegExp(r'[ \t]{2,}'), ' ');

    // Remove empty paragraphs
    s = s.replaceAll(RegExp(r'<p>\s*</p>', caseSensitive: false), '');

    return s.trim();
  }

  /// Process guillemet quotes «...» in text content
  /// Extracts quoted sections and converts them to <arabic> blocks
  static String _processGuillemetQuotes(String html) {
    // Process each paragraph separately to handle guillemet quotes
    return html.replaceAllMapped(
      RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true),
      (match) {
        final content = match.group(1) ?? '';
        if (content.trim().isEmpty) return match.group(0) ?? '';

        // Check if paragraph contains guillemet quotes
        if (!content.contains('«') && !content.contains('»')) {
          return match.group(0) ?? '';
        }

        // Decode HTML entities first
        var decodedContent = content
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'");

        // Remove HTML tags inside paragraph (like <strong>, <span>, etc.)
        // We'll preserve structure but extract text for parsing
        decodedContent = decodedContent.replaceAll(RegExp(r'<[^>]+>'), '');

        // Parse guillemet quotes
        final segments = GuillemetParser.parseGuillemetQuotes(decodedContent);

        if (segments.isEmpty) {
          return match.group(0) ?? '';
        }

        // Convert segments back to HTML
        return GuillemetParser.segmentsToHtml(segments);
      },
    );
  }

  /// Extract inline Arabic runs from paragraphs and convert to <arabic> blocks
  /// Merges adjacent Arabic runs separated only by spaces/punctuation
  /// NOTE: Skips paragraphs that already contain <arabic> tags (from guillemet processing)
  static String _extractInlineArabicFromParagraphs(String html) {
    // Process each paragraph separately
    return html.replaceAllMapped(
      RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true),
      (match) {
        final content = match.group(1) ?? '';
        if (content.trim().isEmpty) return match.group(0) ?? '';

        // Skip if paragraph already contains <arabic> tags (from guillemet processing)
        if (content.contains('<arabic>')) {
          return match.group(0) ?? '';
        }

        // First, check if paragraph contains Arabic characters directly
        final hasArabic = _arabicPattern.hasMatch(content);
        if (!hasArabic) {
          return match.group(0) ?? '';
        }

        // Decode HTML entities first
        var decodedContent = content
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'");

        // Remove HTML tags inside paragraph (like <strong>, <span>, etc.)
        decodedContent = decodedContent.replaceAllMapped(
          RegExp(r'<[^>]+>'),
          (m) => '', // Remove tags but keep text
        );

        // Split content into segments by Arabic runs
        final segments = _splitByArabicRuns(decodedContent);

        // Merge adjacent Arabic runs separated only by spaces/punctuation
        final mergedSegments = _mergeAdjacentArabicRuns(segments);

        // If no Arabic found after processing, return original paragraph
        if (mergedSegments.every((seg) => !_isArabicSegment(seg))) {
          return match.group(0) ?? '';
        }

        // Build output: separate <p> for Latin, <arabic> for Arabic
        final output = StringBuffer();
        StringBuffer? currentParagraph;
        bool hasContent = false;

        for (final segment in mergedSegments) {
          final trimmed = segment.trim();
          if (trimmed.isEmpty) continue;

          if (_isArabicSegment(trimmed)) {
            // Close any open paragraph before Arabic block
            if (currentParagraph != null) {
              // Clean up English text before Arabic block
              final paragraphText = currentParagraph.toString();
              final cleaned = GuillemetParser.cleanBeforeArabicBlock(paragraphText);
              output.write('<p>');
              output.write(cleaned);
              output.write('</p>');
              currentParagraph = null;
            }

            // Only create Arabic card if meaningful (>=24 chars OR >=3 words OR has Quran markers)
            if (_arabicRunIsMeaningful(trimmed)) {
              // Escape HTML entities in Arabic text
              final escaped = trimmed
                  .replaceAll('&', '&amp;')
                  .replaceAll('<', '&lt;')
                  .replaceAll('>', '&gt;');
              output.write('<arabic>$escaped</arabic>');
              hasContent = true;
            } else {
              // Keep short Arabic inline - add to current paragraph
              if (currentParagraph == null) {
                currentParagraph = StringBuffer();
              } else {
                currentParagraph.write(' ');
              }
              currentParagraph.write(trimmed);
              hasContent = true;
            }
          } else {
            // Latin text - add to current paragraph
            if (currentParagraph == null) {
              currentParagraph = StringBuffer();
            } else {
              currentParagraph.write(' ');
            }
            currentParagraph.write(trimmed);
            hasContent = true;
          }
        }

        // Close any remaining paragraph
        if (currentParagraph != null) {
          output.write('<p>');
          output.write(currentParagraph.toString());
          output.write('</p>');
        }

        return hasContent ? output.toString() : match.group(0) ?? '';
      },
    );
  }

  /// Merge adjacent Arabic runs separated only by spaces or punctuation
  static List<String> _mergeAdjacentArabicRuns(List<String> segments) {
    if (segments.length <= 1) return segments;

    final merged = <String>[];
    StringBuffer? arabicBuffer;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final isArabic = _isArabicSegment(seg);

      if (isArabic) {
        if (arabicBuffer == null) {
          arabicBuffer = StringBuffer(seg);
        } else {
          // Merge with previous Arabic run
          arabicBuffer.write(' ');
          arabicBuffer.write(seg);
        }
      } else {
        // Non-Arabic segment
        // If we have accumulated Arabic, flush it first
        if (arabicBuffer != null) {
          merged.add(arabicBuffer.toString());
          arabicBuffer = null;
        }

        // Check if this is just spacing/punctuation between Arabic runs
        final trimmed = seg.trim();
        if (trimmed.isEmpty || RegExp(r'^[\s\p{P}]+$', unicode: true).hasMatch(trimmed)) {
          // Skip pure spacing/punctuation - it will be merged with Arabic
          continue;
        }

        merged.add(seg);
      }
    }

    // Flush any remaining Arabic
    if (arabicBuffer != null) {
      merged.add(arabicBuffer.toString());
    }

    return merged;
  }

  /// Count Arabic characters in a string
  static int _countArabicChars(String text) {
    int count = 0;
    for (final r in text.runes) {
      final ch = String.fromCharCode(r);
      if (_arabicPattern.hasMatch(ch)) {
        count++;
      }
    }
    return count;
  }

  /// Split text into segments by Arabic runs
  /// More aggressive splitting to catch Arabic even with mixed content
  static List<String> _splitByArabicRuns(String text) {
    final segments = <String>[];
    final buffer = StringBuffer();
    bool? currentIsArabic;

    for (final r in text.runes) {
      final ch = String.fromCharCode(r);
      final isAr = _arabicPattern.hasMatch(ch);

      if (currentIsArabic == null) {
        currentIsArabic = isAr;
        buffer.write(ch);
      } else if (currentIsArabic == isAr) {
        buffer.write(ch);
      } else {
        // Switch detected - flush buffer
        if (buffer.length > 0) {
          segments.add(buffer.toString());
          buffer.clear();
        }
        currentIsArabic = isAr;
        buffer.write(ch);
      }
    }

    if (buffer.length > 0) {
      segments.add(buffer.toString());
    }

    // If no segments found, return original text
    if (segments.isEmpty) {
      return [text];
    }

    // Post-process: merge very small non-Arabic segments with adjacent Arabic if needed
    final processed = <String>[];
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final isAr = _isArabicSegment(seg);
      
      if (isAr) {
        processed.add(seg);
      } else {
        // For non-Arabic, check if it's very small and merge with next if Arabic
        if (seg.trim().length <= 3 && i + 1 < segments.length && _isArabicSegment(segments[i + 1])) {
          // Merge small non-Arabic with next Arabic
          processed.add('$seg ${segments[i + 1]}');
          i++; // Skip next segment as it's merged
        } else {
          processed.add(seg);
        }
      }
    }

    return processed;
  }

  /// Check if segment is Arabic
  static bool _isArabicSegment(String text) {
    return _arabicPattern.hasMatch(text);
  }

  /// Check if Arabic run is meaningful (>=5 chars OR >=2 words)
  /// Check if Arabic segment is meaningful enough to be a separate card
  /// Must meet ONE of:
  /// - Arabic length >= 24 characters OR
  /// - contains >= 3 Arabic words OR
  /// - contains Quran markers (۝ ۗ ۚ ۖ ۘ etc)
  static bool _arabicRunIsMeaningful(String segment) {
    // Check for Quran markers first (most reliable indicator)
    final quranMarkerPattern = RegExp(r'[۝ۗۚۖۘۙۛۜ]');
    if (quranMarkerPattern.hasMatch(segment)) {
      return true;
    }

    // Count Arabic characters
    final arabicCharCount = _countArabicChars(segment);
    if (arabicCharCount >= 24) {
      return true;
    }

    // Check word count (split by whitespace and count Arabic words)
    final words = segment.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    int arabicWordCount = 0;
    for (final word in words) {
      if (_arabicPattern.hasMatch(word)) {
        arabicWordCount++;
      }
    }

    return arabicWordCount >= 3;
  }

  /// Convert plain text to HTML - NO auto-heading detection
  /// Only wraps text in <p> tags, preserves existing structure
  /// Headings MUST come from HTML tags only (<h1>..<h6>)
  static String _plainTextToHtml(String text) {
    if (text.trim().isEmpty) return '';

    // Split by double newlines to preserve paragraph structure
    final paragraphs = text.split(RegExp(r'\n{2,}'));
    
    final buffer = StringBuffer();
    for (final para in paragraphs) {
      final trimmed = para.trim();
      if (trimmed.isEmpty) continue;
      
      // Process Arabic extraction and wrap in <p>
      buffer.write('<p>');
      buffer.write(_processLineForArabic(trimmed));
      buffer.writeln('</p>');
    }
    
    // If no paragraphs found, wrap entire text
    if (buffer.isEmpty) {
      buffer.write('<p>');
      buffer.write(_processLineForArabic(text.trim()));
      buffer.writeln('</p>');
    }

    return buffer.toString();
  }

  /// Split sentences ONLY within <p> tags
  /// Does NOT touch headings, lists, or arabic blocks
  static String _splitSentencesInParagraphs(String html) {
    // Process each <p>...</p> block separately
    return html.replaceAllMapped(
      RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true),
      (match) {
        final pContent = match.group(1) ?? '';
        if (pContent.trim().isEmpty) return match.group(0) ?? '';
        
        // Skip if content contains <arabic> tags (already processed)
        if (pContent.contains('<arabic>')) {
          return match.group(0) ?? '';
        }
        
        // Split sentences within this paragraph
        final splitContent = _splitSentences(pContent);
        
        // If split occurred, the content already has <p>...</p></p><p>...</p></p> structure
        // Return it as-is since it's already properly wrapped
        if (splitContent.contains('</p><p>')) {
          return splitContent;
        } else {
          // No split, return original
          return '<p>$pContent</p>';
        }
      },
    );
  }

  /// Split text into sentences, protected abbreviations, decimals, and Quran refs
  static String _splitSentences(String text) {
    // Step 1: Protect abbreviations, decimals, and Quran references
    final protected = <String, String>{};
    int placeholderIndex = 0;
    
    // Protect abbreviations: e.g., i.e., etc., Dr., Mr., Mrs., Ms., No., vs., al., St.
    text = text.replaceAllMapped(
      RegExp(r'\b(e\.g\.|i\.e\.|etc\.|Dr\.|Mr\.|Mrs\.|Ms\.|No\.|vs\.|al\.|St\.)\s*', caseSensitive: false),
      (m) {
        final placeholder = '__PROTECT_${placeholderIndex}__';
        protected[placeholder] = m.group(0)!;
        placeholderIndex++;
        return placeholder;
      },
    );
    
    // Protect decimals: 3.14, 2.5, etc.
    text = text.replaceAllMapped(
      RegExp(r'\b\d+\.\d+\b'),
      (m) {
        final placeholder = '__PROTECT_${placeholderIndex}__';
        protected[placeholder] = m.group(0)!;
        placeholderIndex++;
        return placeholder;
      },
    );
    
    // Protect Quran references: (26:23-24), (18:50), etc.
    text = text.replaceAllMapped(
      RegExp(r'\(\d+:\d+(?:-\d+)?\)'),
      (m) {
        final placeholder = '__PROTECT_${placeholderIndex}__';
        protected[placeholder] = m.group(0)!;
        placeholderIndex++;
        return placeholder;
      },
    );
    
    // Step 2: Split by sentence endings (. ! ?) followed by space
    // Pattern: punctuation followed by space (and optionally capital letter)
    final sentencePattern = RegExp(r'([.!?])\s+');
    final sentences = <String>[];
    int lastIndex = 0;
    
    for (final match in sentencePattern.allMatches(text)) {
      // Extract sentence including punctuation
      final sentence = text.substring(lastIndex, match.start + 1).trim();
      if (sentence.isNotEmpty) {
        sentences.add(sentence);
      }
      lastIndex = match.end;
    }
    
    // Add remaining text
    if (lastIndex < text.length) {
      final remaining = text.substring(lastIndex).trim();
      if (remaining.isNotEmpty) {
        sentences.add(remaining);
      }
    }
    
    // If only one sentence, return as-is (no split needed)
    if (sentences.length <= 1) {
      var result = text;
      // Restore protected content
      protected.forEach((placeholder, original) {
        result = result.replaceAll(placeholder, original);
      });
      return result;
    }
    
    // Join sentences with </p><p> tags
    // First sentence starts with <p>, subsequent sentences separated by </p><p>, last ends with </p>
    final buffer = StringBuffer();
    buffer.write('<p>');
    for (int i = 0; i < sentences.length; i++) {
      if (i > 0) {
        buffer.write('</p><p>');
      }
      buffer.write(sentences[i]);
    }
    buffer.write('</p>');
    
    var result = buffer.toString();
    
    // Step 3: Restore protected content
    protected.forEach((placeholder, original) {
      result = result.replaceAll(placeholder, original);
    });
    
    return result;
  }


  /// Process a line: extract Arabic and create proper HTML structure
  /// Multiple Arabic runs that are close together should be combined into one block
  static String _processLineForArabic(String line) {
    // Split by Arabic runs
    final segments = _splitByArabicRuns(line);
    
    final buffer = StringBuffer();
    final arabicBuffer = StringBuffer();
    bool lastWasArabic = false;
    
    for (final segment in segments) {
      final trimmed = segment.trim();
      if (trimmed.isEmpty) continue;
      
      if (_isArabicSegment(trimmed)) {
        // If this is Arabic and previous was also Arabic, accumulate
        if (lastWasArabic) {
          // Add space between Arabic runs if needed
          if (arabicBuffer.isNotEmpty && !arabicBuffer.toString().endsWith(' ')) {
            arabicBuffer.write(' ');
          }
          arabicBuffer.write(trimmed);
        } else {
          // Previous was Latin, flush any accumulated Arabic first
          if (arabicBuffer.isNotEmpty) {
            final accumulated = arabicBuffer.toString().trim();
            if (_arabicRunIsMeaningful(accumulated)) {
              buffer.write('<arabic>$accumulated</arabic>');
            } else {
              buffer.write(accumulated);
            }
            arabicBuffer.clear();
          }
          // Start new Arabic accumulation
          arabicBuffer.write(trimmed);
          lastWasArabic = true;
        }
      } else {
        // This is Latin text
        // If we were accumulating Arabic, flush it first
        if (lastWasArabic && arabicBuffer.isNotEmpty) {
          final accumulated = arabicBuffer.toString().trim();
          if (_arabicRunIsMeaningful(accumulated)) {
            buffer.write('<arabic>$accumulated</arabic>');
          } else {
            buffer.write(accumulated);
          }
          arabicBuffer.clear();
        }
        lastWasArabic = false;
        
        // Add Latin text
        buffer.write(trimmed);
        buffer.write(' ');
      }
    }
    
    // Flush any remaining Arabic
    if (arabicBuffer.isNotEmpty) {
      final accumulated = arabicBuffer.toString().trim();
      if (_arabicRunIsMeaningful(accumulated)) {
        buffer.write('<arabic>$accumulated</arabic>');
      } else {
        buffer.write(accumulated);
      }
    }
    
    return buffer.toString().trim();
  }
}
