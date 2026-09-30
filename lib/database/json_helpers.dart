import 'dart:convert';

List<String> decodeStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  if (value is String && value.isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }
  }
  return [];
}

String encodeStringList(List<String> values) => jsonEncode(values);

Map<String, dynamic> rowWithId(Map<String, dynamic> row) {
  final data = Map<String, dynamic>.from(row);
  data['id'] = data['id'] ?? data['\$id'];
  return data;
}

String nowIso() => DateTime.now().toUtc().toIso8601String();
