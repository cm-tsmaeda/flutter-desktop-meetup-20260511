import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowPage extends StatefulWidget {
  const WindowPage({super.key});

  @override
  State<WindowPage> createState() => _WindowPageState();
}

class _WindowPageState extends State<WindowPage> with WindowListener {
  String _info = '';
  bool _isAlwaysOnTop = false;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadWindowInfo();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _loadWindowInfo() async {
    final size = await windowManager.getSize();
    final position = await windowManager.getPosition();
    setState(() {
      _info = 'サイズ: ${size.width.toInt()} x ${size.height.toInt()}\n'
          '位置: (${position.dx.toInt()}, ${position.dy.toInt()})';
    });
  }

  @override
  void onWindowResize() => _loadWindowInfo();

  @override
  void onWindowMove() => _loadWindowInfo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Window'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ウィンドウ情報
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _info.isEmpty ? '読み込み中...' : _info,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // サイズ変更
            const Text('ウィンドウサイズ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _sizeButton('小 (400x300)', 400, 300),
                _sizeButton('中 (800x600)', 800, 600),
                _sizeButton('大 (1200x800)', 1200, 800),
              ],
            ),
            const SizedBox(height: 24),

            // タイトル変更
            const Text('ウィンドウタイトル', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _titleButton('デフォルト', 'myapp'),
                _titleButton('カスタム', 'Hello Desktop!'),
                _titleButton('日本語', 'デスクトップアプリ'),
              ],
            ),
            const SizedBox(height: 24),

            // オプション
            const Text('オプション', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('常に最前面に表示'),
              value: _isAlwaysOnTop,
              onChanged: (v) async {
                await windowManager.setAlwaysOnTop(v);
                setState(() => _isAlwaysOnTop = v);
              },
            ),
            const SizedBox(height: 8),

            // 透明度
            Row(
              children: [
                const Text('透明度'),
                Expanded(
                  child: Slider(
                    value: _opacity,
                    min: 0.3,
                    max: 1.0,
                    onChanged: (v) async {
                      await windowManager.setOpacity(v);
                      setState(() => _opacity = v);
                    },
                  ),
                ),
                Text('${(_opacity * 100).toInt()}%'),
              ],
            ),
            const SizedBox(height: 24),

            // アクション
            const Text('アクション', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => windowManager.minimize(),
                  icon: const Icon(Icons.minimize),
                  label: const Text('最小化'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (await windowManager.isMaximized()) {
                      windowManager.unmaximize();
                    } else {
                      windowManager.maximize();
                    }
                  },
                  icon: const Icon(Icons.crop_square),
                  label: const Text('最大化/元に戻す'),
                ),
                ElevatedButton.icon(
                  onPressed: () => windowManager.center(),
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('画面中央へ'),
                ),
                ElevatedButton.icon(
                  onPressed: _launchNewWindow,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('新しいウィンドウ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchNewWindow() async {
    // 自分自身のアプリバイナリを見つけて新しいプロセスとして起動
    final executable = Platform.resolvedExecutable;
    await Process.start(executable, []);
  }

  Widget _sizeButton(String label, double w, double h) {
    return ElevatedButton(
      onPressed: () async {
        await windowManager.setSize(Size(w, h));
        _loadWindowInfo();
      },
      child: Text(label),
    );
  }

  Widget _titleButton(String label, String title) {
    return ElevatedButton(
      onPressed: () => windowManager.setTitle(title),
      child: Text(label),
    );
  }
}
