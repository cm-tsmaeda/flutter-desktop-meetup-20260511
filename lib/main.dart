import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'curl_page.dart';
import 'claude_page.dart';
import 'file_explorer_page.dart';
import 'window_page.dart';
import 'local_server_page.dart';
import 'system_tray_page.dart';
import 'drag_drop_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Desktop Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = <_DemoItem>[
      _DemoItem(
        title: 'Window',
        subtitle: 'ウィンドウの操作・制御',
        icon: Icons.window,
        builder: (_) => const WindowPage(),
      ),
      _DemoItem(
        title: 'System Tray',
        subtitle: 'メニューバーに常駐アイコンを表示',
        icon: Icons.vertical_align_top,
        builder: (_) => const SystemTrayPage(),
      ),
      _DemoItem(
        title: 'Drag & Drop',
        subtitle: 'ファイルをドラッグ＆ドロップして閲覧',
        icon: Icons.upload_file,
        builder: (_) => const DragDropPage(),
      ),
      _DemoItem(
        title: 'File Explorer',
        subtitle: 'ローカルファイルを閲覧',
        icon: Icons.folder_open,
        builder: (_) => const FileExplorerPage(),
      ),
      _DemoItem(
        title: 'Local Server',
        subtitle: 'HTTPサーバーを起動してリクエストを受信',
        icon: Icons.dns,
        builder: (_) => const LocalServerPage(),
      ),
      _DemoItem(
        title: 'curl',
        subtitle: 'URLを指定してHTTPリクエストを実行',
        icon: Icons.language,
        builder: (_) => const CurlPage(),
      ),
      _DemoItem(
        title: 'Claude',
        subtitle: 'Claude CLIにプロンプトを送信',
        icon: Icons.smart_toy,
        builder: (_) => const ClaudePage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Desktop Demo'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final demo = demos[index];
          return ListTile(
            leading: Icon(demo.icon, size: 32),
            title: Text(demo.title),
            subtitle: Text(demo.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: demo.builder),
            ),
          );
        },
      ),
    );
  }
}

class _DemoItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;

  _DemoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });
}
