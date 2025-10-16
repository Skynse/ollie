enum Priority {
  low,
  medium,
  high;

  String toJson() => name;

  static Priority fromJson(String value) {
    return Priority.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => Priority.low,
    );
  }
}
