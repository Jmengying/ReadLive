import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/book_source/domain/book_source_entity.dart';
import 'package:readlive/features/book_source/domain/source_rule.dart';

class BookSourceRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  BookSourceRepository(this._db);

  Future<List<BookSourceEntity>> getAllSources() async {
    final data = await _db.getAllBookSources();
    return data.map(BookSourceEntity.fromData).toList();
  }

  Stream<List<BookSourceEntity>> watchAllSources() {
    return _db.watchAllBookSources().map(
          (list) => list.map(BookSourceEntity.fromData).toList(),
        );
  }

  Future<List<BookSourceEntity>> getEnabledSources() async {
    final data = await _db.getEnabledBookSources();
    return data.map(BookSourceEntity.fromData).toList();
  }

  Future<BookSourceEntity?> getSourceById(String id) async {
    final data = await _db.getBookSourceById(id);
    return data != null ? BookSourceEntity.fromData(data) : null;
  }

  Future<BookSourceEntity> addSource({
    required String name,
    required String host,
    required SourceRule rule,
    String contentType = 'novel',
    int weight = 100,
    String? groupName,
    bool builtIn = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    final ruleJson = rule.toJsonString();

    final companion = BookSourcesTableCompanion(
      id: Value(id),
      name: Value(name),
      host: Value(host),
      contentType: Value(contentType),
      enabled: const Value(true),
      weight: Value(weight),
      ruleJson: Value(ruleJson),
      status: const Value('active'),
      groupName: Value(groupName),
      builtIn: Value(builtIn),
      createdAt: Value(now),
    );

    await _db.insertBookSource(companion);
    return (await getSourceById(id))!;
  }

  Future<void> updateSource(BookSourceEntity source) async {
    final companion = BookSourcesTableCompanion(
      id: Value(source.id),
      name: Value(source.name),
      host: Value(source.host),
      contentType: Value(source.contentType),
      enabled: Value(source.enabled),
      weight: Value(source.weight),
      ruleJson: Value(source.ruleJson),
      status: Value(source.status),
      lastTestedAt: Value(source.lastTestedAt),
      groupName: Value(source.groupName),
      builtIn: Value(source.builtIn),
      createdAt: Value(source.createdAt),
    );
    await _db.updateBookSource(companion);
  }

  Future<void> deleteSource(String id) async {
    await _db.deleteBookSource(id);
  }

  Future<void> toggleEnabled(String id, bool enabled) async {
    final source = await getSourceById(id);
    if (source == null) return;
    final updated = BookSourceEntity(
      id: source.id,
      name: source.name,
      host: source.host,
      contentType: source.contentType,
      enabled: enabled,
      weight: source.weight,
      ruleJson: source.ruleJson,
      status: source.status,
      lastTestedAt: source.lastTestedAt,
      groupName: source.groupName,
      builtIn: source.builtIn,
      createdAt: source.createdAt,
    );
    await updateSource(updated);
  }

  Future<void> updateSourceStatus(String id, String status) async {
    final source = await getSourceById(id);
    if (source == null) return;
    final updated = BookSourceEntity(
      id: source.id,
      name: source.name,
      host: source.host,
      contentType: source.contentType,
      enabled: source.enabled,
      weight: source.weight,
      ruleJson: source.ruleJson,
      status: status,
      lastTestedAt: DateTime.now().millisecondsSinceEpoch,
      groupName: source.groupName,
      builtIn: source.builtIn,
      createdAt: source.createdAt,
    );
    await updateSource(updated);
  }

  /// Import a source from a JSON string (single source or array).
  /// Returns (successCount, errorMessages).
  Future<(int, List<String>)> importFromJson(String jsonStr, {bool builtIn = false}) async {
    final dynamic decoded = jsonDecode(jsonStr);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      list = [decoded];
    } else {
      return (0, ['无效的 JSON 格式']);
    }

    var count = 0;
    final errors = <String>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Map<String, dynamic>) {
        errors.add('第 ${i + 1} 项不是有效的对象');
        continue;
      }
      try {
        final rule = SourceRule.fromJson(item);
        if (rule.name.trim().isEmpty) {
          errors.add('第 ${i + 1} 项: name 为空');
          continue;
        }
        if (rule.host.trim().isEmpty) {
          errors.add('第 ${i + 1} 项: host 为空');
          continue;
        }
        await addSource(
          name: rule.name.trim(),
          host: rule.host.trim(),
          rule: rule,
          contentType: rule.contentType,
          weight: rule.weight,
          builtIn: builtIn,
        );
        count++;
      } catch (e) {
        errors.add('第 ${i + 1} 项: $e');
      }
    }
    return (count, errors);
  }

  /// Export all sources as a JSON string.
  Future<String> exportToJson() async {
    final sources = await getAllSources();
    final rules = sources.map((s) => s.parseRule().toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(rules);
  }

  /// Delete multiple sources by ID.
  Future<void> deleteSources(List<String> ids) async {
    for (final id in ids) {
      await _db.deleteBookSource(id);
    }
  }

  /// Enable/disable multiple sources.
  Future<void> toggleSources(List<String> ids, bool enabled) async {
    for (final id in ids) {
      await toggleEnabled(id, enabled);
    }
  }

  /// Remove duplicate sources by host, keeping the one with highest weight.
  /// Built-in sources are never removed.
  Future<int> deduplicate() async {
    final sources = await getAllSources();
    final byHost = <String, List<BookSourceEntity>>{};
    for (final s in sources) {
      final key = s.host.toLowerCase().replaceAll(RegExp(r'^https?://'), '');
      byHost.putIfAbsent(key, () => []).add(s);
    }

    var removed = 0;
    for (final group in byHost.values) {
      if (group.length <= 1) continue;
      // Sort by weight descending, built-in first
      group.sort((a, b) {
        if (a.builtIn != b.builtIn) return a.builtIn ? -1 : 1;
        return b.weight.compareTo(a.weight);
      });
      // Remove non-built-in duplicates, keeping the first (highest weight or built-in)
      for (var i = 1; i < group.length; i++) {
        if (!group[i].builtIn) {
          await _db.deleteBookSource(group[i].id);
          removed++;
        }
      }
    }
    return removed;
  }
}
