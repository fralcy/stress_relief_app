import 'package:flutter/material.dart';

class TimePickerProvider extends ChangeNotifier {
  TimePickerProvider(TimeOfDay initial)
      : hour = initial.hour,
        minute = initial.minute;

  int hour;
  int minute;
  bool editingHour = false;
  bool editingMinute = false;

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  void setHour(int h) {
    hour = h;
    notifyListeners();
  }

  void setMinute(int m) {
    minute = m;
    notifyListeners();
  }

  void startEditHour() {
    editingHour = true;
    notifyListeners();
  }

  void commitHour(int? h) {
    editingHour = false;
    if (h != null) hour = h;
    notifyListeners();
  }

  void startEditMinute() {
    editingMinute = true;
    notifyListeners();
  }

  void commitMinute(int? m) {
    editingMinute = false;
    if (m != null) minute = m;
    notifyListeners();
  }

  void syncFromTime(TimeOfDay t) {
    bool changed = false;
    if (hour != t.hour) {
      hour = t.hour;
      changed = true;
    }
    if (minute != t.minute) {
      minute = t.minute;
      changed = true;
    }
    if (changed) notifyListeners();
  }
}
