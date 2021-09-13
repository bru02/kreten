// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lesson _$LessonFromJson(Map<String, dynamic> json) => Lesson(
      status: json['status'] == null
          ? null
          : Category.fromJson(json['status'] as Map<String, dynamic>),
      date: DateTime.parse(json['date'] as String),
      subject: Subject.fromJson(json['subject'] as Map<String, dynamic>),
      lessonIndex: json['lessonIndex'] as String,
      lessonYearIndex: json['lessonYearIndex'] as int?,
      substituteTeacher: json['substituteTeacher'] as String? ?? "",
      teacher: json['teacher'] as String,
      homeworkEnabled: json['homeworkEnabled'] as bool? ?? false,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      studentPresence: json['studentPresence'] == null
          ? null
          : Category.fromJson(json['studentPresence'] as Map<String, dynamic>),
      homeworkId: json['homeworkId'] as String,
      exams: json['exams'] as List<dynamic>? ?? const [],
      id: json['id'] as String,
      type: json['type'] == null
          ? null
          : Category.fromJson(json['type'] as Map<String, dynamic>),
      description: json['description'] as String,
      room: json['room'] as String,
      groupName: json['groupName'] as String,
      name: json['name'] as String,
      online: json['online'] as bool? ?? false,
      isEmpty: json['isEmpty'] as bool? ?? false,
      json: json['json'] as Map<String, dynamic>?,
      original: Lesson.fromFilcJson(json['original'] as Map<String, dynamic>?),
    );

Map<String, dynamic> _$LessonToJson(Lesson instance) => <String, dynamic>{
      'json': instance.json,
      'status': instance.status?.toJson(),
      'date': instance.date.toIso8601String(),
      'subject': instance.subject.toJson(),
      'lessonIndex': instance.lessonIndex,
      'lessonYearIndex': instance.lessonYearIndex,
      'substituteTeacher': instance.substituteTeacher,
      'teacher': instance.teacher,
      'homeworkEnabled': instance.homeworkEnabled,
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'studentPresence': instance.studentPresence?.toJson(),
      'homeworkId': instance.homeworkId,
      'exams': instance.exams,
      'id': instance.id,
      'type': instance.type?.toJson(),
      'description': instance.description,
      'room': instance.room,
      'groupName': instance.groupName,
      'name': instance.name,
      'online': instance.online,
      'isEmpty': instance.isEmpty,
      'original': instance.original?.toJson(),
    };
