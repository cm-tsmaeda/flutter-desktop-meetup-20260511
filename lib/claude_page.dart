import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ClaudePage extends StatefulWidget {
  const ClaudePage({super.key});

  @override
  State<ClaudePage> createState() => _ClaudePageState();
}

class _ClaudePageState extends State<ClaudePage> {
  final _promptController = TextEditingController(text: 'こんにちは〜');
  String _output = '';
  bool _isLoading = false;

  Future<void> _runClaude() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _output = '';
    });

    try {
      // Finder からダブルクリック起動した Release ビルドでも PATH を解決するため、
      // zsh のログイン+インタラクティブシェル経由で claude を起動する
      // (-i がないと ~/.zshrc が読まれず PATH が補強されない)。
      // プロンプトは "$1" 展開で渡してシェルエスケープを回避。
      final result = await Process.run(
        '/bin/zsh',
        ['-ilc', 'claude -p "\$1"', 'flutter-app', prompt],
      );
      setState(() {
        _output = result.exitCode == 0
            ? result.stdout as String
            : 'エラー (exit code: ${result.exitCode})\n'
                  'stdout: ${result.stdout}\n'
                  'stderr: ${result.stderr}';
      });
    } catch (e) {
      setState(() {
        _output = '実行エラー: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Claude'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      labelText: 'プロンプト',
                      border: OutlineInputBorder(),
                      hintText: '何か聞いてみよう',
                    ),
                    onSubmitted: (_) => _runClaude(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _runClaude,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('送信'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _output.isEmpty
                      ? const Center(
                          child: Text(
                            'Claudeの応答がここに表示されます',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Markdown(
                          data: _output,
                          selectable: true,
                          padding: const EdgeInsets.all(16),
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 16, height: 1.6),
                            h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
                            h2: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
                            h3: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, height: 1.4),
                            code: TextStyle(
                              fontSize: 14,
                              fontFamily: 'monospace',
                              backgroundColor: Colors.grey.shade200,
                            ),
                            codeblockPadding: const EdgeInsets.all(12),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
