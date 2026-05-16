import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';

class LocalServerPage extends StatefulWidget {
  const LocalServerPage({super.key});

  @override
  State<LocalServerPage> createState() => _LocalServerPageState();
}

class _LocalServerPageState extends State<LocalServerPage> {
  HttpServer? _server;
  final int _port = 8080;
  final List<String> _logs = [];
  int _requestCount = 0;

  bool get _isRunning => _server != null;

  Future<void> _startServer() async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
      setState(() {
        _server = server;
        _addLog('サーバー起動: http://localhost:$_port');
      });

      server.listen((request) {
        _requestCount++;
        _addLog('[${request.method}] ${request.uri.path}');
        _handleRequest(request);
      });
    } catch (e) {
      _addLog('起動エラー: $e');
    }
  }

  void _handleRequest(HttpRequest request) {
    final path = request.uri.path;
    final response = request.response;

    response.headers.contentType = ContentType.json;

    if (path == '/' || path == '/hello') {
      response.write(jsonEncode({
        'message': 'こんにちは！Flutterサーバーです',
        'time': DateTime.now().toIso8601String(),
        'requestCount': _requestCount,
      }));
    } else if (path == '/info') {
      response.write(jsonEncode({
        'platform': Platform.operatingSystem,
        'version': Platform.version,
        'hostname': Platform.localHostname,
      }));
    } else {
      response.statusCode = HttpStatus.notFound;
      response.write(jsonEncode({
        'error': 'Not Found',
        'path': path,
        'availableEndpoints': ['/', '/hello', '/info'],
      }));
    }

    response.close();
  }

  Future<void> _stopServer() async {
    await _server?.close();
    setState(() {
      _server = null;
      _addLog('サーバー停止');
    });
  }

  void _addLog(String message) {
    final time = DateTime.now();
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
    setState(() {
      _logs.insert(0, '[$timeStr] $message');
      if (_logs.length > 100) _logs.removeLast();
    });
  }

  Future<void> _sendTestRequest(String path) async {
    try {
      final client = HttpClient();
      final request = await client.get('localhost', _port, path);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      // JSONを整形して表示
      final json = jsonDecode(body);
      final pretty = const JsonEncoder.withIndent('  ').convert(json);
      _addLog('レスポンス ($path):\n$pretty');

      client.close();
    } catch (e) {
      _addLog('リクエストエラー: $e');
    }
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Local Server'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サーバー制御
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: _isRunning ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isRunning
                      ? 'http://localhost:$_port で稼働中'
                      : '停止中',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isRunning ? _stopServer : _startServer,
                  icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(_isRunning ? '停止' : '起動'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? Colors.red.shade100 : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // テストリクエスト
            const Text('テストリクエスト', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? () => _sendTestRequest('/hello') : null,
                  child: const Text('GET /hello'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? () => _sendTestRequest('/info') : null,
                  child: const Text('GET /info'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? () => _sendTestRequest('/unknown') : null,
                  child: const Text('GET /unknown (404)'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ブラウザからも http://localhost:$_port にアクセスできます',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // ログ
            const Text('ログ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return SelectableText(
                      _logs[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        color: Colors.greenAccent,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
