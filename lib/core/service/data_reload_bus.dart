import 'package:flutter/foundation.dart';

class DataReloadBus {
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static void notify() {
    notifier.value += 1;
  }
}
