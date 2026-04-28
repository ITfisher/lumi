/// Lightweight markdown helpers used across the app.
///
/// We persist the task notes as a Markdown string (see `MarkdownEditor`),
/// but in cards / list rows we want a calm, plain-text preview without
/// stray `**`, `[]()`, `- [ ]` artefacts.  This is intentionally a regex
/// stripper — not a full parser — and is good enough for a 2-3 line preview.
library;

/// Convert a markdown string to a single-line plain-text preview.
///
/// • Drops fenced/inline code, images, headings markers, list/quote markers,
///   blockquotes, horizontal rules, html tags, footnotes.
/// • Keeps the visible text inside bold / italic / strikethrough / links.
/// • Renders task checkboxes as `☐` / `☑` so the preview still reads as a list.
/// • Collapses runs of whitespace into a single space.
///
/// Returns an empty string for null / blank input.
String stripMarkdown(String? input) {
  if (input == null) return '';
  var s = input;
  if (s.trim().isEmpty) return '';

  // 1. Drop fenced code blocks entirely (```lang ... ```).
  s = s.replaceAll(
    RegExp(r'```[\s\S]*?```', multiLine: true),
    ' ',
  );

  // 2. Drop HTML tags.
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');

  // 3. Images:  ![alt](url)  →  drop entirely.
  s = s.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '');

  // 4. Links:  [text](url)  →  text
  s = s.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
    (m) => m.group(1) ?? '',
  );

  // 5. Reference-style links:  [text][ref]  →  text
  s = s.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\[[^\]]*\]'),
    (m) => m.group(1) ?? '',
  );

  // 6. Process line-by-line markers (heading / list / quote / hr / todo).
  final lines = s.split('\n').map(_stripLineMarkers).toList();
  s = lines.join(' ');

  // 7. Inline emphasis — bold/italic/strikethrough.
  //    Order matters: handle strong (`**x**` / `__x__`) before em (`*x*` / `_x_`).
  s = s.replaceAllMapped(
    RegExp(r'\*\*(.+?)\*\*'),
    (m) => m.group(1) ?? '',
  );
  s = s.replaceAllMapped(
    RegExp(r'__(.+?)__'),
    (m) => m.group(1) ?? '',
  );
  s = s.replaceAllMapped(
    RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'),
    (m) => m.group(1) ?? '',
  );
  s = s.replaceAllMapped(
    RegExp(r'(?<!_)_(?!_)(.+?)(?<!_)_(?!_)'),
    (m) => m.group(1) ?? '',
  );
  s = s.replaceAllMapped(
    RegExp(r'~~(.+?)~~'),
    (m) => m.group(1) ?? '',
  );

  // 8. Inline code:  `code`  →  code
  s = s.replaceAllMapped(
    RegExp(r'`([^`]+)`'),
    (m) => m.group(1) ?? '',
  );

  // 9. Collapse whitespace.
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

/// Strip block-level line markers from a single line.
String _stripLineMarkers(String raw) {
  var line = raw;

  // Trim leading whitespace but remember it for indentation-aware logic.
  final leading = RegExp(r'^\s*').firstMatch(line)?.group(0) ?? '';
  line = line.substring(leading.length);

  // Horizontal rule → drop the line.
  if (RegExp(r'^([-*_])\s*\1\s*\1[\s\1]*$').hasMatch(line)) {
    return '';
  }

  // ATX headings:  #, ##, ### …
  final heading = RegExp(r'^#{1,6}\s+').firstMatch(line);
  if (heading != null) {
    line = line.substring(heading.end);
  }

  // Blockquotes: >, >>, > >
  while (RegExp(r'^>\s?').hasMatch(line)) {
    line = line.replaceFirst(RegExp(r'^>\s?'), '');
  }

  // Task list:  - [ ]  /  - [x]
  final task = RegExp(r'^[-*+]\s+\[([ xX])\]\s+').firstMatch(line);
  if (task != null) {
    final checked = (task.group(1) ?? '').toLowerCase() == 'x';
    line = '${checked ? '☑' : '☐'} ${line.substring(task.end)}';
    return line;
  }

  // Unordered list:  -, *, +
  final ul = RegExp(r'^[-*+]\s+').firstMatch(line);
  if (ul != null) {
    line = line.substring(ul.end);
  }

  // Ordered list:  1.  2)  …
  final ol = RegExp(r'^\d+[.)]\s+').firstMatch(line);
  if (ol != null) {
    line = line.substring(ol.end);
  }

  return line;
}
