import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

/// 暗背景 + シンタックスハイライトでコード/テキストを表示するビュア。
///
/// [language] が null のときは緑の等幅テキストでフォールバック。
class CodeViewer extends StatelessWidget {
  final String content;
  final String? language;

  const CodeViewer({super.key, required this.content, this.language});

  static const _baseTextStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: language == null ? _buildPlain() : _buildHighlighted(),
      ),
    );
  }

  Widget _buildPlain() {
    return SelectableText(
      content,
      style: _baseTextStyle.copyWith(color: Colors.greenAccent),
    );
  }

  Widget _buildHighlighted() {
    final result = highlight.parse(content, language: language);
    final rootStyle = monokaiSublimeTheme['root'];
    return SelectableText.rich(
      TextSpan(
        style: _baseTextStyle.copyWith(color: rootStyle?.color),
        children: _convertNodes(result.nodes ?? [], monokaiSublimeTheme),
      ),
    );
  }

  // flutter_highlight の HighlightView 内部実装を踏襲（SelectableText.rich に渡すため）
  static List<TextSpan> _convertNodes(
    List<Node> nodes,
    Map<String, TextStyle> theme,
  ) {
    final List<TextSpan> spans = [];
    var currentSpans = spans;
    final List<List<TextSpan>> stack = [];

    void traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(
          node.className == null
              ? TextSpan(text: node.value)
              : TextSpan(text: node.value, style: theme[node.className!]),
        );
      } else if (node.children != null) {
        final List<TextSpan> tmp = [];
        currentSpans.add(
          TextSpan(children: tmp, style: theme[node.className!]),
        );
        stack.add(currentSpans);
        currentSpans = tmp;

        for (final n in node.children!) {
          traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (final node in nodes) {
      traverse(node);
    }
    return spans;
  }
}

/// ファイル名（拡張子）から highlight.js の言語キーを推論する。
String? languageFromFileName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.dart')) return 'dart';
  if (lower.endsWith('.yaml') || lower.endsWith('.yml')) return 'yaml';
  if (lower.endsWith('.json')) return 'json';
  if (lower.endsWith('.md')) return 'markdown';
  if (lower.endsWith('.swift')) return 'swift';
  if (lower.endsWith('.kt') || lower.endsWith('.kts')) return 'kotlin';
  if (lower.endsWith('.ts') || lower.endsWith('.tsx')) return 'typescript';
  if (lower.endsWith('.js') || lower.endsWith('.jsx') || lower.endsWith('.mjs')) {
    return 'javascript';
  }
  if (lower.endsWith('.sh') || lower.endsWith('.zsh') || lower.endsWith('.bash')) {
    return 'bash';
  }
  if (lower.endsWith('.html') || lower.endsWith('.htm') || lower.endsWith('.xml')) {
    return 'xml';
  }
  if (lower.endsWith('.css')) return 'css';
  if (lower.endsWith('.scss') || lower.endsWith('.sass')) return 'scss';
  if (lower.endsWith('.py')) return 'python';
  if (lower.endsWith('.rb')) return 'ruby';
  if (lower.endsWith('.go')) return 'go';
  if (lower.endsWith('.rs')) return 'rust';
  if (lower.endsWith('.toml')) return 'toml';
  if (lower.endsWith('.gradle')) return 'gradle';
  if (lower == 'gemfile' || lower.endsWith('.gemspec')) return 'ruby';
  if (lower == 'podfile') return 'ruby';
  if (lower == 'dockerfile' || lower == 'makefile') return lower;
  return null;
}

/// 文字列の先頭からゆるく言語を推論する（curl レスポンス等で利用）。
String? languageFromContent(String content) {
  final trimmed = content.trimLeft();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) return 'json';
  if (trimmed.startsWith('<')) return 'xml';
  return null;
}
