import 'package:filcnaplo/api/providers/user_provider.dart';
import 'package:filcnaplo/api/providers/database_provider.dart';
import 'package:filcnaplo/models/user.dart';
import 'package:filcnaplo_kreta_api/client/api.dart';
import 'package:filcnaplo_kreta_api/client/client.dart';
import 'package:filcnaplo_kreta_api/models/lesson.dart';
import 'package:filcnaplo_kreta_api/models/week.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TimetableProvider with ChangeNotifier {
  late List<Lesson> _lessons;
  late BuildContext _context;
  List<Lesson> get lessons => _lessons;

  TimetableProvider({
    List<Lesson> initialLessons = const [],
    required BuildContext context,
  }) {
    _lessons = List.castFrom(initialLessons);
    _context = context;

    if (_lessons.length == 0) restore();
  }

  Future<void> restore() async {
    String? userId = Provider.of<UserProvider>(_context, listen: false).id;

    // Load lessons from the database
    if (userId != null) {
      var dbLessons = await Provider.of<DatabaseProvider>(_context, listen: false).userQuery.getLessons(userId: userId);
      _lessons = dbLessons;
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
    _lessons = lessons;
    notifyListeners();
  }

  // Stores Lessons in the database
  Future<void> store(List<Lesson> lessons) async {
    User? user = Provider.of<UserProvider>(_context, listen: false).user;
    if (user == null) throw "Cannot store Lessons for User null";
    String userId = user.id;
    await Provider.of<DatabaseProvider>(_context, listen: false).userStore.storeLessons(lessons, userId: userId);
  }
}