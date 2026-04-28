import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

import '../services/clipboard_image_service.dart';
import '../theme/app_theme.dart';

final _mdDocument = md.Document(
  encodeHtml: false,
  extensionSet: md.ExtensionSet.gitHubFlavored,
);
final _mdToDelta = MarkdownToDelta(markdownDocument: _mdDocument);
final _deltaToMd = DeltaToMarkdown();

// ── Public API ────────────────────────────────────────────────────────────────

class MarkdownEditorController {
  QuillController? _quill;

  String get markdown {
    final delta = _quill?.document.toDelta();
    if (delta == null) return '';
    return _deltaToMd.convert(delta).trim();
  }

  void _attach(QuillController c) => _quill = c;
  void _detach() => _quill = null;
}

class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({
    super.key,
    this.initialMarkdown,
    this.controller,
    this.onChanged,
    this.height = 180,
    this.autoFocus = false,
    this.readOnly = false,
  });

  final String? initialMarkdown;
  final MarkdownEditorController? controller;
  final ValueChanged<String>? onChanged;
  final double height;
  final bool autoFocus;
  final bool readOnly;

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

// ── State ─────────────────────────────────────────────────────────────────────

class _MarkdownEditorState extends State<MarkdownEditor> {
  late final QuillController _quill;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();

    final initial = (widget.initialMarkdown ?? '').trim();
    Document doc;
    if (initial.isEmpty) {
      doc = Document();
    } else {
      try {
        final delta = _mdToDelta.convert(initial);
        doc = Document.fromJson(delta.toJson());
      } catch (e) {
        debugPrint('MarkdownToDelta conversion failed: $e');
        doc = Document()..insert(0, initial);
      }
    }

    _quill = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: widget.readOnly,
      config: widget.readOnly
          ? const QuillControllerConfig()
          // ignore: experimental_member_use
          : QuillControllerConfig(
              // ignore: experimental_member_use
              clipboardConfig: QuillClipboardConfig(
                // ignore: experimental_member_use
                onClipboardPaste: _onClipboardPaste,
              ),
            ),
    );

    widget.controller?._attach(_quill);
    if (widget.onChanged != null) {
      _quill.changes.listen(_onDocChange);
    }
  }

  Future<bool> _onClipboardPaste() async {
    final imagePath = await ClipboardImageService.persistClipboardImage();
    if (imagePath == null) return false;
    final index = _quill.selection.baseOffset;
    final len = (_quill.selection.extentOffset - index).abs();
    _quill.replaceText(index, len, BlockEmbed.image(imagePath), null);
    return true;
  }

  void _onDocChange(DocChange _) {
    widget.onChanged?.call(_deltaToMd.convert(_quill.document.toDelta()).trim());
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _quill.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    final editor = QuillEditor(
      controller: _quill,
      focusNode: _focusNode,
      scrollController: _scrollController,
      config: QuillEditorConfig(
        placeholder: 'Write notes in Markdown or paste an image…',
        autoFocus: widget.autoFocus,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        embedBuilders: const [_ImageEmbedBuilder()],
        customStyles: _buildStyles(),
        readOnlyMouseCursor:
            widget.readOnly ? SystemMouseCursors.basic : SystemMouseCursors.text,
      ),
    );

    final Widget content = widget.readOnly
        ? editor
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToolbar(),
              const Divider(height: 1, thickness: 1, color: Color(0x18000000)),
              Expanded(child: editor),
            ],
          );

    return Container(
      height: widget.height,
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
        child: content,
      ),
    );
  }

  Widget _buildToolbar() {
    return QuillSimpleToolbar(
      controller: _quill,
      config: QuillSimpleToolbarConfig(
        color: Colors.transparent,
        multiRowsDisplay: false,
        toolbarIconAlignment: WrapAlignment.start,
        showDividers: false,
        showFontFamily: false,
        showFontSize: false,
        showBoldButton: true,
        showItalicButton: true,
        showSmallButton: false,
        showUnderLineButton: false,
        showLineHeightButton: false,
        showStrikeThrough: true,
        showInlineCode: true,
        showColorButton: false,
        showBackgroundColorButton: false,
        showClearFormat: false,
        showAlignmentButtons: false,
        showLeftAlignment: false,
        showCenterAlignment: false,
        showRightAlignment: false,
        showJustifyAlignment: false,
        showHeaderStyle: true,
        showListNumbers: true,
        showListBullets: true,
        showListCheck: true,
        showCodeBlock: false,
        showQuote: true,
        showIndent: false,
        showLink: true,
        showUndo: true,
        showRedo: true,
        showDirection: false,
        showSearchButton: false,
        showSubscript: false,
        showSuperscript: false,
        // ignore: experimental_member_use
        showClipboardCut: false,
        // ignore: experimental_member_use
        showClipboardCopy: false,
        // ignore: experimental_member_use
        showClipboardPaste: false,
        iconTheme: QuillIconTheme(
          iconButtonSelectedData: IconButtonData(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                AppTheme.accentBlue.withValues(alpha: 0.12),
              ),
            ),
          ),
          iconButtonUnselectedData: IconButtonData(
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(AppTheme.fgSecondary),
            ),
          ),
        ),
      ),
    );
  }

  DefaultStyles _buildStyles() {
    final bodyStyle = AppTheme.body(size: 14, height: 1.4);
    const noSpacing = VerticalSpacing.zero;
    const tightSpacing = VerticalSpacing(1, 1);
    const hSpacing = HorizontalSpacing(0, 0);

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        bodyStyle,
        hSpacing,
        tightSpacing,
        tightSpacing,
        null,
      ),
      h1: DefaultTextBlockStyle(
        AppTheme.body(size: 22, height: 1.3).copyWith(fontWeight: FontWeight.w700),
        hSpacing,
        const VerticalSpacing(6, 2),
        noSpacing,
        null,
      ),
      h2: DefaultTextBlockStyle(
        AppTheme.body(size: 18, height: 1.3).copyWith(fontWeight: FontWeight.w600),
        hSpacing,
        const VerticalSpacing(4, 2),
        noSpacing,
        null,
      ),
      h3: DefaultTextBlockStyle(
        AppTheme.body(size: 16, height: 1.3).copyWith(fontWeight: FontWeight.w600),
        hSpacing,
        const VerticalSpacing(3, 1),
        noSpacing,
        null,
      ),
      lists: DefaultListBlockStyle(
        bodyStyle,
        hSpacing,
        noSpacing,
        noSpacing,
        null,
        null,
      ),
      quote: DefaultTextBlockStyle(
        bodyStyle.copyWith(color: AppTheme.fgSecondary),
        hSpacing,
        tightSpacing,
        tightSpacing,
        BoxDecoration(
          border: Border(
            left: BorderSide(color: AppTheme.accentBlue.withValues(alpha: 0.5), width: 3),
          ),
        ),
      ),
      bold: const TextStyle(fontWeight: FontWeight.w700),
      italic: const TextStyle(fontStyle: FontStyle.italic),
      strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
      underline: const TextStyle(decoration: TextDecoration.underline),
      link: TextStyle(
        color: AppTheme.accentBlue,
        decoration: TextDecoration.underline,
        decorationColor: AppTheme.accentBlue.withValues(alpha: 0.4),
      ),
      inlineCode: InlineCodeStyle(
        style: AppTheme.mono(size: 13, color: AppTheme.fgPrimary),
        backgroundColor: const Color(0x14000000),
        radius: const Radius.circular(3),
      ),
      placeHolder: DefaultTextBlockStyle(
        bodyStyle.copyWith(color: AppTheme.fgTertiary),
        hSpacing,
        tightSpacing,
        tightSpacing,
        null,
      ),
    );
  }
}

// ── Image embed ───────────────────────────────────────────────────────────────

class _ImageEmbedBuilder extends EmbedBuilder {
  const _ImageEmbedBuilder();

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => true;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final src = embedContext.node.value.data as String;
    Widget image;
    if (src.startsWith('http://') || src.startsWith('https://')) {
      image = Image.network(
        src,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      image = Image.file(
        File(src),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 320),
        child: image,
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 120,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0x0F000000),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppTheme.fgTertiary,
          size: 28,
        ),
      );
}
