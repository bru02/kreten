import 'category.dart';
import 'package:json_annotation/json_annotation.dart';
part 'subject.g.dart';

@JsonSerializable(explicitToJson: true)
class Subject {
  @JsonKey(name: 'Uid')
  String id;
  @JsonKey(name: 'Kategoria')
  Category category;
  @JsonKey(name: 'Nev')
  String name;

  Subject({
    required this.id,
    required this.category,
    required this.name,
  });

  factory Subject.fromJson(Map json) {
    return Subject(
      id: json["Uid"] ?? "",
      category: Category.fromJson(json["Kategoria"] ?? {}),
      name: (json["Nev"] ?? "").trim(),
    );
  }

  @override
  bool operator ==(other) {
    if (other is! Subject) return false;
    return id == other.id;
  }

  Map<String, dynamic> toJson() => _$SubjectToJson(this);

  @override
  int get hashCode => id.hashCode;
}
