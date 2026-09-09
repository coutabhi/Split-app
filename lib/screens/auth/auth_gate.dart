import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../state/app_scope.dart';
import '../../state/app_store.dart';
import '../root_shell.dart';
import 'sign_in_screen.dart';

/// Shows the sign-in flow when signed out, otherwise starts the realtime
/// Supabase-backed [AppStore] and shows the app once its first load
/// completes.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AppStore _store = AppStore(Supabase.instance.client);
  late StreamSubscription<AuthState> _authSub;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _session = Supabase.instance.client.auth.currentSession;
    if (_session != null) _store.startListening();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final hadSession = _session != null;
      final hasSession = data.session != null;
      if (hasSession && !hadSession) {
        _store.startListening();
      } else if (!hasSession && hadSession) {
        _store.stopListening();
      }
      setState(() => _session = data.session);
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _store.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) return const SignInScreen();

    return AppScope(
      store: _store,
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (!_store.loaded) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return const RootShell();
        },
      ),
    );
  }
}
