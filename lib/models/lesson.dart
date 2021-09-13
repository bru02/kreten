import 'package:filcnaplo_kreta_api/providers/timetable_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'subject.dart';
import 'category.dart';
import 'package:json_annotation/json_annotation.dart';
part 'lesson.g.dart';

@JsonSerializable(explicitToJson: true)
class Lesson {
  Map? json;
  Category? status;
  DateTime date;
  Subject subject;
  String lessonIndex;
  int? lessonYearIndex;
  String substituteTeacher;
  String teacher;
  bool homeworkEnabled;
  DateTime start;
  DateTime end;
  Category? studentPresence;
  String homeworkId;
  List exams;
  String id;
  Category? type;
  String description;
  String room;
  String groupName;
  String name;
  bool online;
  bool isEmpty;

  /// Contains a copy of the lesson, without overrides.
  @JsonKey(fromJson: fromFilcJson)
  Lesson? original;

  Lesson({
    this.status,
    required this.date,
    required this.subject,
    required this.lessonIndex,
    this.lessonYearIndex,
    this.substituteTeacher = "",
    required this.teacher,
    this.homeworkEnabled = false,
    required this.start,
    required this.end,
    this.studentPresence,
    required this.homeworkId,
    this.exams = const [],
    required this.id,
    this.type,
    required this.description,
    required this.room,
    required this.groupName,
    required this.name,
    this.online = false,
    this.isEmpty = false,
    this.json,
    this.original,
  });

  factory Lesson.fromJson(Map json, {bool isOriginal = false}) {
    return Lesson(
        id: json["Uid"] ?? "",
        status: json["Allapot"] != null ? Category.fromJson(json["Allapot"]) : null,
        date: json["Datum"] != null ? DateTime.parse(json["Datum"]).toLocal() : DateTime(0),
        subject: Subject.fromJson(json["Tantargy"] ?? {}),
        lessonIndex: json["Oraszam"] != null ? json["Oraszam"].toString() : "+",
        lessonYearIndex: json["OraEvesSorszama"],
        substituteTeacher: (json["HelyettesTanarNeve"] ?? "").trim(),
        teacher: (json["TanarNeve"] ?? "").trim(),
        homeworkEnabled: json["IsTanuloHaziFeladatEnabled"] ?? false,
        start: json["KezdetIdopont"] != null ? DateTime.parse(json["KezdetIdopont"]).toLocal() : DateTime(0),
        end: json["VegIdopont"] != null ? DateTime.parse(json["VegIdopont"]).toLocal() : DateTime(0),
        homeworkId: json["HaziFeladatUid"] ?? "",
        exams: json["BejelentettSzamonkeresUids"] != null ? json["BejelentettSzamonkeresUids"] : [],
        type: json["Tipus"] != null ? Category.fromJson(json["Tipus"]) : null,
        description: json["Tema"] ?? "",
        room: json["TeremNeve"]?.replaceAll("_", " ") ?? "",
        groupName: json["OsztalyCsoport"] != null ? json["OsztalyCsoport"]["Nev"] ?? "" : "",
        name: json["Nev"] ?? "",
        online: json["IsDigitalisOra"] ?? false,
        isEmpty: json['isEmpty'] ?? false,
        json: json,
        original: isOriginal ? null : Lesson.fromJson(json, isOriginal: true));
  }

  static fromFilcJson(Map<String, dynamic>? json) => json != null ? _$LessonFromJson(json) : null;
  Map<String, dynamic> toJson() => _$LessonToJson(this);

  bool hasOverride(String kind) {
    return this.toJson()[kind] != this.original?.toJson()[kind];
  }

  Lesson reactive(BuildContext context) {
    return Provider.of<TimetableProvider>(context).lessons.firstWhere((l) => l.id == this.id, orElse: () => this);
  }
}
