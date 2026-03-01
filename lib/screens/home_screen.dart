import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/oref_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OrefService? _orefService;
  StreamSubscription? _alertSubscription;
  bool _isMonitoring = false;
  OrefAlert? _currentAlert;
  List<String> _selectedAreas = [];
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _selectedRingtone = 'default';
  String? _customRingtonePath;

  final List<String> _availableAreas = [
    'תל אביב - מרכז',
    'תל אביב - יפו',
    'רמת גן',
    'גבעתיים',
    'חולון',
    'בת ים',
    'ראשון לציון',
    'נתניה',
    'חיפה',
    'ירושלים',
    'באר שבע',
    'אשדוד',
    'אשקלון',
    'שדרות',
    'עוטף עזה',
  ];

  @override
  void initState() {
    super.initState();
  }

  void _startMonitoring() {
    setState(() {
      _isMonitoring = true;
      _currentAlert = null;
    });

    _orefService = OrefService(selectedAreas: _selectedAreas);
    _orefService!.startPolling(intervalSeconds: 3);

    _alertSubscription = _orefService!.alertStream.listen((alert) {
      setState(() {
        _currentAlert = alert;
      });
      _playAlertSound();
    });
  }

  void _stopMonitoring() {
    _orefService?.stopPolling();
    _alertSubscription?.cancel();
    setState(() {
      _isMonitoring = false;
      _currentAlert = null;
    });
  }

  Future<void> _playAlertSound() async {
    try {
      if (_selectedRingtone == 'none') {
        for (int i = 0; i < 3; i++) {
          HapticFeedback.vibrate();
          await Future.delayed(const Duration(milliseconds: 500));
        }
        return;
      }
      
      if (_selectedRingtone == 'default') {
        await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
      } else if (_selectedRingtone == 'custom' && _customRingtonePath != null) {
        await _audioPlayer.play(DeviceFileSource(_customRingtonePath!));
      }
      
      for (int i = 0; i < 3; i++) {
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      for (int i = 0; i < 3; i++) {
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  void _stopAlertSound() {
    _audioPlayer.stop();
  }

  @override
  void dispose() {
    _stopMonitoring();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Red Alert'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen(
                  selectedAreas: _selectedAreas,
                  availableAreas: _availableAreas,
                  selectedRingtone: _selectedRingtone,
                  customRingtonePath: _customRingtonePath,
                  onAreasChanged: (areas) => setState(() => _selectedAreas = areas),
                  onRingtoneChanged: (tone, customPath) {
                    setState(() {
                      _selectedRingtone = tone;
                      _customRingtonePath = customPath;
                    });
                  },
                )),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _currentAlert != null
                ? [Colors.red.shade400, Colors.red.shade900]
                : [Colors.green.shade400, Colors.green.shade900],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _currentAlert != null
                    ? Icons.warning_rounded
                    : Icons.shield,
                size: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                _currentAlert != null ? 'התראה!' : _isMonitoring ? 'ללא התראות' : 'לא פעיל',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              if (_currentAlert != null) ...[
                Text(
                  _currentAlert!.title,
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(
                  _currentAlert!.data.join(', '),
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _stopAlertSound,
                  icon: const Icon(Icons.stop),
                  label: const Text('עצור צליל'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 30),
              if (_selectedAreas.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'אזורים: ${_selectedAreas.join(", ")}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _isMonitoring ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  _isMonitoring ? 'עצור' : 'התחל',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
