import 'dart:io';

import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';

import 'widgets/code_viewer.dart';

class DragDropPage extends StatefulWidget {
  const DragDropPage({super.key});

  @override
  State<DragDropPage> createState() => _DragDropPageState();
}

class _DragDropPageState extends State<DragDropPage> {
  final List<_DroppedFile> _files = [];
  bool _isDragging = false;
  String? _previewContent;
  String? _previewName;
  String? _previewLanguage;

  void _onDragEntered(DropEventDetails details) {
    setState(() => _isDragging = true);
  }

  void _onDragExited(DropEventDetails details) {
    setState(() => _isDragging = false);
  }

  Future<void> _onDragDone(DropDoneDetails details) async {
    setState(() => _isDragging = false);

    for (final xFile in details.files) {
      final path = xFile.path;
      final file = File(path);
      final stat = file.statSync();
      final isDir = stat.type == FileSystemEntityType.directory;

      setState(() {
        _files.insert(0, _DroppedFile(
          name: xFile.name,
          path: path,
          size: stat.size,
          isDirectory: isDir,
          modified: stat.modified,
        ));
      });
    }
  }

  Future<void> _previewFile(_DroppedFile dropped) async {
    if (dropped.isDirectory) {
      try {
        final entries = Directory(dropped.path).listSync();
        final listing = entries.map((e) {
          final name = e.path.split('/').last;
          return e is Directory ? '📁 $name/' : '📄 $name';
        }).join('\n');
        setState(() {
          _previewName = dropped.name;
          _previewContent = 'ディレクトリ内容 (${entries.length}件):\n\n$listing';
          _previewLanguage = null;
        });
      } catch (e) {
        setState(() {
          _previewName = dropped.name;
          _previewContent = 'アクセスできません: $e';
          _previewLanguage = null;
        });
      }
      return;
    }

    if (dropped.size > 1024 * 1024) {
      setState(() {
        _previewName = dropped.name;
        _previewContent = '(ファイルが大きすぎます: ${_formatSize(dropped.size)})';
        _previewLanguage = null;
      });
      return;
    }

    try {
      final content = await File(dropped.path).readAsString();
      setState(() {
        _previewName = dropped.name;
        _previewContent = content;
        _previewLanguage = languageFromFileName(dropped.name);
      });
    } catch (e) {
      setState(() {
        _previewName = dropped.name;
        _previewContent = '(テキストとして読み込めません: バイナリファイルの可能性があります)';
        _previewLanguage = null;
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _iconFor(String name, bool isDir) {
    if (isDir) return Icons.folder;
    final lower = name.toLowerCase();
    if (lower.endsWith('.dart')) return Icons.code;
    if (lower.endsWith('.yaml') || lower.endsWith('.yml')) return Icons.settings;
    if (lower.endsWith('.md')) return Icons.description;
    if (lower.endsWith('.json')) return Icons.data_object;
    if (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return Icons.image;
    }
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Drag & Drop'),
      ),
      body: Row(
        children: [
          // 左: ドロップエリア + ファイルリスト
          SizedBox(
            width: 350,
            child: Column(
              children: [
                // ドロップエリア
                DropTarget(
                  onDragEntered: _onDragEntered,
                  onDragExited: _onDragExited,
                  onDragDone: _onDragDone,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.all(16),
                    height: 120,
                    decoration: BoxDecoration(
                      color: _isDragging
                          ? Colors.deepPurple.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDragging
                            ? Colors.deepPurple
                            : Colors.grey.shade300,
                        width: _isDragging ? 2 : 1,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isDragging ? Icons.file_download : Icons.upload_file,
                            size: 36,
                            color: _isDragging
                                ? Colors.deepPurple
                                : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isDragging
                                ? 'ドロップしてください！'
                                : 'ここにファイルをドラッグ＆ドロップ',
                            style: TextStyle(
                              color: _isDragging
                                  ? Colors.deepPurple
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ファイルリスト
                Expanded(
                  child: _files.isEmpty
                      ? const Center(
                          child: Text(
                            'まだファイルがありません',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _files.length,
                          itemBuilder: (context, index) {
                            final f = _files[index];
                            final isSelected = _previewName == f.name;
                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              leading: Icon(
                                _iconFor(f.name, f.isDirectory),
                                color: f.isDirectory
                                    ? Colors.amber
                                    : Colors.grey.shade400,
                                size: 20,
                              ),
                              title: Text(
                                f.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                f.isDirectory
                                    ? 'ディレクトリ'
                                    : _formatSize(f.size),
                                style: const TextStyle(fontSize: 11),
                              ),
                              onTap: () => _previewFile(f),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // 右: プレビュー
          Expanded(
            child: _previewContent == null
                ? const Center(
                    child: Text(
                      'ファイルをクリックしてプレビュー',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.grey.shade100,
                        child: Text(
                          _previewName ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: CodeViewer(
                          content: _previewContent!,
                          language: _previewLanguage,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DroppedFile {
  final String name;
  final String path;
  final int size;
  final bool isDirectory;
  final DateTime modified;

  _DroppedFile({
    required this.name,
    required this.path,
    required this.size,
    required this.isDirectory,
    required this.modified,
  });
}
