import 'package:flutter/material.dart';
import 'package:hovr_app_update/hovr_app_update.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Not configured';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _configurePlugin();
  }

  Future<void> _configurePlugin() async {
    await HovrAppUpdate.configure(
      const AppUpdateConfig(iosAppStoreId: '1585783552'),
    );
    if (!mounted) return;
    setState(() => _status = 'Configured');
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _busy = true;
      _status = 'Checking...';
    });

    try {
      await HovrAppUpdate.promptIfUpdateRequired(serverVersion: '99.0.0');
      if (!mounted) return;
      setState(() => _status = 'Update check completed');
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Update check failed: $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('hovr_app_update example')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _checkForUpdate,
                  child: const Text('Prompt update (demo server 99.0.0)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
