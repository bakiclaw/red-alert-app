import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  final List<String> selectedAreas;
  final List<String> availableAreas;
  final String selectedRingtone;
  final String? customRingtonePath;
  final Function(List<String>) onAreasChanged;
  final Function(String, String?) onRingtoneChanged;

  const SettingsScreen({
    super.key,
    required this.selectedAreas,
    required this.availableAreas,
    required this.selectedRingtone,
    this.customRingtonePath,
    required this.onAreasChanged,
    required this.onRingtoneChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late List<String> _selectedAreas;
  late String _selectedRingtone;
  String? _customRingtonePath;
  bool _selectAll = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Red alert theme colors
  static const Color _alertRed = Color(0xFFE53935);
  static const Color _cardBackground = Color(0xFF2D2D2D);
  static const Color _surfaceColor = Color(0xFF1E1E1E);

  // Filtered areas based on search
  List<String> get _filteredAreas {
    if (_searchQuery.isEmpty) {
      return widget.availableAreas;
    }
    return widget.availableAreas
        .where((area) => area.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedAreas = List.from(widget.selectedAreas);
    _selectedRingtone = widget.selectedRingtone;
    _customRingtonePath = widget.customRingtonePath;
    _selectAll = _selectedAreas.length == widget.availableAreas.length;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _saveAndClose() {
    widget.onAreasChanged(_selectedAreas);
    widget.onRingtoneChanged(_selectedRingtone, _customRingtonePath);
    Navigator.pop(context);
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        // Add all filtered areas to selection
        _selectedAreas = List.from(_filteredAreas);
      } else {
        // Remove filtered areas from selection
        for (var area in _filteredAreas) {
          _selectedAreas.remove(area);
        }
      }
    });
  }

  Future<void> _pickRingtone() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _customRingtonePath = result.files.first.path;
        _selectedRingtone = 'custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הגדרות'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _saveAndClose,
        ),
        actions: [
          TextButton(
            onPressed: _saveAndClose,
            child: const Row(
              children: [
                Text(
                  'שמור',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.check, color: Colors.white, size: 20),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _surfaceColor,
              Color(0xFF121212),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Areas Section
            _buildSectionHeader(
              icon: Icons.location_on,
              title: 'אזורים למעקב',
              subtitle: _selectedAreas.isEmpty 
                  ? 'בחר אזורים לקבלת התראות'
                  : '${_selectedAreas.length} אזורים נבחרו',
            ),
            
            const SizedBox(height: 8),
            
            // Select All toggle
            Card(
              color: _cardBackground,
              child: Column(
                children: [
                  // Search field
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'חפש עיר...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade500),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  // Search results count
                  if (_searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            'נמצאו ${_filteredAreas.length} תוצאות',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'בחר הכל',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _selectAll ? 'לבטל הכל' : 'לבחור את כל האזורים',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                    value: _selectAll,
                    onChanged: _toggleSelectAll,
                    activeColor: _alertRed,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Areas list - lazy loaded with ListView.builder
            Card(
              color: _cardBackground,
              child: SizedBox(
                height: 400, // Show ~20 items
                child: ListView.builder(
                  itemCount: _filteredAreas.length,
                  itemExtent: 52, // Fixed height for performance
                  itemBuilder: (context, index) {
                    final area = _filteredAreas[index];
                    final isSelected = _selectedAreas.contains(area);
                    return CheckboxListTile(
                      title: Text(
                        area,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade400,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedAreas.add(area);
                          } else {
                            _selectedAreas.remove(area);
                          }
                          _selectAll = _selectedAreas.length == widget.availableAreas.length;
                        });
                      },
                      activeColor: _alertRed,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.trailing,
                      dense: true,
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Ringtone Section
            _buildSectionHeader(
              icon: Icons.music_note,
              title: 'צלצול התראה',
              subtitle: _getRingtoneSubtitle(),
            ),
            
            const SizedBox(height: 8),
            
            Card(
              color: _cardBackground,
              child: Column(
                children: [
                  // Default ringtone
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _alertRed.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.notifications_active,
                            color: _alertRed,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('צלצול ברירת מחדל'),
                      ],
                    ),
                    subtitle: const Text(
                      'צלצול המערכת הסטנדרטי',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: 'default',
                    groupValue: _selectedRingtone,
                    onChanged: (value) {
                      setState(() {
                        _selectedRingtone = value!;
                        _customRingtonePath = null;
                      });
                    },
                    activeColor: _alertRed,
                  ),
                  
                  const Divider(height: 1),
                  
                  // Silent mode
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.vibration,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('רק רטט'),
                      ],
                    ),
                    subtitle: const Text(
                      'ללא צליל - רק רטט',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: 'none',
                    groupValue: _selectedRingtone,
                    onChanged: (value) {
                      setState(() {
                        _selectedRingtone = value!;
                        _customRingtonePath = null;
                      });
                    },
                    activeColor: _alertRed,
                  ),
                  
                  const Divider(height: 1),
                  
                  // Custom ringtone
                  ListTile(
                    onTap: _pickRingtone,
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.folder_open,
                            color: Colors.purple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('קובץ מותאם אישית'),
                      ],
                    ),
                    subtitle: Text(
                      _customRingtonePath != null 
                          ? _customRingtonePath!.split('/').last
                          : 'בחר קובץ צליל מהמכשיר',
                      style: TextStyle(
                        fontSize: 12,
                        color: _customRingtonePath != null 
                            ? _alertRed 
                            : Colors.grey.shade400,
                      ),
                    ),
                    trailing: _customRingtonePath != null
                        ? const Icon(Icons.check_circle, color: _alertRed)
                        : const Icon(Icons.chevron_left, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // About Section
            _buildSectionHeader(
              icon: Icons.info_outline,
              title: 'אודות',
              subtitle: 'מידע על האפליקציה',
            ),
            
            const SizedBox(height: 8),
            
            Card(
              color: _cardBackground,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _alertRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: _alertRed,
                      ),
                    ),
                    title: const Text('רד אלרט'),
                    subtitle: const Text('גרסה 1.0.5'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.code,
                        color: Colors.blue,
                      ),
                    ),
                    title: const Text('פותח על ידי'),
                    subtitle: const Text('Baki Labs © 2026'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _alertRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _alertRed, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRingtoneSubtitle() {
    switch (_selectedRingtone) {
      case 'default':
        return 'צלצול ברירת מחדל';
      case 'none':
        return 'רק רטט';
      case 'custom':
        return _customRingtonePath?.split('/').last ?? 'קובץ מותאם אישית';
      default:
        return 'בחר צלצול';
    }
  }
}
