import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/clipboard_image_service.dart';
import '../theme/app_theme.dart';

/// Bear-style WYSIWYG Markdown editor.
///
/// The document is edited as rendered blocks with Markdown shortcuts, then
/// serialized back to Markdown for persistence.
class MarkdownEditorController {
  EditorState? _state;

  String get markdown {
    final st = _state;
    if (st == null) return '';
    return documentToMarkdown(st.document).trim();
  }

  void _attach(EditorState state) => _state = state;
  void _detach() => _state = null;
}

class MarkdownEditor extends StatefulWidget {
  final String? initialMarkdown;
  final MarkdownEditorController? controller;
  final ValueChanged<String>? onChanged;
  final double height;
  final bool autoFocus;
  final bool readOnly;

  const MarkdownEditor({
    super.key,
    this.initialMarkdown,
    this.controller,
    this.onChanged,
    this.height = 180,
    this.autoFocus = false,
    this.readOnly = false,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  static const _imageNodeType = 'image';
  static const _imageNodeUrlKey = 'url';
  static const _imageNodeAlignKey = 'align';
  static const _imageNodeHeightKey = 'height';
  static const _imageNodeWidthKey = 'width';

  late EditorState _editorState;
  late EditorScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final initial = (widget.initialMarkdown ?? '').trim();
    final document =
        initial.isEmpty ? _blankDocument() : _safeParseMarkdown(initial);

    _editorState = EditorState(document: document);
    _scrollController = EditorScrollController(editorState: _editorState);
    widget.controller?._attach(_editorState);
    if (widget.onChanged != null) {
      _editorState.transactionStream.listen(_onTransaction);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _scrollController.dispose();
    _editorState.dispose();
    super.dispose();
  }

  Document _blankDocument() => Document.blank(withInitialText: true);

  Document _safeParseMarkdown(String md) {
    try {
      return markdownToDocument(md);
    } catch (_) {
      return _blankDocument();
    }
  }

  void _onTransaction(dynamic _) {
    widget.onChanged?.call(documentToMarkdown(_editorState.document));
  }

  KeyEventResult _handlePasteCommand(EditorState editorState) {
    final selection = editorState.selection;
    if (selection == null) return KeyEventResult.ignored;

    () async {
      final imagePath = await ClipboardImageService.persistClipboardImage();
      if (imagePath != null) {
        await _insertImage(editorState, imagePath);
        return;
      }
      handlePaste(editorState);
    }();

    return KeyEventResult.handled;
  }

  Future<void> _insertImage(EditorState editorState, String imagePath) async {
    final selection = await editorState.deleteSelectionIfNeeded();
    if (selection == null || !selection.isCollapsed) return;

    final node = editorState.getNodeAtPath(selection.end.path);
    if (node == null) return;

    final transaction = editorState.transaction;
    final imageNode = Node(
      type: _imageNodeType,
      attributes: {
        _imageNodeUrlKey: imagePath,
        _imageNodeAlignKey: 'center',
        _imageNodeHeightKey: null,
        _imageNodeWidthKey: null,
      },
    );

    if (node.type == ParagraphBlockKeys.type &&
        (node.delta?.isEmpty ?? false)) {
      transaction
        ..insertNode(node.path, imageNode)
        ..deleteNode(node);
    } else {
      transaction.insertNode(node.path.next, imageNode);
    }

    transaction.afterSelection = Selection.collapsed(
      Position(path: node.path.next, offset: 0),
    );
    await editorState.apply(transaction);
  }

  List<CommandShortcutEvent> _commandShortcutEvents() {
    if (widget.readOnly) return standardCommandShortcutEvents;

    return standardCommandShortcutEvents.map((event) {
      if (event.key == pasteCommand.key) {
        return event.copyWith(handler: _handlePasteCommand);
      }
      return event;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final style = EditorStyle.desktop(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      cursorColor: AppTheme.accentBlue,
      selectionColor: AppTheme.accentBlue.withValues(alpha: 0.18),
      textStyleConfiguration: TextStyleConfiguration(
        text: AppTheme.body(size: 14, height: 1.32),
        bold: const TextStyle(fontWeight: FontWeight.w700),
        italic: const TextStyle(fontStyle: FontStyle.italic),
        underline: const TextStyle(decoration: TextDecoration.underline),
        strikethrough: const TextStyle(decoration: TextDecoration.lineThrough),
        href: TextStyle(
          color: AppTheme.accentBlue,
          decoration: TextDecoration.underline,
          decorationColor: AppTheme.accentBlue.withValues(alpha: 0.4),
        ),
        code: AppTheme.mono(size: 13, color: AppTheme.fgPrimary).copyWith(
          backgroundColor: const Color(0x14000000),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: widget.readOnly ? Colors.transparent : const Color(0x80FFFFFF),
        borderRadius: radius,
        boxShadow: widget.readOnly
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      foregroundDecoration: widget.readOnly
          ? null
          : BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppTheme.glassBorderMedium, width: 1),
            ),
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: widget.height,
          child: AppFlowyEditor(
            editorState: _editorState,
            editorScrollController: _scrollController,
            editorStyle: style,
            blockComponentBuilders: _bearBlockBuilders(),
            commandShortcutEvents: _commandShortcutEvents(),
            shrinkWrap: false,
            autoFocus: widget.autoFocus,
            editable: !widget.readOnly,
          ),
        ),
      ),
    );
  }

  Map<String, BlockComponentBuilder> _bearBlockBuilders() {
    final baseConfiguration = BlockComponentConfiguration(
      padding: _blockPadding,
      indentPadding: _indentPadding,
      placeholderText: _placeholderText,
      placeholderTextStyle: _placeholderStyle,
    );

    return {
      ...standardBlockComponentBuilderMap,
      ParagraphBlockKeys.type: ParagraphBlockComponentBuilder(
        configuration: baseConfiguration,
      ),
      BulletedListBlockKeys.type: BulletedListBlockComponentBuilder(
        configuration: baseConfiguration,
      ),
      NumberedListBlockKeys.type: NumberedListBlockComponentBuilder(
        configuration: baseConfiguration,
      ),
      TodoListBlockKeys.type: TodoListBlockComponentBuilder(
        configuration: baseConfiguration,
        toggleChildrenTriggers: [
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.shiftLeft,
          LogicalKeyboardKey.shiftRight,
        ],
      ),
      HeadingBlockKeys.type: HeadingBlockComponentBuilder(
        configuration: baseConfiguration,
      ),
      QuoteBlockKeys.type: QuoteBlockComponentBuilder(
        configuration: baseConfiguration,
      ),
    };
  }

  EdgeInsets _blockPadding(Node node) {
    switch (node.type) {
      case BulletedListBlockKeys.type:
      case NumberedListBlockKeys.type:
      case TodoListBlockKeys.type:
        return const EdgeInsets.symmetric(vertical: 1.0);
      case HeadingBlockKeys.type:
        return const EdgeInsets.symmetric(vertical: 3.0);
      default:
        return const EdgeInsets.symmetric(vertical: 2.0);
    }
  }

  EdgeInsets _indentPadding(Node node, TextDirection textDirection) {
    switch (textDirection) {
      case TextDirection.ltr:
        return const EdgeInsets.only(left: 18);
      case TextDirection.rtl:
        return const EdgeInsets.only(right: 18);
    }
  }

  String _placeholderText(Node node) {
    if (node.type == BulletedListBlockKeys.type ||
        node.type == NumberedListBlockKeys.type) {
      return 'List item';
    }
    if (node.type == TodoListBlockKeys.type) return 'To-do';
    return 'Write notes in Markdown or paste an image...';
  }

  TextStyle _placeholderStyle(Node node, {TextSpan? textSpan}) {
    return AppTheme.body(
      size: 14,
      height: 1.32,
      color: AppTheme.fgTertiary,
    );
  }
}
