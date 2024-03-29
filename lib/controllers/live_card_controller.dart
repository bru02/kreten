import 'dart:async';

import 'package:filcnaplo_kreta_api/models/lesson.dart';
import 'package:filcnaplo_kreta_api/models/week.dart';
import 'package:filcnaplo_kreta_api/providers/timetable_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class LiveCardController extends ChangeNotifier {
  Lesson? currentLesson;
  Lesson? nextLesson;
  List<Lesson>? nextLessons;
  final AnimationController animation;

  BuildContext context;
  late Timer _timer;

  LiveCardController({required this.context, required TickerProvider vsync})
      : animation = AnimationController(
          duration: Duration(milliseconds: 500),
          vsync: vsync,
        ) {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) => update());
    update(duration: 0);
  }

  @override
  void dispose() {
    _timer.cancel();
    animation.dispose();
    super.dispose();
  }

  void update({int duration = 500}) async {
    final lessonProvider = Provider.of<TimetableProvider>(context, listen: false);
    List<Lesson> today = _today(lessonProvider);

    if (today.length == 0) {
      await lessonProvider.fetch(week: Week.current());
      today = _today(lessonProvider);
    }

    if (today.length > 0) {
      final now = DateTime.now();
      bool notify = false;

      // sort
      today.sort((a, b) => a.start.compareTo(b.start));

      final _lesson = today.firstWhere((l) => l.start.isBefore(now) && l.end.isAfter(now), orElse: () => Lesson.fromJson({}));
      final _next = today.firstWhere((l) => l.start.isAfter(_lesson.end), orElse: () => Lesson.fromJson({}));
      nextLessons = today.where((l) => l.start.isAfter(_lesson.end)).toList();

      if (_lesson.start.year != 0) {
        currentLesson = _lesson;
        notify = true;
      } else {
        if (currentLesson != null) notify = true;
        currentLesson = null;
      }

      if (_next.start.year != 0) {
        nextLesson = _next;
      } else {
        nextLesson = null;
      }

      animation.animateTo(show ? 1.0 : 0.0, curve: Curves.easeInOut, duration: Duration(milliseconds: duration));

      if (notify) notifyListeners();
    }
  }

  bool get show => currentLesson != null;

  bool _sameDate(DateTime a, DateTime b) => (a.year == b.year && a.month == b.month && a.day == b.day);

  List<Lesson> _today(TimetableProvider p) => p.lessons.where((l) => _sameDate(l.date, DateTime.now())).toList();
}
