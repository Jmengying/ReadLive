import 'dart:io';
import 'package:flutter/material.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';

class BookCard extends StatelessWidget {
  final BookEntity book;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selectionMode;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.selectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image - takes most of the space
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: theme.colorScheme.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image or placeholder
                  book.coverPath != null
                      ? Image.file(
                          File(book.coverPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholder(theme),
                        )
                      : _buildPlaceholder(theme),
                  // Selection overlay
                  if (selectionMode)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  if (selectionMode)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                        ),
                        width: 22,
                        height: 22,
                        child: selected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Title + progress below
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  _formatProgress(book.bookProgress),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          book.title.substring(0, book.title.length.clamp(0, 4)),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatProgress(double progress) {
    if (progress >= 0.99) return '读完';
    final percent = (progress * 100).toStringAsFixed(0);
    return '$percent%';
  }
}
