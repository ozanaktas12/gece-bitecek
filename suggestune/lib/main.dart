import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:suggestune/spotify/spotify_auth.dart';
import 'package:suggestune/spotify/spotify_session.dart';
import 'package:suggestune/ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env');
  runApp(const SuggestuneApp());
}

class SuggestuneApp extends StatelessWidget {
  const SuggestuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suggestune',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BootPage(),
    );
  }
}

class BootPage extends StatefulWidget {
  const BootPage({super.key});

  @override
  State<BootPage> createState() => _BootPageState();
}

class _BootPageState extends State<BootPage> {
  final SpotifySession _session = SpotifySession();
  Future<bool>? _signedInFuture;

  @override
  void initState() {
    super.initState();
    _signedInFuture = _checkSignedIn();
  }

  Future<bool> _checkSignedIn() async {
    try {
      final token = await _session.getValidAccessToken();
      return token != null;
    } catch (_) {
      await _session.signOut();
      return false;
    }
  }

  Future<void> _onSignedIn() async {
    setState(() {
      _signedInFuture = _checkSignedIn();
    });
  }

  Future<void> _onSignOut() async {
    await _session.signOut();
    setState(() {
      _signedInFuture = Future.value(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _signedInFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final signedIn = snapshot.data ?? false;
        if (!signedIn) {
          return LoginPage(
            session: _session,
            onSuccess: _onSignedIn,
          );
        }
        return HomeShell(
          session: _session,
          onSignOut: _onSignOut,
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.session,
    required this.onSuccess,
  });

  final SpotifySession session;
  final Future<void> Function() onSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _status;
  bool _busy = false;

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final tokens = await SpotifyAuth.signInWithPkce();
      await widget.session.saveFromSignIn(tokens);
      await widget.onSuccess();
    } on SpotifyAuthException catch (e) {
      if (!mounted) return;
      setState(() => _status = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suggestune')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Spotify ile giriş (PKCE). Client Secret uygulamada kullanılmaz.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _connect,
              child: Text(_busy ? 'Bekleyin…' : 'Spotify ile bağlan'),
            ),
            if (_status != null) ...[
              const SizedBox(height: 24),
              Text(_status!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
