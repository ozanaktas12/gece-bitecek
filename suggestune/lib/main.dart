import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:suggestune/spotify/spotify_auth.dart';

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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _status;
  bool _busy = false;

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final tokens = await SpotifyAuth.signInWithPkce();
      if (!mounted) return;
      setState(() {
        _status =
            'Bağlandı. Access token uzunluğu: ${tokens.accessToken.length} karakter.';
      });
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
