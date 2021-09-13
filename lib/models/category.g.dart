// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
      id: json['Uid'] as String,
      description: json['Leiras'] as String? ?? "",
      name: json['Nev'] as String? ?? "",
    );

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
      'Uid': instance.id,
      'Leiras': instance.description,
      'Nev': instance.name,
    };
