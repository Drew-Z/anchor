import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../features/agent/agent_home_screen.dart';
import '../features/home/home_screen.dart';
import '../features/deck/deck_list_screen.dart';
import '../features/knowledge_base/knowledge_base_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/ingestion/ingestion_screen.dart';

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  int _currentIndex = 0;
  StreamSubscription? _sharingSubscription;

  final _screens = const [
    HomeScreen(),
    DeckListScreen(),
    AgentHomeScreen(),
    KnowledgeBaseScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initSharingIntent();
  }

  void _initSharingIntent() {
    try {
      // 处理 APP 通过分享启动时的内容(文本和图片)
      ReceiveSharingIntent.instance
          .getInitialMedia()
          .then((List<SharedMediaFile> files) {
        if (files.isNotEmpty) {
          _handleSharedFiles(files);
        }
        ReceiveSharingIntent.instance.reset();
      }).catchError((_) {});

      // 监听 APP 运行时的分享事件
      _sharingSubscription = ReceiveSharingIntent.instance
          .getMediaStream()
          .listen((List<SharedMediaFile> files) {
        if (files.isNotEmpty) {
          _handleSharedFiles(files);
        }
      });
    } catch (e) {
      // release 模式下初始化失败时静默处理，不影响正常渲染
    }
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    String? text;
    String? imagePath;

    for (final file in files) {
      if (file.type == SharedMediaType.text) {
        text = file.path; // 文本内容在 path 字段
      } else if (file.type == SharedMediaType.image) {
        imagePath = file.path;
      }
    }

    if (text != null || imagePath != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IngestionScreen(
            sharedText: text,
            sharedImagePath: imagePath,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _sharingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '学习',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz),
            label: '题库',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'Agent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: '知识库',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
