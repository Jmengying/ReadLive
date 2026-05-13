import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:readlive/features/book_source/data/book_source_repository.dart';

class AppInit {
  static Future<void> loadBuiltInSources(BookSourceRepository repo) async {
    try {
      // Skip if built-in sources are already loaded
      final existing = await repo.getAllSources();
      if (existing.any((s) => s.builtIn)) {
        debugPrint('Built-in sources already loaded, skipping');
        return;
      }

      debugPrint('Loading built-in sources from assets...');
      final jsonStr = await rootBundle.loadString('assets/built_in_sources.json');
      debugPrint('Loaded JSON: ${jsonStr.length} bytes');

      final (count, errors) = await repo.importFromJson(jsonStr, builtIn: true);
      debugPrint('Imported $count built-in book sources');
      if (errors.isNotEmpty) {
        for (final e in errors) {
          debugPrint('  Import warning: $e');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to load built-in sources: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
