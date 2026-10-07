class ChildProfile {
  const ChildProfile({required this.name, required this.age, required this.colorIndex});
  final String name;
  final int age;
  final int colorIndex;

  Map<String, dynamic> toJson() => {'name': name, 'age': age, 'color': colorIndex};

  factory ChildProfile.fromJson(Map<String, dynamic> j) {
    final age = ((j['age'] as num?)?.toInt() ?? 4).clamp(3, 5).toInt();
    final name = (j['name'] as String?)?.trim() ?? '';
    return ChildProfile(
      name: name.isEmpty ? '⭐' : name,
      age: age,
      colorIndex: (j['color'] as num?)?.toInt() ?? 0,
    );
  }

  ChildProfile copyWith({String? name, int? age, int? colorIndex}) =>
      ChildProfile(name: name ?? this.name, age: age ?? this.age, colorIndex: colorIndex ?? this.colorIndex);
}
