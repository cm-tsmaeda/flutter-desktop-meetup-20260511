import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';

class SystemTrayPage extends StatefulWidget {
  const SystemTrayPage({super.key});

  @override
  State<SystemTrayPage> createState() => _SystemTrayPageState();
}

class _SystemTrayPageState extends State<SystemTrayPage> with TrayListener {
  bool _isActive = false;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    if (_isActive) {
      trayManager.destroy();
    }
    super.dispose();
  }

  Future<void> _setupTray() async {
    // tray_manager が内部で rootBundle.load() するので、Flutter assets のパスをそのまま渡す
    // （Directory.current は起動方法によって変わるため絶対パス組み立て不可）
    await trayManager.setIcon('assets/tray_icon.png');
    await trayManager.setToolTip('Flutter Desktop Demo');

    await _updateMenu('通常モード');

    setState(() {
      _isActive = true;
      _addLog('システムトレイに追加しました');
    });
  }

  Future<void> _updateMenu(String status) async {
    final menu = Menu(items: [
      MenuItem(label: 'ステータス: $status', disabled: true),
      MenuItem.separator(),
      MenuItem(label: 'あいさつ', key: 'greet'),
      MenuItem(label: '現在時刻', key: 'time'),
      MenuItem.separator(),
      MenuItem(
        label: 'モード',
        submenu: Menu(items: [
          MenuItem(label: '通常モード', key: 'mode_normal'),
          MenuItem(label: '集中モード', key: 'mode_focus'),
          MenuItem(label: 'おやすみモード', key: 'mode_sleep'),
        ]),
      ),
      MenuItem.separator(),
      MenuItem(label: 'トレイから削除', key: 'remove'),
    ]);
    await trayManager.setContextMenu(menu);
  }

  Future<void> _removeTray() async {
    await trayManager.destroy();
    setState(() {
      _isActive = false;
      _addLog('システムトレイから削除しました');
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
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  @override
  void onTrayIconMouseDown() {
    _addLog('トレイアイコンがクリックされました');
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    _addLog('トレイアイコンが右クリックされました');
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'greet':
        _addLog('こんにちは！トレイメニューからのあいさつです');
        break;
      case 'time':
        _addLog('現在時刻: ${DateTime.now()}');
        break;
      case 'mode_normal':
        _addLog('通常モードに切り替え');
        _updateMenu('通常モード');
        break;
      case 'mode_focus':
        _addLog('集中モードに切り替え');
        _updateMenu('集中モード');
        break;
      case 'mode_sleep':
        _addLog('おやすみモードに切り替え');
        _updateMenu('おやすみモード');
        break;
      case 'remove':
        _removeTray();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('System Tray'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ステータス
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: _isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isActive ? 'メニューバーに表示中' : '非表示',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isActive ? _removeTray : _setupTray,
                  icon: Icon(_isActive ? Icons.remove_circle : Icons.add_circle),
                  label: Text(_isActive ? '削除' : 'トレイに追加'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isActive)
              Text(
                'メニューバーのアイコンをクリックしてメニューを表示できます',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 16),

            // ログ
            const Text('イベントログ', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        fontSize: 12,
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
