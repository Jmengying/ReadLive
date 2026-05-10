import 'package:flutter/material.dart';

class BookshelfPage extends StatelessWidget {
  final String contentType;
  const BookshelfPage({super.key, required this.contentType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(contentType == 'manga' ? '漫画' : '小说')),
      body: const Center(child: Text('书架')),
    );
  }
}
