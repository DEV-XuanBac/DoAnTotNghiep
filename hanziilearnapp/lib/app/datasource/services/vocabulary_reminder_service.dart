import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hanziilearnapp/app/datasource/repository/notebook_repository.dart';
import 'package:hanziilearnapp/app/models/notebook_word_item.dart';
import 'package:hanziilearnapp/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const String _kPrefEnabled = 'vocab_reminder_enabled';
const String _kPrefUid = 'vocab_reminder_user_uid';

const String kVocabularyReminderTaskId =
    'com.example.hanziilearnapp.vocabulary.periodic';

const int _kNotificationId = 94001;
const String _kAndroidChannelId = 'hanzii_vocab_favorites';

final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

/// Entry cho Workmanager (isolate nền).
@pragma('vm:entry-point')
void vocabularyReminderCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != kVocabularyReminderTaskId &&
        task != Workmanager.iOSBackgroundTask) {
      return Future.value(true);
    }
    if (task == Workmanager.iOSBackgroundTask) {
      return Future.value(true);
    }
    await VocabularyReminderService.runBackgroundFetch();
    return Future.value(true);
  });
}

abstract final class VocabularyReminderService {
  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> setup() async {
    if (!_supported) {
      return;
    }
    await _ensureLocalNotificationsReady();
    await Workmanager().initialize(vocabularyReminderCallbackDispatcher);
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPrefEnabled) ?? false;
  }

  static Future<void> syncScheduleWithPrefs() async {
    if (!_supported) return;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kPrefEnabled) ?? false;
    final uid = prefs.getString(_kPrefUid);
    final user = FirebaseAuth.instance.currentUser;
    if (!enabled || uid == null || uid.isEmpty) {
      return;
    }
    if (user == null || user.uid != uid) {
      return;
    }
    await registerPeriodicWork();
  }

  static Future<void> enableForUser(String userId) async {
    if (!_supported) return;
    await _requestNotificationPermissions();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefEnabled, true);
    await prefs.setString(_kPrefUid, userId);
    await registerPeriodicWork();
  }

  static Future<void> disable() async {
    if (!_supported) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefEnabled, false);
      await prefs.remove(_kPrefUid);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefEnabled, false);
    await prefs.remove(_kPrefUid);
    await Workmanager().cancelByUniqueName(kVocabularyReminderTaskId);
  }

  static Future<void> disableOnLogout() async {
    if (!_supported) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefEnabled, false);
      await prefs.remove(_kPrefUid);
      return;
    }
    await Workmanager().cancelByUniqueName(kVocabularyReminderTaskId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefEnabled, false);
    await prefs.remove(_kPrefUid);
  }

  static Future<void> registerPeriodicWork() async {
    if (!_supported) return;
    await Workmanager().registerPeriodicTask(
      kVocabularyReminderTaskId,
      kVocabularyReminderTaskId,
      frequency: const Duration(hours: 3),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static Future<void> _requestNotificationPermissions() async {
    if (!_supported) return;
    if (Platform.isAndroid) {
      final android = _fln
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _fln
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> _ensureLocalNotificationsReady() async {
    await _fln.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _kAndroidChannelId,
        'Nhắc nhở học tập',
        description: 'Nhắc ngẫu nhiên một từ yêu thích trong sổ tay mỗi 3 giờ',
        importance: Importance.defaultImportance,
      );
      await _fln
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  @visibleForTesting
  static String buildNotificationBody(NotebookWordItem item) {
    final w = item.word;
    final line1 = '${w.hanzi} — ${w.pinyin}';
    final line2 = w.meaning;
    final note = item.note.trim();
    if (note.isEmpty) {
      return '$line1\n$line2';
    }
    return '$line1\n$line2\n$note';
  }

  static Future<void> runBackgroundFetch() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _ensureLocalNotificationsReady();

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kPrefEnabled) ?? false)) {
      return;
    }
    final savedUid = prefs.getString(_kPrefUid);
    if (savedUid == null || savedUid.isEmpty) {
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != savedUid) {
      for (var i = 0; i < 8; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        user = FirebaseAuth.instance.currentUser;
        if (user != null && user.uid == savedUid) {
          break;
        }
      }
    }
    if (user == null || user.uid != savedUid) {
      return;
    }

    final repo = NotebookRepository();
    final items = await repo.listItemsForUser(user.uid);
    final favorites = items.where((e) => e.isFavorite).toList();

    const title = 'Nhắc nhở học tập';
    if (favorites.isEmpty) {
      await _showNotification(
        title: title,
        body:
            'Bạn chưa có từ yêu thích trong sổ tay.\nMở Sổ tay → đánh dấu yêu thích để nhận nhắc học.',
      );
      return;
    }

    final pick = favorites[math.Random().nextInt(favorites.length)];
    final body = buildNotificationBody(pick);
    await _showNotification(title: title, body: body);
  }

  static Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _kAndroidChannelId,
      'Nhắc nhở học tập',
      channelDescription: 'Nhắc từ yêu thích trong sổ tay',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(body),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _fln.show(
      id: _kNotificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }
}
