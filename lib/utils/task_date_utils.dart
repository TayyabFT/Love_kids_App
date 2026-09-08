import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Local calendar-date helpers for task due dates (avoids UTC day shifts).
class TaskDateUtils {
  TaskDateUtils._();

  static DateTime localNow() => DateTime.now();

  /// Today at 00:00 in the device timezone.
  static DateTime todayDateOnly() {
    final now = localNow();
    return DateTime(now.year, now.month, now.day);
  }

  /// Normalizes any [DateTime] to local wall-clock time.
  static DateTime toLocalDateTime(DateTime value) => value.toLocal();

  /// Strips time, keeping the calendar day in local timezone.
  static DateTime dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    final day = dateOnly(date);
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  static bool isSameCalendarDay(DateTime a, DateTime b) {
    final al = dateOnly(a);
    final bl = dateOnly(b);
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  static bool isToday(DateTime value) => isSameCalendarDay(value, localNow());

  static DateTime parseDueDate(dynamic value) {
    if (value is Timestamp) {
      return toLocalDateTime(value.toDate());
    }
    if (value is DateTime) {
      return toLocalDateTime(value);
    }
    throw ArgumentError('Invalid dueDate value: $value');
  }

  static DateTime? parseOptionalTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return toLocalDateTime(value.toDate());
    if (value is DateTime) return toLocalDateTime(value);
    return null;
  }

  static String formatDueDate(DateTime dueDate) {
    return DateFormat('MMMM d, yyyy').format(toLocalDateTime(dueDate));
  }
}
