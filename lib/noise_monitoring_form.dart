import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'firestore_service.dart';
import 'form_widgets.dart';
import 'reading_models.dart';
import 'theme.dart';
import 'location_service.dart';

class NoiseMonitoringForm extends StatefulWidget {
  const NoiseMonitoringForm({super.key});

  @override
  State<NoiseMonitoringForm> createState() => _NoiseMonitoringFormState();
}

class _NoiseMonitoringFormState extends State<NoiseMonitoringForm> {
  final _formKey = GlobalKey<FormState>();
  final _fs = FirestoreService();
  final _auth = AuthService();
  final _locationService = LocationService();

  UserModel? _user;
  List<Map<String, dynamic>> _locations = [];
  String? _selectedLocationId;
  String? _selectedLocationName;
  DateTime _monitoringDateTime = DateTime.now();
  double? _lat;
  double? _lng;
  bool _gpsLoading = false;

  List<NoiseRow> _rows = [NoiseRow()];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _user = await _auth.getCurrentUserModel();
    if (_user == null) return;
    final locs = await _fs.getLocations(roId: _user!.roId);
    if (mounted) setState(() => _locations = locs);
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppTheme.primaryColor)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() {
      _monitoringDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (_user == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a location'),
            backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final reading = NoiseReading(
        roId: _user!.roId ?? '',
        roName: _user!.roName ?? '',
        locationId: _selectedLocationId!,
        locationName: _selectedLocationName!,
        monitoringDateTime: _monitoringDateTime,
        submittedBy: _user!.uid,
        submittedByName: _user!.name,
        lat: _lat,
        lng: _lng,
        rows: _rows,
      );
      await _fs.submitNoiseReading(reading);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Noise report submitted successfully'),
              backgroundColor: AppTheme.accentColor),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noise Monitoring Report'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: const Text('Zone-based noise level monitoring',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Report Info
              FormCard(
                title: 'Report Information',
                children: [
                  LabeledDropdown<String>(
                    label: 'Monitoring Location',
                    required: true,
                    hint: '-- Select Location --',
                    value: _selectedLocationId,
                    onChanged: (v) {
                      final loc = _locations.firstWhere(
  (l) => l['id'] == v,
  orElse: () => {},
);
                      setState(() {
                        _selectedLocationId = v;
                        _selectedLocationName = loc['name'];
                      });
                    },
                    items: _locations
                        .map((l) => DropdownMenuItem(
                              value: l['id'] as String,
                              child: Text(l['name'] as String),
                            ))
                        .toList(),
                  ),
                  const Text('Date & Time of Monitoring *',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickDateTime,
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
                          Text(_formatDt(_monitoringDateTime),
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('GPS Coordinates',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  GpsLocationTile(
  lat: _lat,
  lng: _lng,
  onTap: () async {
    setState(() => _gpsLoading = true);

    final pos = await _locationService.getCurrentPosition();

    if (mounted) {
      setState(() {
        _lat = pos?.latitude;
        _lng = pos?.longitude;
        _gpsLoading = false;
      });
    }
  },
  isLoading: _gpsLoading,
),
                ],
              ),

              // Prescribed Limits Reference
              FormCard(
                title: 'Prescribed Limits Reference',
                children: [
                  _LimitsTable(),
                ],
              ),

              // Noise Readings
              FormCard(
                title: 'Noise Readings',
                headerTrailing: TextButton.icon(
                  onPressed: () => setState(() => _rows.add(NoiseRow())),
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  label: const Text('Add Row',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                children: [
                  ..._rows.asMap().entries.map((e) => _NoiseRowWidget(
                        row: e.value,
                        canRemove: _rows.length > 1,
                        onRemove: () => setState(() => _rows.removeAt(e.key)),
                        onChanged: () => setState(() {}),
                      )),
                  if (_rows.any((r) => r.exceedsLimit))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: ViolationBadge(),
                    ),
                ],
              ),

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
                                  strokeWidth: 2, color: Colors.white))
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
}

// ── Prescribed Limits Table ───────────────────────────────────────────────────
class _LimitsTable extends StatelessWidget {
  const _LimitsTable();

  @override
  Widget build(BuildContext context) {
    final zones = [
      {'zone': 'Silence Zone', 'day': 50, 'night': 40},
      {'zone': 'Residential', 'day': 55, 'night': 45},
      {'zone': 'Commercial', 'day': 65, 'night': 55},
      {'zone': 'Industrial', 'day': 75, 'night': 70},
    ];

    return Table(
      border: TableBorder.all(
          color: AppTheme.borderColor, borderRadius: BorderRadius.circular(6)),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        // Header
        TableRow(
          decoration: const BoxDecoration(color: AppTheme.primaryColor),
          children: const [
            _TCell('Zone', isHeader: true),
            _TCell('Day (dB)', isHeader: true),
            _TCell('Night (dB)', isHeader: true),
          ],
        ),
        ...zones.map((z) => TableRow(
              children: [
                _TCell(z['zone'] as String),
                _TCell('${z['day']}'),
                _TCell('${z['night']}'),
              ],
            )),
      ],
    );
  }
}

class _TCell extends StatelessWidget {
  final String text;
  final bool isHeader;

  const _TCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
          color: isHeader ? Colors.white : AppTheme.textPrimary,
        ),
      ),
    );
  }
}

// ── Noise Row Widget ──────────────────────────────────────────────────────────
class _NoiseRowWidget extends StatefulWidget {
  final NoiseRow row;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _NoiseRowWidget({
    required this.row,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_NoiseRowWidget> createState() => _NoiseRowWidgetState();
}

class _NoiseRowWidgetState extends State<_NoiseRowWidget> {
  late final TextEditingController _locationCtrl;
  late final TextEditingController _levelCtrl;

  @override
  void initState() {
    super.initState();
    _locationCtrl = TextEditingController(text: widget.row.location);
    _levelCtrl =
        TextEditingController(text: widget.row.noiseLevel?.toString() ?? '');
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _levelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.row.exceedsLimit
            ? AppTheme.errorColor.withOpacity(0.05)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.row.exceedsLimit
              ? AppTheme.errorColor.withOpacity(0.4)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _locationCtrl,
                  onChanged: (v) {
                    widget.row.location = v;
                    widget.onChanged();
                  },
                  decoration: const InputDecoration(
                    hintText: 'Location name',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.canRemove)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppTheme.errorColor, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.row.zone,
                  onChanged: (v) => setState(() {
                    widget.row.zone = v!;
                    widget.onChanged();
                  }),
                  items: const [
                    DropdownMenuItem(
                        value: 'Silence', child: Text('Silence Zone')),
                    DropdownMenuItem(
                        value: 'Residential', child: Text('Residential')),
                    DropdownMenuItem(
                        value: 'Commercial', child: Text('Commercial')),
                    DropdownMenuItem(
                        value: 'Industrial', child: Text('Industrial')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Zone',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.row.monitoringTime,
                  onChanged: (v) => setState(() {
                    widget.row.monitoringTime = v!;
                    widget.onChanged();
                  }),
                  items: const [
                    DropdownMenuItem(value: 'Day', child: Text('Day')),
                    DropdownMenuItem(value: 'Night', child: Text('Night')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _levelCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    widget.row.noiseLevel = double.tryParse(v);
                    setState(() {});
                    widget.onChanged();
                  },
                  decoration: InputDecoration(
                    labelText: 'dB(A)',
                    hintText: '—',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    fillColor: widget.row.exceedsLimit
                        ? AppTheme.errorColor.withOpacity(0.05)
                        : Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: widget.row.exceedsLimit
                            ? AppTheme.errorColor
                            : AppTheme.borderColor,
                      ),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          if (widget.row.noiseLevel != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Text(
                    'Limit: ${widget.row.prescribedLimit} dB(A)',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  if (widget.row.exceedsLimit) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.warning_rounded,
                        color: AppTheme.errorColor, size: 14),
                    const Text(
                      ' Exceeds limit',
                      style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
