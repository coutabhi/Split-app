import 'package:flutter/material.dart';

import 'screens/root_shell.dart';
import 'services/data_store.dart';
import 'services/settings_store.dart';
import 'state/app_scope.dart';
import 'state/app_store.dart';
import 'theme/app_theme.dart';
import 'widgets/currency_scope.dart';

void main() {
  runApp(const OfficeSplitApp());
}

class OfficeSplitApp extends StatefulWidget {
  const OfficeSplitApp({super.key});

  @override
  State<OfficeSplitApp> createState() => _OfficeSplitAppState();
}

class _OfficeSplitAppState extends State<OfficeSplitApp> {
  final _settingsStore = SettingsStore();
  final _appStore = AppStore(DataStore());
  String _currency = '₹';

  @override
  void initState() {
    super.initState();
    _appStore.load();
    _settingsStore.loadCurrency().then((c) {
      if (mounted) setState(() => _currency = c);
    });
  }

  void _setCurrency(String symbol) {
    setState(() => _currency = symbol);
    _settingsStore.saveCurrency(symbol);
  }

  @override
  Widget build(BuildContext context) {
    return CurrencyScope(
      symbol: _currency,
      setSymbol: _setCurrency,
      child: AppScope(
        store: _appStore,
        child: MaterialApp(
          title: 'OfficeSplit',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          home: ListenableBuilder(
            listenable: _appStore,
            builder: (context, _) {
              if (!_appStore.loaded) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return const RootShell();
            },
          ),
        ),
      ),
    );
  }
}
