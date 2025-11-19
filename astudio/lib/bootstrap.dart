import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadEnvironment();

  final supabaseUrl = _resolveConfig(
    key: 'SUPABASE_URL',
    fallback: AppConfig.supabaseUrl,
  );
  final supabaseAnonKey = _resolveConfig(
    key: 'SUPABASE_ANON_KEY',
    fallback: AppConfig.supabaseAnonKey,
  );

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'Configuration Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Missing Supabase configuration.\n\n'
                    'Please provide SUPABASE_URL and SUPABASE_ANON_KEY:\n\n'
                    '1. Create a .env file in the project root with:\n'
                    '   SUPABASE_URL=your-project-url\n'
                    '   SUPABASE_ANON_KEY=your-anon-key\n\n'
                    '2. Or use --dart-define flags when running:\n'
                    '   flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Reload the page
                      if (kIsWeb) {
                        // ignore: avoid_web_libraries_in_flutter
                        // ignore: undefined_prefixed_name
                        // dart:html is not available in all platforms
                      }
                    },
                    child: const Text('Check Console for Details'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.warn,
      ),
    );
  } catch (e, stackTrace) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to initialize Supabase:\n\n$e',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Stack trace:\n$stackTrace',
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(const ProviderScope(child: App()));
}

Future<void> _loadEnvironment() async {
  try {
    await dotenv.load(fileName: '.env');
    if (kDebugMode) {
      print('✓ Loaded .env file');
      print(
        '  SUPABASE_URL: ${dotenv.env['SUPABASE_URL']?.isNotEmpty == true ? '✓ Set' : '✗ Missing'}',
      );
      print(
        '  SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty == true ? '✓ Set' : '✗ Missing'}',
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠ Could not load .env file: $e');
      print('  Using --dart-define or AppConfig fallback values');
    }
    // Ignore missing .env files to allow using --dart-define or other sources.
  }
}

String _resolveConfig({required String key, required String fallback}) {
  final envValue = dotenv.env[key];
  if (envValue != null && envValue.isNotEmpty) {
    return envValue;
  }
  return fallback;
}
