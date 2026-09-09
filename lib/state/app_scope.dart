import 'package:flutter/widgets.dart';

import 'app_store.dart';

/// Makes the single [AppStore] instance available anywhere below it in the
/// tree, and rebuilds dependents whenever it changes.
class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child}) : super(notifier: store);

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    final store = scope?.notifier;
    if (store == null) {
      // An assert alone would be stripped from release builds, turning this
      // into an opaque "Null check operator used on a null value" crash.
      throw FlutterError(
        'No AppScope found above this widget.\n'
        'AppScope must wrap MaterialApp so that routes pushed onto its '
        'Navigator can still reach the store.',
      );
    }
    return store;
  }
}
