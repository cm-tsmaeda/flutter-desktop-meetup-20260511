import 'dart:io';

import 'package:flutter/material.dart';

import 'widgets/code_viewer.dart';

class CurlPage extends StatefulWidget {
  const CurlPage({super.key});

  @override
  State<CurlPage> createState() => _CurlPageState();
}

class _CurlPageState extends State<CurlPage> {
  final _urlController = TextEditingController(
    text: 'https://httpbin.org/get',
  );
  String _output = '';
  String _lastCommand = '';
  bool _isLoading = false;

  Future<void> _runCurl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _output = '';
      _lastCommand = 'curl -s $url';
    });

    try {
      final result = await Process.run('curl', ['-s', url]);
      setState(() {
        _output =
            result.exitCode == 0
                ? result.stdout as String
                : 'エラー (exit code: ${result.exitCode})\n${result.stderr}';
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
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('curl'),
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
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com',
                    ),
                    onSubmitted: (_) => _runCurl(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _runCurl,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('curl 実行'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Colors.grey.shade900,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_lastCommand.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: SelectableText(
                            '\$ $_lastCommand',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              height: 1.5,
                              letterSpacing: 0.5,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                      Expanded(
                        child: CodeViewer(
                          content: _output.isEmpty
                              ? (_isLoading ? '実行中...' : '結果がここに表示されます')
                              : _output,
                          language: languageFromContent(_output),
                        ),
                      ),
                    ],
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
