import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/core/utils/markdown_utils.dart';

void main() {
  group('stripMarkdown', () {
    test('returns empty for null / blank', () {
      expect(stripMarkdown(null), '');
      expect(stripMarkdown(''), '');
      expect(stripMarkdown('   \n  \t '), '');
    });

    test('strips heading markers but keeps the text', () {
      expect(stripMarkdown('# Hello'), 'Hello');
      expect(stripMarkdown('### Sub'), 'Sub');
    });

    test('strips bold / italic / strikethrough wrappers', () {
      expect(stripMarkdown('**bold** word'), 'bold word');
      expect(stripMarkdown('a *italic* b'), 'a italic b');
      expect(stripMarkdown('a _italic_ b'), 'a italic b');
      expect(stripMarkdown('~~old~~ new'), 'old new');
    });

    test('inline code keeps the inner text', () {
      expect(stripMarkdown('use `flutter run` to start'), 'use flutter run to start');
    });

    test('fenced code blocks are dropped entirely', () {
      const md = 'before\n```dart\nfinal x = 1;\n```\nafter';
      expect(stripMarkdown(md), 'before after');
    });

    test('links keep their visible text only', () {
      expect(stripMarkdown('see [docs](https://example.com)'), 'see docs');
    });

    test('images are dropped', () {
      expect(stripMarkdown('hi ![logo](a.png) bye'), 'hi bye');
    });

    test('list bullets are stripped', () {
      const md = '- one\n- two\n* three\n+ four';
      expect(stripMarkdown(md), 'one two three four');
    });

    test('ordered list markers are stripped', () {
      const md = '1. one\n2. two\n10) ten';
      expect(stripMarkdown(md), 'one two ten');
    });

    test('task list checkboxes render as ☐ / ☑', () {
      const md = '- [ ] open\n- [x] done\n- [X] also done';
      expect(stripMarkdown(md), '☐ open ☑ done ☑ also done');
    });

    test('blockquotes lose their marker', () {
      expect(stripMarkdown('> quoted'), 'quoted');
      expect(stripMarkdown('> > nested'), 'nested');
    });

    test('multiline collapses to single line of preview text', () {
      const md = '# Title\n\nSome **bold** intro.\n\n- a\n- b\n';
      expect(stripMarkdown(md), 'Title Some bold intro. a b');
    });

    test('html tags are stripped', () {
      expect(stripMarkdown('hi <b>there</b>!'), 'hi there!');
    });
  });
}
