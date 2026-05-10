import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:monetrack/core/utils/message_parser.dart';
import 'package:monetrack/data/datasources/database_helper.dart';
import 'package:monetrack/data/repositories/transaction_repository_impl.dart';
import 'package:monetrack/domain/entities/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'monetrack_foreground', // id
    'Monetrack Service', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'monetrack_foreground',
      initialNotificationTitle: 'Monetrack Service',
      initialNotificationContent: 'Monitoring for transactions...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Initialize dependencies
  final parser = MessageParser();
  parser.loadRules(); // Note: This might need to be async or loaded from assets differently in background

  // Polling timer to check for new notifications from Native
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Monetrack Service",
          content: "Monitoring for transactions...",
        );
      }
    }

    await _checkAndProcessNotifications(parser);
  });
}

Future<void> _checkAndProcessNotifications(MessageParser parser) async {
  try {
    // Use the specific prefix for Flutter SharedPreferences on Android
    final prefs = await SharedPreferences.getInstance();
    
    // Key used by Native NotificationService to store pending notifications
    const key = 'pending_notifications';
    final List<String>? pending = prefs.getStringList(key);

    if (pending != null && pending.isNotEmpty) {
      // Check if auto-add is enabled
      final autoAdd = prefs.getBool('auto_add') ?? false;
      if (!autoAdd) {
        // If disabled, just clear the pending list so they don't pile up? 
        // Or keep them until enabled? 
        // Better to ignore processing but maybe not clear if we want them later?
        // Standard behavior: if feature is off, we don't import.
        // Clearing them prevents backlog.
        await prefs.setStringList(key, []);
        return;
      }

      print('Background Service: Found ${pending.length} pending notifications');
      
      final dbHelper = DatabaseHelper.instance;
      final repo = TransactionRepositoryImpl(dbHelper);

      for (final jsonStr in pending) {
        // Simple parsing assuming format "package|title|text"
        // Or we can use a proper JSON structure. 
        // Let's assume the native side saves as "package|title|text" string for simplicity
        // or we can parse JSON if we used JSON.
        
        // Let's stick to a simple delimiter for now to avoid complex JSON parsing without a library
        final parts = jsonStr.split('|||');
        if (parts.length < 3) continue;
        
        final packageName = parts[0];
        // final title = parts[1]; 
        final text = parts[2];

        final transaction = parser.parse(text);
        if (transaction != null) {
          final newTransaction = TransactionEntity(
            id: const Uuid().v4(),
            amount: transaction.amount,
            currency: 'INR',
            type: transaction.type,
            date: transaction.date ?? DateTime.now(),
            payee: transaction.payee,
            notes: 'Auto-imported from $packageName (Background)',
            source: 'auto',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await repo.addTransaction(newTransaction);
          print('Background Service: Added transaction ${transaction.amount}');
        }
      }

      // Clear processed notifications
      await prefs.setStringList(key, []);
    }
  } catch (e) {
    print('Background Service Error: $e');
  }
}
