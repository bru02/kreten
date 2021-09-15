import 'dart:convert';
import 'package:filcnaplo/api/providers/user_provider.dart';
import 'package:filcnaplo/api/providers/database_provider.dart';
import 'package:filcnaplo/models/user.dart';
import 'package:filcnaplo_kreta_api/client/api.dart';
import 'package:filcnaplo_kreta_api/client/client.dart';
import 'package:filcnaplo_kreta_api/controllers/timetable_controller.dart';
import 'package:filcnaplo_kreta_api/models/lesson.dart';
import 'package:filcnaplo_kreta_api/models/week.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';

class TimetableProvider with ChangeNotifier {
  late List<Lesson> _lessons;
  late BuildContext _context;

  List<Lesson> get lessons => _lessons;

  TimetableProvider({
    List<Lesson> initialLessons = const [],
    required BuildContext context,
  }) {
    _lessons = _wrapLessons(List.castFrom(initialLessons));
    _context = context;

    Provider.of<DatabaseProvider>(_context, listen: false).query.getRecurringLessonOverrides().then((overrides) {
      overrides.forEach((Map map) {
        _set(_recurringOverridesByKey, _getKey(map['dayhash_or_weekid'], map['lesson_start_or_id']), map['kind'], map['value']);
      });
    });

    if (_lessons.length == 0) restore();
  }

  Future<void> restore() async {
    String? userId = Provider.of<UserProvider>(_context, listen: false).id;

    // Load lessons from the database
    if (userId != null) {
      var dbLessons = await Provider.of<DatabaseProvider>(_context, listen: false).userQuery.getLessons(userId: userId);
      _lessons = _wrapLessons(dbLessons);
      notifyListeners();
    }
  }

  // Fetches Lessons from the Kreta API then stores them in the database
  Future<void> fetch({Week? week, bool db = true}) async {
    if (week == null) return;
    User? user = Provider.of<UserProvider>(_context, listen: false).user;
    if (user == null) throw "Cannot fetch Lessons for User null";
    String iss = user.instituteCode;
    List? lessonsJson = await Provider.of<KretaClient>(_context, listen: false).getAPI(KretaAPI.timetable(iss, start: week.start, end: week.end));
    if (lessonsJson == null) throw "Cannot fetch Lessons for User ${user.id}";
    List<Lesson> lessons = lessonsJson.map((e) => Lesson.fromJson(e)).toList();

    if (lessons.length == 0 && _lessons.length == 0) return;

    if (db) await store(lessons);

    // Overrides
    await _fetchOverridesForWeek(TimetableController.getWeekId(week));
    _lessons = _wrapLessons(lessons);

    notifyListeners();
  }

  // Stores Lessons in the database
  Future<void> store(List<Lesson> lessons) async {
    User? user = Provider.of<UserProvider>(_context, listen: false).user;
    if (user == null) throw "Cannot store Lessons for User null";
    String userId = user.id;

    await Provider.of<DatabaseProvider>(_context, listen: false).userStore.storeLessons(lessons, userId: userId);
  }

  /// Overrides each lesson's properties
  List<Lesson> _wrapLessons(List<Lesson> lessons) {
    return List.from(lessons.map((l) {
      Map overrides = getOverridesForLesson(l);
      if (overrides.isEmpty) return l;

      Map<String, dynamic> lessonMap = l.toJson();
      overrides.forEach((key, value) {
        if (lessonMap.containsKey(key) && lessonMap[key] is String) {
          if (lessonMap[key] != value) print("override[$key]: ${lessonMap[key]} -> $value");
          lessonMap[key] = value;
        } else {
          print("[timetable provider]: unsupported override kind $key. value=$value");
        }
      });
      return Lesson.fromFilcJson(lessonMap);
    }));
  }

  final Map<String, Map<String, String>> _recurringOverridesByKey = Map();
  final Map<String, Map<String, String>> _overridesByLessonId = Map();
  final Set<int> _fetchedWeeks = Set();
  final Map<DateTime, String> _dateDayHashMap = Map();

  Future<void> _fetchOverridesForWeek(int weekId) async {
    if (_fetchedWeeks.contains(weekId)) return;
    _fetchedWeeks.add(weekId);
    List<Map> overrides = await Provider.of<DatabaseProvider>(_context, listen: false).query.getLessonOverridesForWeek(weekId);
    overrides.forEach((Map map) {
      _set(_overridesByLessonId, map['lesson_start_or_id'], map['kind'], map['value']);
    });
  }

  String? getOverrideOfKind(Lesson l, String kind) {
    return _overridesByLessonId[l.id]?[kind] ?? _recurringOverridesByKey[_getKeyForLesson(l)]?[kind];
  }

  Map<String, String> getOverridesForLesson(Lesson l) {
    return {..._recurringOverridesByKey[_getKeyForLesson(l)] ?? {}, ..._overridesByLessonId[l.id] ?? {}};
  }

  List<String> getRecurringOverridesOfKind(String kind) {
    return _recurringOverridesByKey.values.map((m) => m[kind] ?? '').where((s) => s.isNotEmpty).toSet().toList()..sort();
  }

  Future<void> override(Lesson l, String kind, String value, {bool recurring = false}) async {
    var store = Provider.of<DatabaseProvider>(_context, listen: false).store;
    if (recurring) {
      await store.setRecurringLessonOverride(_getDayHashForLesson(l), _getLessonStart(l), kind, value);
      _set(_recurringOverridesByKey, _getKeyForLesson(l), kind, value);
    } else {
      await store.setLessonOverride(_getWeekIdForLesson(l).toString(), l.id, kind, value);
      _set(_overridesByLessonId, l.id, kind, value);
    }
    _lessons = _wrapLessons(_lessons);
    notifyListeners();
  }

  String _getDayHashForLesson(Lesson lesson) {
    if (_dateDayHashMap.containsKey(lesson.date)) {
      return _dateDayHashMap[lesson.date]!;
    }

    List<Lesson> lessons = _lessons.where((l) => _sameDate(l.date, lesson.date) && l.lessonIndex != "+" && l.subject.id != '').toList();

    List<int> bytes = utf8.encode(lessons.map((e) => e.lessonIndex + e.subject.name).join());

    String hash = sha1.convert(bytes).toString();
    _dateDayHashMap[lesson.date] = hash;
    return hash;
  }

  int _getWeekIdForLesson(Lesson l) {
    return TimetableController.getWeekId(Week(
      start: l.date.subtract(Duration(days: l.date.weekday - 1)),
      end: DateTime.now(),
    ));
  }

  _set(Map<String, Map<String, String>> what, String key1, String key2, String value) {
    if (!what.containsKey(key1)) what[key1] = Map();
    if (value.isNotEmpty)
      what[key1]![key2] = value;
    else
      what[key1]!.remove(key2);
  }

  _getKey(String dayHash, String index) {
    return "$dayHash-$index";
  }

  _getKeyForLesson(Lesson l) {
    return _getKey(_getDayHashForLesson(l), _getLessonStart(l).toString());
  }

  int _getLessonStart(Lesson l) {
    return ((l.start.millisecondsSinceEpoch - l.date.millisecondsSinceEpoch) / 1000).round();
  }

  bool _sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
