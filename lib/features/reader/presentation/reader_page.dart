import 'package:flutter/material.dart';

class ReaderPage extends StatelessWidget {
  final String bookId;
  const ReaderPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('阅读器: $bookId')),
    );
  }
}
