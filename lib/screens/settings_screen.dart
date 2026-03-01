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

  @override
  void initState() {
    super.initState();
    _selectedAreas = List.from(widget.selectedAreas);
    _selectedRingtone = widget.selectedRingtone;
    _customRingtonePath = widget.customRingtonePath;
  }

  void _saveAndClose() {
    widget.onAreasChanged(_selectedAreas);
    widget.onRingtoneChanged(_selectedRingtone, _customRingtonePath);
    Navigator.pop(context);
  }

  Future<void> _pickRingtone() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _customRingtonePath = result!.files.first.path;
        _selectedRingtone = 'custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הגדרות'),
        actions: [
          TextButton(
            onPressed: _saveAndClose,
            child: const Text('שמור', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'בחר אזורים לסינון:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...widget.availableAreas.map((area) => CheckboxListTile(
            title: Text(area),
            value: _selectedAreas.contains(area),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedAreas.add(area);
                } else {
                  _selectedAreas.remove(area);
                }
              });
            },
          )),
          
          const Divider(),
          
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'בחר צלצול:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          RadioListTile<String>(
            title: const Text('ברירת מחדל'),
            subtitle: const Text('צלצול המערכת'),
            value: 'default',
            groupValue: _selectedRingtone,
            onChanged: (value) {
              setState(() {
                _selectedRingtone = value!;
                _customRingtonePath = null;
              });
            },
          ),
          
          RadioListTile<String>(
            title: const Text('ללא צליל'),
            subtitle: const Text('רק רטט'),
            value: 'none',
            groupValue: _selectedRingtone,
            onChanged: (value) {
              setState(() {
                _selectedRingtone = value!;
                _customRingtonePath = null;
              });
            },
          ),
          
          ListTile(
            title: const Text('בחר מהמכשיר'),
            subtitle: Text(
              _customRingtonePath != null 
                  ? _customRingtonePath!.split('/').last 
                  : 'לחץ לבחור קובץ צליל'
            ),
            trailing: const Icon(Icons.folder_open),
            onTap: _pickRingtone,
          ),
          
          if (_customRingtonePath != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _customRingtonePath!.split('/').last,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('אודות'),
            subtitle: const Text('גרסה 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Red Alert',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Baki Labs',
              );
            },
          ),
        ],
      ),
    );
  }
}
