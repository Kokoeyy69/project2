import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();

    // Set up Firebase Messaging
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Get FCM token
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    _isInitialized = true;
  }

  static Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to activity screen
    print('Notification tapped: ${response.payload}');
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    if (message.notification != null) {
      showInstantNotification(
        message.notification!.title ?? 'NeoPay',
        message.notification!.body ?? '',
      );
    }
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message: ${message.notification?.title}');
  }

  static Future<void> showInstantNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'neopay_transactions',
      'NeoPay Transactions',
      channelDescription: 'Transaction notifications for NeoPay',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: 'transaction',
    );
  }

  static Future<String?> getFCMToken() async {
    return await _messaging.getToken();
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}

/// Helper to format transaction notification messages
class TransactionNotification {
  static String formatTransferSent(String recipientName, double amount, String currency) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: currency == 'USD' ? '\$' : (currency == 'CNY' ? '¥ ' : 'Rp '), decimalDigits: 0);
    return 'Berhasil! Dana ${formatter.format(amount)} telah terkirim ke $recipientName';
  }

  static String formatTransferReceived(String senderName, double amount, String currency) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: currency == 'USD' ? '\$' : (currency == 'CNY' ? '¥ ' : 'Rp '), decimalDigits: 0);
    return 'Dana masuk! ${formatter.format(amount)} dari $senderName';
  }

  static String formatTopUp(double amount, String currency) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: currency == 'USD' ? '\$' : (currency == 'CNY' ? '¥ ' : 'Rp '), decimalDigits: 0);
    return 'Top up berhasil! Saldo bertambah ${formatter.format(amount)}';
  }
}