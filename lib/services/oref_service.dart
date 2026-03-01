import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OrefAlert {
  final String? id;
  final String title;
  final List<String> data;
  final String desc;
  final int timestamp;
  final int? timeToRun;

  OrefAlert({
    this.id,
    required this.title,
    required this.data,
    required this.desc,
    required this.timestamp,
    this.timeToRun,
  });

  factory OrefAlert.fromJson(Map<String, dynamic> json) {
    return OrefAlert(
      id: json['id'],
      title: json['title'] ?? '',
      data: List<String>.from(json['data'] ?? []),
      desc: json['desc'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      timeToRun: json['time_to_run'],
    );
  }

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}

class OrefService {
  static const String _baseUrl = 'https://www.oref.org.il';
  static const String _alertsEndpoint = '/WarningMessages/alerts.json';
  static const String _historyEndpoint = '/warningMessages/alert/History/AlertsHistory.json';

  final List<String> selectedAreas;
  Timer? _pollingTimer;
  Timer? _historyPollingTimer;
  final StreamController<OrefAlert> _alertController =
      StreamController<OrefAlert>.broadcast();
  final StreamController<List<OrefAlert>> _historyController =
      StreamController<List<OrefAlert>>.broadcast();

  Stream<OrefAlert> get alertStream => _alertController.stream;
  Stream<List<OrefAlert>> get historyStream => _historyController.stream;
  OrefAlert? _lastAlert;

  OrefService({this.selectedAreas = const []});

  /// Fetches alert history from the last 24 hours
  Future<List<OrefAlert>> fetchAlertHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_historyEndpoint'),
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': 'https://www.oref.org.il/heb/alerts-history',
          'accept': 'application/json, text/plain, */*',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data is List) {
          return data.map((item) => OrefAlert.fromJson(item)).toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort newest first
        }
      }
    } catch (e) {
      // Silently handle errors
    }
    return [];
  }

  Future<OrefAlert?> fetchAlerts() async {
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
          final alert = OrefAlert.fromJson(data);
          
          if (_lastAlert == null || _lastAlert!.timestamp != alert.timestamp) {
            _lastAlert = alert;
            
            if (selectedAreas.isEmpty || 
                alert.data.any((area) => selectedAreas.contains(area))) {
              return alert;
            }
          }
        }
      }
    } catch (e) {
      // Silently handle errors
    }
    return null;
  }

  void startPolling({int intervalSeconds = 5}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) async {
        final alert = await fetchAlerts();
        if (alert != null) {
          _alertController.add(alert);
        }
      },
    );
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    stopHistoryPolling();
  }

  /// Start polling for history every 30 seconds
  void startHistoryPolling({int intervalSeconds = 30}) {
    _historyPollingTimer?.cancel();
    _historyPollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) async {
        final history = await fetchAlertHistory();
        if (history.isNotEmpty) {
          _historyController.add(history);
        }
      },
    );
    // Fetch immediately
    fetchAlertHistory().then((history) {
      if (history.isNotEmpty) {
        _historyController.add(history);
      }
    });
  }

  void stopHistoryPolling() {
    _historyPollingTimer?.cancel();
    _historyPollingTimer = null;
  }

  void dispose() {
    stopPolling();
    _alertController.close();
    _historyController.close();
  }
}
