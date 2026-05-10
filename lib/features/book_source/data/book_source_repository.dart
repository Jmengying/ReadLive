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
      createdAt: source.createdAt,
    );
    await updateSource(updated);
  }

  /// Import a source from a JSON string (single source or array).
  Future<int> importFromJson(String jsonStr) async {
    final dynamic decoded = jsonDecode(jsonStr);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      list = [decoded];
    } else {
      return 0;
    }

    var count = 0;
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final rule = SourceRule.fromJson(item);
        await addSource(
          name: rule.name,
          host: rule.host,
          rule: rule,
          contentType: rule.contentType,
          weight: rule.weight,
        );
        count++;
      }
    }
    return count;
  }

  /// Export all sources as a JSON string.
  Future<String> exportToJson() async {
    final sources = await getAllSources();
    final rules = sources.map((s) => s.parseRule().toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(rules);
  }
}
