import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SelectionMenu extends StatelessWidget {
  final String selectedText;
  final VoidCallback onHighlight;
  final VoidCallback onNote;
  final VoidCallback onCancel;
  final Offset position;

  static const highlightColors = [
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
  ];

  const SelectionMenu({
    super.key,
    required this.selectedText,
    required this.onHighlight,
    required this.onNote,
    required this.onCancel,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx.clamp(16.0, MediaQuery.of(context).size.width - 280),
      top: position.dy - 60 < 0 ? position.dy + 20 : position.dy - 60,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Highlight color circles
              ...highlightColors.map((color) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: selectedText));
                    onHighlight();
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                ),
              )),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_note, size: 20),
                tooltip: '添加笔记',
                onPressed: onNote,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: '复制',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: selectedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制')),
                  );
                  onCancel();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
