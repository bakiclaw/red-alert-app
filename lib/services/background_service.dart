import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// OREF Alert data model for background service
class BackgroundOrefAlert {
  final String? id;
  final String title;
  final List<String> data;
  final String desc;
  final int timestamp;
  final int? timeToRun;

  BackgroundOrefAlert({
    this.id,
    required this.title,
    required this.data,
    required this.desc,
    required this.timestamp,
    this.timeToRun,
  });

  factory BackgroundOrefAlert.fromJson(Map<String, dynamic> json) {
    return BackgroundOrefAlert(
      id: json['id'],
      title: json['title'] ?? '',
      data: List<String>.from(json['data'] ?? []),
      desc: json['desc'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      timeToRun: json['time_to_run'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'data': data,
      'desc': desc,
      'timestamp': timestamp,
      'timeToRun': timeToRun,
    };
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}

/// Background service for OREF alerts polling
class OrefBackgroundService {
  static const String _baseUrl = 'https://www.oref.org.il';
  static const String _alertsEndpoint = '/WarningMessages/alerts.json';
  
  // Notification IDs
  static const int _persistentNotificationId = 888;
  static const int _alertNotificationId = 999;

  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Initialize the background service
  static Future<void> initialize() async {
    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels
    await _createNotificationChannels();

    // Request notification permission (Android 13+)
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Configure and start background service
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'red_alert_persistent',
        initialNotificationTitle: 'Red Alert',
        initialNotificationContent: 'Service initializing...',
        foregroundServiceNotificationId: _persistentNotificationId,
        // foregroundServiceTypes - removed location, not needed for network polling
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    // Persistent notification channel (foreground service)
    const persistentChannel = AndroidNotificationChannel(
      'red_alert_persistent',
      'Background Service',
      description: 'Keeps the alert monitoring running in the background',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    // Alert notification channel (high priority)
    const alertChannel = AndroidNotificationChannel(
      'red_alert_alerts',
      'Red Alert Notifications',
      description: 'Notifications when a red alert is triggered',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(persistentChannel);
    await androidPlugin?.createNotificationChannel(alertChannel);
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - can be extended to open specific screen
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Main background service entry point
  @pragma('vm:entry-point')
  static Future<void> _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Timer for periodic polling
    Timer? pollingTimer;
    
    // Store last alert to avoid duplicate notifications
    int? lastAlertTimestamp;
    List<String> selectedAreas = [];

    // Load selected areas from SharedPreferences
    Future<void> loadSelectedAreas() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final areasJson = prefs.getStringList('selected_areas');
        if (areasJson != null) {
          selectedAreas = areasJson.cast<String>();
        }
      } catch (e) {
        // Ignore errors
      }
    }

    /// Show persistent notification
    Future<void> showPersistentNotification() async {
      const androidDetails = AndroidNotificationDetails(
        'red_alert_persistent',
        'Background Service',
        channelDescription: 'Keeps the alert monitoring running',
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(android: androidDetails);
      
      if (selectedAreas.isEmpty) {
        await _notifications.show(
          _persistentNotificationId,
          '🔴 Red Alert',
          'מעקב אחרי כל האזורים פעיל',
          details,
        );
      } else {
        await _notifications.show(
          _persistentNotificationId,
          '🔴 Red Alert',
          'מעקב אחרי ${selectedAreas.length} אזורים פעיל',
          details,
        );
      }
    }

    /// Show alert notification when red alert is triggered
    Future<void> showAlertNotification(BackgroundOrefAlert alert) async {
      const androidDetails = AndroidNotificationDetails(
        'red_alert_alerts',
        'Red Alert Notifications',
        channelDescription: 'Notifications when a red alert is triggered',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );
      const details = NotificationDetails(android: androidDetails);

      final areasText = alert.data.join(', ');
      await _notifications.show(
        _alertNotificationId,
        '⚠️ התראה! ${alert.title}',
        areasText,
        details,
      );
    }

    /// Fetch alerts from OREF API
    Future<BackgroundOrefAlert?> fetchAlerts() async {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl$_alertsEndpoint'),
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': _baseUrl,
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data != null && data['data'] != null && (data['data'] as List).isNotEmpty) {
            return BackgroundOrefAlert.fromJson(data);
          }
        }
      } catch (e) {
        // Silently handle errors
      }
      return null;
    }

    /// Start polling for alerts
    void startPolling() {
      pollingTimer?.cancel();
      pollingTimer = Timer.periodic(
        const Duration(seconds: 5),
        (timer) async {
          // Reload selected areas periodically
          await loadSelectedAreas();
          
          final alert = await fetchAlerts();
          
          if (alert != null) {
            // Check if this is a new alert
            if (lastAlertTimestamp == null || lastAlertTimestamp != alert.timestamp) {
              lastAlertTimestamp = alert.timestamp;
              
              // Check if alert is for selected areas (or no areas selected = all)
              if (selectedAreas.isEmpty || 
                  alert.data.any((area) => selectedAreas.contains(area))) {
                // Show alert notification
                await showAlertNotification(alert);
                
                // Send event to main app
                service.invoke('alert', alert.toJson());
              }
            }
          }
        },
      );
    }

    // Initial setup
    await loadSelectedAreas();
    await showPersistentNotification();
    startPolling();

    // Listen for stop command
    service.on('stop').listen((event) {
      pollingTimer?.cancel();
      service.stopSelf();
    });

    // Listen for update areas command
    service.on('update_areas').listen((event) async {
      if (event != null) {
        // Handle Map type from background service
        final areas = event['areas'];
        if (areas != null && areas is List) {
          selectedAreas = (areas as List).map((e) => e.toString()).toList();
        }
        await showPersistentNotification();
      }
    });

    // Handle service events
    service.on('start').listen((event) {
      startPolling();
    });
  }

  /// Start the background service
  static Future<bool> startService() async {
    try {
      final isRunning = await _service.isRunning();
      if (!isRunning) {
        return await _service.startService();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stop the background service
  static Future<void> stopService() async {
    try {
      final isRunning = await _service.isRunning();
      if (isRunning) {
        _service.invoke('stop');
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Check if service is running
  static Future<bool> isRunning() async {
    try {
      return await _service.isRunning();
    } catch (e) {
      return false;
    }
  }

  /// Update selected areas in background service
  static Future<void> updateSelectedAreas(List<String> areas) async {
    _service.invoke('update_areas', {'areas': areas});
  }

  /// Get the service instance for listening to events
  static Stream<Map<String, dynamic>?> get onAlert {
    return _service.on('alert');
  }
}
