import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:hanziilearnapp/firebase_options.dart';
import 'package:hanziilearnapp/app/datasource/network_services/hsk_import_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _authenticateIfConfigured();

  stdout.writeln('Starting HSK word import...');

  try {
    final total = await HskImportService().importFromAsset();
    stdout.writeln('Import completed successfully. Total words: $total');
    exitCode = 0;
  } catch (error, stackTrace) {
    stderr.writeln('Import failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }

  await Future<void>.delayed(const Duration(milliseconds: 300));
  exit(exitCode);
}

Future<void> _authenticateIfConfigured() async {
  final email = Platform.environment['IMPORT_FIREBASE_EMAIL'];
  final password = Platform.environment['IMPORT_FIREBASE_PASSWORD'];

  if (email == null || password == null) {
    stdout.writeln(
      'No auth env found. Running import without sign-in.',
    );
    return;
  }

  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );

  stdout.writeln('Signed in as $email');
}
