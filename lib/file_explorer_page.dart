import 'dart:io';

import 'package:flutter/material.dart';

import 'widgets/code_viewer.dart';

const _initialPath = String.fromEnvironment('INITIAL_PATH');

class FileExplorerPage extends StatefulWidget {
  const FileExplorerPage({super.key});

  @override
  State<FileExplorerPage> createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  late Directory _currentDir;
  List<FileSystemEntity> _entries = [];
  String? _selectedFileContent;
  String? _selectedFileName;
  String? _selectedLanguage;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final path = _initialPath.isNotEmpty
        ? _initialPath
        : (Platform.environment['HOME'] ?? '/');
    _currentDir = Directory(path);
    _loadDirectory();
  }

  void _loadDirectory() {
    try {
      final entries = _currentDir.listSync()
        ..sort((a, b) {
          // ディレクトリを先に、その後ファイル名順
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });
      setState(() {
        _entries = entries;
        _selectedFileContent = null;
        _selectedFileName = null;
        _selectedLanguage = null;
        _error = '';
      });
    } catch (e) {
      setState(() {
        _error = 'アクセスできません: $e';
      });
    }
  }

  void _navigateTo(Directory dir) {
    setState(() {
      _currentDir = dir;
    });
    _loadDirectory();
  }

  void _goUp() {
    final parent = _currentDir.parent;
    if (parent.path != _currentDir.path) {
      _navigateTo(parent);
    }
  }

  Future<void> _openFile(File file) async {
    try {
      final stat = file.statSync();
      // 1MB以上のファイルは開かない
      if (stat.size > 1024 * 1024) {
        setState(() {
          _selectedFileName = _name(file);
          _selectedFileContent = '(ファイルが大きすぎます: ${_formatSize(stat.size)})';
          _selectedLanguage = null;
        });
        return;
      }
      final content = await file.readAsString();
      setState(() {
        _selectedFileName = _name(file);
        _selectedFileContent = content;
        _selectedLanguage = languageFromFileName(_name(file));
      });
    } catch (e) {
      setState(() {
        _selectedFileName = _name(file);
        _selectedFileContent = '(読み込めません: バイナリファイルの可能性があります)';
        _selectedLanguage = null;
      });
    }
  }

  String _name(FileSystemEntity entity) {
    return entity.path.split('/').last;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _iconFor(FileSystemEntity entity) {
    if (entity is Directory) return Icons.folder;
    final name = _name(entity).toLowerCase();
    if (name.endsWith('.dart')) return Icons.code;
    if (name.endsWith('.yaml') || name.endsWith('.yml')) return Icons.settings;
    if (name.endsWith('.md')) return Icons.description;
    if (name.endsWith('.json')) return Icons.data_object;
    if (name.endsWith('.png') || name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }

  Color _colorFor(FileSystemEntity entity) {
    if (entity is Directory) return Colors.amber;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('File Explorer'),
      ),
      body: Column(
        children: [
          _buildPathBar(),
          Expanded(
            child: _error.isNotEmpty
                ? Center(child: Text(_error))
                : Row(
                    children: [
                      _buildFileList(),
                      const VerticalDivider(width: 1),
                      Expanded(child: _buildFileViewer()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade200,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            tooltip: '上のディレクトリへ',
            onPressed: _goUp,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              _currentDir.path,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return SizedBox(
      width: 300,
      child: ListView.builder(
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final name = _name(entry);
          final isSelected = _selectedFileName == name;
          return ListTile(
            dense: true,
            selected: isSelected,
            leading: Icon(_iconFor(entry), color: _colorFor(entry), size: 20),
            title: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            onTap: () {
              if (entry is Directory) {
                _navigateTo(entry);
              } else if (entry is File) {
                _openFile(entry);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildFileViewer() {
    if (_selectedFileContent == null) {
      return const Center(
        child: Text(
          'ファイルを選択してください',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade100,
          child: Text(
            _selectedFileName ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Expanded(
          child: CodeViewer(
            content: _selectedFileContent!,
            language: _selectedLanguage,
          ),
        ),
      ],
    );
  }
}
