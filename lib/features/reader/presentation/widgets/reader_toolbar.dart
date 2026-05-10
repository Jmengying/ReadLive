import 'package:flutter/material.dart';

class ReaderToolbar extends StatelessWidget {
  final String bookTitle;
  final int currentChapter;
  final int totalChapters;
  final bool isLocked;
  final VoidCallback onBack;
  final VoidCallback onToggleLock;
  final VoidCallback onShowChapters;
  final VoidCallback onShowSettings;
  final VoidCallback onShowBookmarks;
  final VoidCallback onToggleNightMode;
  final VoidCallback onToggleTts;
  final VoidCallback onAddBookmark;
  final ValueChanged<int> onChapterChange;

  const ReaderToolbar({
    super.key,
    required this.bookTitle,
    required this.currentChapter,
    required this.totalChapters,
    required this.isLocked,
    required this.onBack,
    required this.onToggleLock,
    required this.onShowChapters,
    required this.onShowSettings,
    required this.onShowBookmarks,
    required this.onToggleNightMode,
    required this.onToggleTts,
    required this.onAddBookmark,
    required this.onChapterChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.black54,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 8,
            right: 8,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  bookTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  isLocked ? Icons.lock : Icons.lock_open,
                  color: Colors.white,
                ),
                onPressed: onToggleLock,
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          color: Colors.black54,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '第${currentChapter + 1}章',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Expanded(
                    child: Slider(
                      value: currentChapter.toDouble(),
                      min: 0,
                      max: (totalChapters - 1).toDouble().clamp(0, double.infinity),
                      onChanged: (v) => onChapterChange(v.toInt()),
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                    ),
                  ),
                  Text(
                    '第$totalChapters章',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.list, color: Colors.white),
                    onPressed: onShowChapters,
                    tooltip: '目录',
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border, color: Colors.white),
                    onPressed: onShowBookmarks,
                    tooltip: '书签',
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_add, color: Colors.white),
                    onPressed: onAddBookmark,
                    tooltip: '添加书签',
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    onPressed: onToggleTts,
                    tooltip: '朗读',
                  ),
                  IconButton(
                    icon: const Icon(Icons.nightlight_round, color: Colors.white),
                    onPressed: onToggleNightMode,
                    tooltip: '夜间模式',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: onShowSettings,
                    tooltip: '设置',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
