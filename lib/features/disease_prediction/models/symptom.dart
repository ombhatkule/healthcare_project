/// Represents a single symptom the user can select for prediction.
///
/// NOTE: This is a UI selection model only. It does NOT, by itself, imply any
/// diagnosis — symptoms are collected for an informational AI-assisted
/// prediction flow only.
class Symptom {
  final String id;
  final String name;

  const Symptom({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      other is Symptom && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => name;
}
