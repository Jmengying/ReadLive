import 'package:flutter/material.dart';

class MangaContentView extends StatefulWidget {
  final List<String> imageUrls;
  final String readingMode; // 'page' or 'scroll'
  final ValueChanged<int>? onPageChanged;
  final int initialPage;
  final Color backgroundColor;

  const MangaContentView({
    super.key,
    required this.imageUrls,
    this.readingMode = 'page',
    this.onPageChanged,
    this.initialPage = 0,
    this.backgroundColor = Colors.black,
  });

  @override
  State<MangaContentView> createState() => _MangaContentViewState();
}

class _MangaContentViewState extends State<MangaContentView> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const Center(child: Text('暂无图片'));
    }

    if (widget.readingMode == 'scroll') {
      return _buildScrollView();
    }
    return _buildPageView();
  }

  Widget _buildPageView() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) {
            setState(() => _currentPage = index);
            widget.onPageChanged?.call(index);
          },
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: _MangaImage(
                  url: widget.imageUrls[index],
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
        // Page indicator
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_currentPage + 1}/${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollView() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: widget.imageUrls.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _MangaImage(
            url: widget.imageUrls[index],
            fit: BoxFit.fitWidth,
          ),
        );
      },
    );
  }
}

class _MangaImage extends StatefulWidget {
  final String url;
  final BoxFit fit;

  const _MangaImage({required this.url, required this.fit});

  @override
  State<_MangaImage> createState() => _MangaImageState();
}

class _MangaImageState extends State<_MangaImage> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 300,
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('图片加载失败',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _hasError = false),
                child: const Text('重试', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );
    }

    return Image.network(
      widget.url,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 300,
          color: Colors.grey[900],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white54,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasError) {
            setState(() => _hasError = true);
          }
        });
        return const SizedBox.shrink();
      },
    );
  }
}
