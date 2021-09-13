// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subject _$SubjectFromJson(Map<String, dynamic> json) => Subject(
      id: json['Uid'] as String,
      category: Category.fromJson(json['Kategoria'] as Map<String, dynamic>),
      name: json['Nev'] as String,
    );

Map<String, dynamic> _$SubjectToJson(Subject instance) => <String, dynamic>{
      'Uid': instance.id,
      'Kategoria': instance.category.toJson(),
      'Nev': instance.name,
    };
