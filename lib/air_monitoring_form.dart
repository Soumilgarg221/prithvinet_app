import 'package:flutter/material.dart';

import 'aqi_calculator.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'form_widgets.dart';
import 'location_service.dart';
import 'reading_models.dart';
import 'theme.dart';

class AirMonitoringForm extends StatefulWidget {
  const AirMonitoringForm({super.key});

  @override
  State<AirMonitoringForm> createState() => _AirMonitoringFormState();
}

class _AirMonitoringFormState extends State<AirMonitoringForm> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _locationService = LocationService();

  UserModel? _user;
  List<Map<String, dynamic>> _industries = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _teamMembers = [];

  // Report Info
  String _monitoringType = 'Package Monitoring (Stack + Ambient)';
  String? _selectedIndustryId;
  String? _selectedIndustryName;
  String? _selectedLocationId;
  String? _selectedLocationName;
  DateTime _monitoringDateTime = DateTime.now();
  DateTime? _analysisDateTime;
  String? _selectedMemberId;
  String? _selectedMemberName;
  double? _lat;
  double? _lng;
  bool _gpsLoading = false;

  // Stack rows
  List<StackEmissionRow> _stackRows = [StackEmissionRow()];

  // Ambient air controllers
  final _pm10Ctrl = TextEditingController();
  final _pm25Ctrl = TextEditingController();
  final _so2Ctrl = TextEditingController();
  final _no2Ctrl = TextEditingController();
  final _o3Ctrl = TextEditingController();
  final _co8hrCtrl = TextEditingController();
  final _nh3Ctrl = TextEditingController();
  final _pbCtrl = TextEditingController();

  double? _computedAqi;
  String? _aqiCategory;
  bool _submitting = false;

  bool get _showStack =>
      _monitoringType == 'Package Monitoring (Stack + Ambient)' ||
      _monitoringType == 'Stack Emission Only';
  bool get _showAmbient =>
      _monitoringType == 'Package Monitoring (Stack + Ambient)' ||
      _monitoringType == 'Ambient Air Only';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _addAmbientListeners();
  }

  void _addAmbientListeners() {
    for (final ctrl in [_pm10Ctrl, _pm25Ctrl, _so2Ctrl, _no2Ctrl]) {
      ctrl.addListener(_recalcAqi);
    }
  }

  void _recalcAqi() {
    final result = AqiCalculator.calculate(
      pm10: double.tryParse(_pm10Ctrl.text),
      pm25: double.tryParse(_pm25Ctrl.text),
      so2: double.tryParse(_so2Ctrl.text),
      no2: double.tryParse(_no2Ctrl.text),
    );
    setState(() {
      _computedAqi = result['aqi'];
      _aqiCategory = result['category'];
    });
  }

  Future<void> _loadInitialData() async {
    _user = await _authService.getCurrentUserModel();
    print("USER ROID = ${_user?.roId}");
    if (_user == null) return;

    final industries = await _firestoreService.getIndustries();
    final locations = await _firestoreService.getLocations();
    final members = await _firestoreService.getTeamMembers();

    if (mounted) {
      setState(() {
        _industries = industries;
        _locations = locations;
        _teamMembers = members;
      });
    }
  }

  Future<void> _captureGps() async {
    setState(() => _gpsLoading = true);
    final position = await _locationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _lat = position?.latitude;
        _lng = position?.longitude;
        _gpsLoading = false;
      });
    }
  }

  Future<void> _pickDateTime({required bool isMonitoring}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isMonitoring) {
        _monitoringDateTime = dt;
      } else {
        _analysisDateTime = dt;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_user == null) return;
    setState(() => _submitting = true);

    try {
      final reading = AirReading(
        roId: _user!.roId ?? '',
        roName: _user!.roName ?? '',
        monitoringType: _monitoringType,
        industryId: _selectedIndustryId,
        industryName: _selectedIndustryName,
        locationId: _selectedLocationId ?? '',
        locationName: _selectedLocationName ?? '',
        monitoringDateTime: _monitoringDateTime,
        analysisDateTime: _analysisDateTime,
        submittedBy: _user!.uid,
        submittedByName: _selectedMemberName ?? _user!.name,
        lat: _lat,
        lng: _lng,
        stackRows: _showStack ? _stackRows : [],
        pm10: double.tryParse(_pm10Ctrl.text),
        pm25: double.tryParse(_pm25Ctrl.text),
        so2: double.tryParse(_so2Ctrl.text),
        no2: double.tryParse(_no2Ctrl.text),
        o3: double.tryParse(_o3Ctrl.text),
        co8hr: double.tryParse(_co8hrCtrl.text),
        nh3: double.tryParse(_nh3Ctrl.text),
        pb: double.tryParse(_pbCtrl.text),
        aqi: _computedAqi,
        aqiCategory: _aqiCategory,
      );

      await _firestoreService.submitAirReading(reading);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Air report submitted successfully'),
              ],
            ),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pm10Ctrl.dispose();
    _pm25Ctrl.dispose();
    _so2Ctrl.dispose();
    _no2Ctrl.dispose();
    _o3Ctrl.dispose();
    _co8hrCtrl.dispose();
    _nh3Ctrl.dispose();
    _pbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Air Monitoring Report'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: const Text(
              'Submit new air quality / stack emission report',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Report Information ─────────────────────────────────────────
              FormCard(
                title: 'Report Information',
                children: [
                  LabeledDropdown<String>(
                    label: 'Monitoring Type',
                    required: true,
                    value: _monitoringType,
                    onChanged: (v) => setState(() => _monitoringType = v!),
                    items: const [
                      DropdownMenuItem(
                        value: 'Package Monitoring (Stack + Ambient)',
                        child: Text('Package Monitoring (Stack + Ambient)'),
                      ),
                      DropdownMenuItem(
                        value: 'Stack Emission Only',
                        child: Text('Stack Emission Only'),
                      ),
                      DropdownMenuItem(
                        value: 'Ambient Air Only',
                        child: Text('Ambient Air Only'),
                      ),
                    ],
                  ),
                  LabeledDropdown<String>(
                    label: 'Industry / Station',
                    required: true,
                    hint: '-- Select Industry --',
                    value: _selectedIndustryId,
                    onChanged: (v) {
                      final ind = _industries.firstWhere((i) => i['id'] == v);
                      setState(() {
                        _selectedIndustryId = v;
                        _selectedIndustryName = ind['name'];
                      });
                    },
                    items: _industries
                        .map((i) => DropdownMenuItem(
                            value: i['id'] as String,
                            child: Text(i['name'] as String)))
                        .toList(),
                  ),
                  LabeledDropdown<String>(
                    label: 'Location',
                    required: true,
                    hint: '-- Select Location --',
                    value: _selectedLocationId,
                    onChanged: (v) {
                      final loc = _locations.firstWhere((l) => l['id'] == v);
                      setState(() {
                        _selectedLocationId = v;
                        _selectedLocationName = loc['name'];
                      });
                    },
                    items: _locations
                        .map((l) => DropdownMenuItem(
                            value: l['id'] as String,
                            child: Text(l['name'] as String)))
                        .toList(),
                  ),

                  // Date & Time of Monitoring
                  const _FieldLabel(
                      label: 'Date & Time of Monitoring', required: true),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _pickDateTime(isMonitoring: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            _formatDateTime(_monitoringDateTime),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Date & Time of Analysis
                  const _FieldLabel(
                      label: 'Date & Time of Analysis', required: false),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _pickDateTime(isMonitoring: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.science_outlined,
                              size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            _analysisDateTime != null
                                ? _formatDateTime(_analysisDateTime!)
                                : 'dd-mm-yyyy --:--',
                            style: TextStyle(
                              fontSize: 14,
                              color: _analysisDateTime != null
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  LabeledDropdown<String>(
                    label: 'Monitored By',
                    hint: '-- Select Team Member --',
                    value: _selectedMemberId,
                    onChanged: (v) {
                      final m = _teamMembers.firstWhere((t) => t['id'] == v);
                      setState(() {
                        _selectedMemberId = v;
                        _selectedMemberName = m['name'];
                      });
                    },
                    items: _teamMembers
                        .map((m) => DropdownMenuItem(
                            value: m['id'] as String,
                            child: Text(m['name'] as String)))
                        .toList(),
                  ),

                  // GPS
                  const _FieldLabel(label: 'GPS Coordinates', required: false),
                  const SizedBox(height: 6),
                  GpsLocationTile(
                    lat: _lat,
                    lng: _lng,
                    onTap: _captureGps,
                    isLoading: _gpsLoading,
                  ),
                ],
              ),

              // ── Stack Emission Monitoring ──────────────────────────────────
              if (_showStack)
                FormCard(
                  title: 'Stack Emission Monitoring',
                  headerTrailing: TextButton.icon(
                    onPressed: () =>
                        setState(() => _stackRows.add(StackEmissionRow())),
                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                    label: const Text(
                      'Add Row',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text('Stack / Source',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary))),
                          Expanded(
                              flex: 2,
                              child: Text('Unit',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary))),
                          Expanded(
                              flex: 2,
                              child: Text('PM Value',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary))),
                          Expanded(
                              flex: 2,
                              child: Text('Remark',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary))),
                          SizedBox(width: 32),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._stackRows.asMap().entries.map((entry) =>
                        _StackRowWidget(
                          row: entry.value,
                          onRemove: _stackRows.length > 1
                              ? () =>
                                  setState(() => _stackRows.removeAt(entry.key))
                              : null,
                        )),
                  ],
                ),

              // ── Ambient Air Quality Monitoring ────────────────────────────
              if (_showAmbient)
                FormCard(
                  title: 'Ambient Air Quality Monitoring',
                  children: [
                    // AQI preview
                    if (_computedAqi != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _aqiColor(_aqiCategory).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _aqiColor(_aqiCategory).withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.air, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Computed AQI: ${_computedAqi!.round()} — ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              _aqiCategory ?? '',
                              style: TextStyle(
                                color: _aqiColor(_aqiCategory),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: ParameterInput(
                            label: 'PM10',
                            unit: 'µg/m³',
                            limit: 100,
                            controller: _pm10Ctrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ParameterInput(
                            label: 'PM2.5',
                            unit: 'µg/m³',
                            limit: 60,
                            controller: _pm25Ctrl,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ParameterInput(
                            label: 'SO₂',
                            unit: 'µg/m³',
                            limit: 80,
                            controller: _so2Ctrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ParameterInput(
                            label: 'NO₂',
                            unit: 'µg/m³',
                            limit: 80,
                            controller: _no2Ctrl,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ParameterInput(
                            label: 'O₃',
                            unit: 'µg/m³',
                            limit: 100,
                            controller: _o3Ctrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ParameterInput(
                            label: 'CO (8hr)',
                            unit: 'mg/m³',
                            limit: 10,
                            controller: _co8hrCtrl,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ParameterInput(
                            label: 'NH₃',
                            unit: 'µg/m³',
                            limit: 400,
                            controller: _nh3Ctrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ParameterInput(
                            label: 'Pb (Lead)',
                            unit: 'µg/m³',
                            limit: 1,
                            controller: _pbCtrl,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              // ── Action Buttons ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(_submitting ? 'Saving...' : 'Save Report'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Color _aqiColor(String? category) {
    switch (category) {
      case 'Good':
        return AppTheme.aqiGood;
      case 'Satisfactory':
        return AppTheme.aqiSatisfactory;
      case 'Moderate':
        return AppTheme.aqiModerate;
      case 'Poor':
        return AppTheme.aqiPoor;
      case 'Very Poor':
        return AppTheme.aqiVeryPoor;
      case 'Severe':
        return AppTheme.aqiSevere;
      default:
        return AppTheme.textSecondary;
    }
  }
}

// ── Stack Row Widget ──────────────────────────────────────────────────────────
class _StackRowWidget extends StatefulWidget {
  final StackEmissionRow row;
  final VoidCallback? onRemove;

  const _StackRowWidget({required this.row, this.onRemove});

  @override
  State<_StackRowWidget> createState() => _StackRowWidgetState();
}

class _StackRowWidgetState extends State<_StackRowWidget> {
  late final TextEditingController _sourceCtrl;
  late final TextEditingController _pmCtrl;
  late final TextEditingController _remarkCtrl;

  @override
  void initState() {
    super.initState();
    _sourceCtrl = TextEditingController(text: widget.row.stackSource);
    _pmCtrl = TextEditingController(
        text: widget.row.particulateMatter?.toString() ?? '');
    _remarkCtrl = TextEditingController(text: widget.row.remark);
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _pmCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
  children: [

    Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _sourceCtrl,
            onChanged: (v) => widget.row.stackSource = v,
            decoration: const InputDecoration(
              labelText: 'Stack / Source',
            ),
          ),
        ),
        IconButton(
          onPressed: widget.onRemove,
          icon: Icon(
            Icons.remove_circle_outline,
            color: widget.onRemove != null
                ? AppTheme.errorColor
                : AppTheme.borderColor,
          ),
        ),
      ],
    ),

    const SizedBox(height: 8),

    Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: widget.row.unit,
            onChanged: (v) => setState(() => widget.row.unit = v!),
            items: const [
              DropdownMenuItem(value: 'mg/Nm³', child: Text('mg/Nm³')),
              DropdownMenuItem(value: 'µg/m³', child: Text('µg/m³')),
              DropdownMenuItem(value: 'mg/m³', child: Text('mg/m³')),
            ],
            decoration: const InputDecoration(
              labelText: "Unit",
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _pmCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) =>
                widget.row.particulateMatter = double.tryParse(v),
            decoration: const InputDecoration(
              labelText: 'PM Value',
            ),
          ),
        ),
      ],
    ),

    const SizedBox(height: 8),

    TextFormField(
      controller: _remarkCtrl,
      onChanged: (v) => widget.row.remark = v,
      decoration: const InputDecoration(
        labelText: 'Remark',
      ),
    ),

  ],
),
    );
  }
}

// Private helper
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary),
        children: required
            ? [
                const TextSpan(
                    text: ' *', style: TextStyle(color: AppTheme.errorColor))
              ]
            : [],
      ),
    );
  }
}
