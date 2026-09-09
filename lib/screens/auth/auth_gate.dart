import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../state/app_scope.dart';
import '../root_shell.dart';
import 'sign_in_screen.dart';

/// Shows the sign-in flow when signed out, otherwise starts the realtime
/// Supabase-backed store and shows the app once its first load completes.
///
/// The store itself lives above MaterialApp (see main.dart) so pushed
/// routes can reach it; this widget only drives its lifecycle.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSub;
  Session? _session;
  bool _wired = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wired) return;
    _wired = true;

    final store = AppScope.of(context);
    _session = Supabase.instance.client.auth.currentSession;
    if (_session != null) store.startListening();

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final hadSession = _session != null;
      final hasSession = data.session != null;
      if (hasSession && !hadSession) {
        store.startListening();
      } else if (!hasSession && hadSession) {
        store.stopListening();
      }
      if (mounted) setState(() => _session = data.session);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) return const SignInScreen();

    final store = AppScope.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!store.loaded) {
          if (store.loadError != null) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 48),
                      const SizedBox(height: 12),
                      Text(store.loadError!, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: store.startListening,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return const RootShell();
      },
    );
  }
}
