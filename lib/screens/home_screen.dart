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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  OrefService? _orefService;
  StreamSubscription? _alertSubscription;
  bool _isMonitoring = false;
  OrefAlert? _currentAlert;
  List<String> _selectedAreas = [];
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _selectedRingtone = 'default';
  String? _customRingtonePath;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Red alert colors
  static const Color _alertRed = Color(0xFFE53935);
  static const Color _alertRedDark = Color(0xFFB71C1C);
  static const Color _safeGreen = Color(0xFF43A047);
  static const Color _safeGreenDark = Color(0xFF1B5E20);

  final List<String> _availableAreas = [
    // Tel Aviv District
    'תל אביב - מרכז',
    'תל אביב - יפו',
    'תל אביב - מזרח',
    'תל אביב - מערב',
    'תל אביב - צפון',
    'תל אביב - דרום',
    'רמת גן',
    'גבעתיים',
    'חולון',
    'בת ים',
    'ראשון לציון',
    'בני ברק',
    'גבעת שמואל',
    'קרית אונו',
    'אור יהודה',
    'יהוד-מונסון',
    'רמת השרון',
    'הרצליה',
    'פתח תקווה',
    'רמלה',
    'לוד',
    'רחובות',
    'נהריה',
    // Central District
    'נתניה',
    'כפר סבא',
    'הוד השרון',
    'רעננה',
    'יבנה',
    'גדרה',
    'מודיעין',
    'אלעד',
    'בית שמש',
    'יבנה',
    'צריפין',
    'שוהם',
    'גני תקווה',
    'טייבה',
    'טירה',
    'כפר קרע',
    'קדימה צורן',
    'כוכב יאיר',
    'יד בנימין',
    'גן שורק',
    'באר טוביה',
    'גבעת ברנר',
    'רנן',
    'כפר ביל"ו',
    'געש',
    'אבן יהודה',
    'כפר יונה',
    'כפר ברא',
    'רמת יוחנן',
    'חרוצים',
    'גבעת זאב',
    'מזכיר',
    'נחליאל',
    'צרעה',
    'גזר',
    'גת',
    // Jerusalem District
    'ירושלים - מרכז',
    'ירושלים - מערב',
    'ירושלים - מזרח',
    'ירושלים - דרום',
    'ירושלים - צפון',
    'מבשרת ציון',
    'ביתר עילית',
    'גבעת זאב',
    'רמות',
    'רמת זאב',
    'פסיפלורה',
    'הר ברכה',
    'אפרת',
    'עמנואל',
    'קרית ארבע',
    'שערי תקווה',
    'כרמי גן',
    'מעלה אדומים',
    // Haifa District
    'חיפה - כרמל, הדר ועיר תחתית',
    'חיפה - מערב',
    'חיפה - מפרץ',
    'חיפה - נווה שאנן ורמות כרמל',
    'חיפה - קריית חיים ושמואל',
    'קריית ביאליק',
    'קריית מוצקין',
    'קריית ים',
    'קריית אתא',
    'קריית בת ים',
    'נהריה',
    'עכו',
    'טבריה',
    'צפת',
    'כרמיאל',
    'עפולה',
    'מגדל העמק',
    'חדרה',
    'זכרון יעקב',
    'בנימינה',
    'פרדס חנה-כרכור',
    'מעגן מיכאל',
    'בית שאן',
    'מעלות-תרשיחא',
    'רכסים',
    'טירת הכרמל',
    'יקנעם',
    'עתלית',
    'נשר',
    'קריות',
    // Northern District
    'צפת',
    'טבריה',
    'כרמיאל',
    'עפולה',
    'מגדל העמק',
    'נהריה',
    'עכו',
    'חדרה',
    'נצרת',
    'שפרעם',
    'סכנין',
    'כפר מנדא',
    'עראבה',
    'טמרה',
    "ג'סר א-זרקא",
    'כפר יסיף',
    "ג'ת",
    'באקה אל-גרבייה',
    "ג'יברין",
    'ראש פינה',
    'מגדל',
    'לב הגליל',
    'שלומי',
    'מטולה',
    'ראש הנקרה',
    'שעב',
    'ביר אל-מכסור',
    "דאהר אל-מג'דלגה",
    'טורעאן',
    'ריינה',
    'יפעת',
    'כפר בתיה',
    'מגדלים',
    'גבים',
    'עספיא',
    'דיור',
    'כרכור',
    'מלאכי',
    'שחר',
    'צור הדסה',
    'אלפי מנשה',
    'גבעת אבני',
    'חולתה',
    'דליה',
    'רמת צבי',
    'ניצן',
    'גאולה',
    'חיננית',
    'רמות מנשה',
    'שדה יעקב',
    'בית סוסין',
    'גבעת חיים',
    'אליקים',
    'מרחביה',
    'יפית',
    'עין החורש',
    'כפר חנניה',
    'כפר גליקסון',
    'שדה אליהו',
    'רועי',
    'גבעות',
    'מצפה',
    'חופית',
    'גזית',
    'נאות פרי',
    'כפר מיסר',
    'אזור',
    'יגל',
    'בית ברל',
    'כפר שמריהו',
    'שדה בוקר',
    'רמת הכובש',
    'משמר השרון',
    'כפר סירקין',
    'גבעת כ"ם',
    'בית דגן',
    'שדמה',
    'עומר',
    'שורש',
    'צלפון',
    'נחשון',
    'גמזו',
    'בית חשמונאי',
    'בית עובד',
    'ניר צבי',
    'גילת',
    'תל מונד',
    'אביחיל',
    'בית יצחק',
    'בחפץ',
    'חרמש',
    'גתית',
    'מגשימים',
    // Southern District
    'באר שבע - מרכז',
    'באר שבע - דרום',
    'באר שבע - מזרח',
    'באר שבע - מערב',
    'באר שבע - צפון',
    'אשדוד',
    'אשקלון',
    'שדרות',
    'נתיבות',
    'אופקים',
    'דימונה',
    'ערד',
    'ירוחם',
    'מיתרים',
    'אילת',
    'רהט',
    'קרית גת',
    'קרית מלאכי',
    'להבים',
    'חורה',
    'תלמים',
    'בית הלוי',
    'שקמה',
    'חלוץ',
    'מיתר',
    'כרמיה',
    'לכיש',
    'רתמים',
    'ניר ישראל',
    'שדה דוד',
    'נחל עוז',
    'מגן',
    'ארז',
    'גבולות',
    'ניצנים',
    'שלומי',
    'באר גנים',
    'גילו',
    'שדה יואב',
    'יד מרדכי',
    // Gaza Envelope
    'עוטף עזה',
    'שדרות',
    'ניר עם',
    'כיסופים',
    'בארי',
    'מטווח ניר עם',
    'גבים, מכללת ספיר',
    'נחל עוז',
    'בת שלמה',
    'שער הנגב',
    'נתיבות',
    'קרית גת',
    'אופקים',
    'שדה משה',
    'ירוחם',
    'להבים',
    'חורה',
    'תלמים',
    'בית הלוי',
    'שקמה',
    'חלוץ',
    'מיתר',
    'כרמיה',
    'גבים',
    'רנן',
    'גבעת ברנר',
    'מזכיר',
    'נחליאל',
    // West Bank
    'אריאל',
    'בית אל',
    'שכם',
    'רמאללה',
    'בית לחם',
    'חברון',
    'קלקיליה',
    'טול כרם',
    "ג'נין",
    'אל פול',
    'עמי',
    'כפר תפוח',
    'רחלים',
    'שילה',
    'קדומים',
    'עפרה',
    'אלקנה',
    'צור הדסה',
    'גבעת הרא"ה',
    'מעלה אדומים',
    'נריה',
    'טנא',
    'שועלים',
    'כפר אדומים',
    'מצפה יריחו',
    'פלמחים',
    'ראש זוהר',
    'גבעת חיים מאוחד',
    'ראש העין',
    'קרית אליפלט',
    'צור יגאל',
    'גבעת שפירא',
    'כפר קאסם',
    'חורפיש',
    'גילגיל',
    'שורשים',
    'כפר גלים',
    'חיבת ציון',
  ];

  @override
  void initState() {
    super.initState();
    
    // Setup pulse animation for alerts
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
      _pulseController.repeat(reverse: true);
      _playAlertSound();
    });
  }

  void _stopMonitoring() {
    _orefService?.stopPolling();
    _alertSubscription?.cancel();
    _pulseController.stop();
    _pulseController.reset();
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
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _currentAlert = null;
    });
  }

  @override
  void dispose() {
    _stopMonitoring();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAlert = _currentAlert != null;
    final Color primaryColor = hasAlert ? _alertRed : (_isMonitoring ? _safeGreen : Colors.grey.shade700);
    final Color gradientEnd = hasAlert ? _alertRedDark : (_isMonitoring ? _safeGreenDark : Colors.grey.shade900);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('רד אלרט'),
          ],
        ),
        backgroundColor: primaryColor.withOpacity(0.95),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: const Icon(Icons.settings, size: 26),
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
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              gradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),
              
              // Main status icon with animation
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: hasAlert ? _pulseAnimation.value : 1.0,
                    child: child,
                  );
                },
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: hasAlert
                        ? [
                            BoxShadow(
                              color: _alertRed.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    hasAlert
                        ? Icons.warning_rounded
                        : (_isMonitoring ? Icons.visibility : Icons.visibility_off),
                    size: 90,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Status text
              Text(
                hasAlert 
                    ? 'התראה!' 
                    : (_isMonitoring ? 'פעיל - אין התראות' : 'לא פעיל'),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Alert details
              if (hasAlert) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _currentAlert!.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentAlert!.data.join(' | '),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Stop button
                ElevatedButton.icon(
                  onPressed: _stopAlertSound,
                  icon: const Icon(Icons.stop_circle, size: 28),
                  label: const Text('עצור התראה'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _alertRed,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
              
              const Spacer(flex: 1),
              
              // Selected areas display
              if (_selectedAreas.isNotEmpty && !hasAlert)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedAreas.join(' • '),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Start/Stop button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isMonitoring ? Icons.stop : Icons.play_arrow,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isMonitoring ? 'עצור מעקהתחלב' : ' מעקב',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
