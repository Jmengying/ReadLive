import 'dart:convert';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/book_source/domain/source_rule.dart';

class BookSourceEntity {
  final String id;
  final String name;
  final String host;
  final String contentType;
  final bool enabled;
  final int weight;
  final String ruleJson;
  final String status;
  final int? lastTestedAt;
  final String? groupName;
  final int createdAt;

  const BookSourceEntity({
    required this.id,
    required this.name,
    required this.host,
    required this.contentType,
    required this.enabled,
    required this.weight,
    required this.ruleJson,
    required this.status,
    this.lastTestedAt,
    this.groupName,
    required this.createdAt,
  });

  factory BookSourceEntity.fromData(BookSourcesTableData data) {
    return BookSourceEntity(
      id: data.id,
      name: data.name,
      host: data.host,
      contentType: data.contentType,
      enabled: data.enabled,
      weight: data.weight,
      ruleJson: data.ruleJson,
      status: data.status,
      lastTestedAt: data.lastTestedAt,
      groupName: data.groupName,
      createdAt: data.createdAt,
    );
  }

  SourceRule parseRule() {
    final json = jsonDecode(ruleJson) as Map<String, dynamic>;
    json['id'] = id;
    json['name'] = name;
    json['host'] = host;
    json['contentType'] = contentType;
    json['enabled'] = enabled;
    json['weight'] = weight;
    return SourceRule.fromJson(json);
  }
}
