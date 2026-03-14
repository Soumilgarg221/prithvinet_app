import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'firestore_service.dart';
import 'form_widgets.dart';
import 'reading_models.dart';
import 'theme.dart';
import 'location_service.dart';

class WaterMonitoringForm extends StatefulWidget {
  final String waterType; // 'natural' or 'waste'

  const WaterMonitoringForm({super.key, required this.waterType});

  @override
  State<WaterMonitoringForm> createState() => _WaterMonitoringFormState();
}

class _WaterMonitoringFormState extends State<WaterMonitoringForm> {
  final _formKey = GlobalKey<FormState>();
  final _fs = FirestoreService();
  final _auth = AuthService();
  final _locationService = LocationService();

  UserModel? _user;
  List<Map<String, dynamic>> _industries = [];
  List<Map<String, dynamic>> _locations = [];

  String? _selectedIndustryId;
  String? _selectedIndustryName;
  String? _selectedLocationId;
  String? _selectedLocationName;
  DateTime _monitoringDateTime = DateTime.now();
  double? _lat;
  double? _lng;
  bool _gpsLoading = false;

  final _chemistCtrl = TextEditingController();
  final _scientistCtrl = TextEditingController();

  // Up to 4 samples
  List<WaterSample> _samples = [WaterSample(sampleId: 'S-1')];
  bool _submitting = false;

  bool get _isWaste => widget.waterType == 'waste';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _user = await _auth.getCurrentUserModel();
    if (_user == null) return;
    final ind = await _fs.getIndustries(roId: _user!.roId);
    final loc = await _fs.getLocations(roId: _user!.roId);
    if (mounted)
      setState(() {
        _industries = ind;
        _locations = loc;
      });
  }

  Future<void> _captureGps() async {
  setState(() => _gpsLoading = true);

  final pos = await _locationService.getCurrentPosition();

  if (mounted) {
    setState(() {
      _lat = pos?.latitude;
      _lng = pos?.longitude;
      _gpsLoading = false;
    });
  }
}
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
        ),
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
    setState(() => _submitting = true);
    try {
      final reading = WaterReading(
        roId: _user!.roId ?? '',
        roName: _user!.roName ?? '',
        waterType: widget.waterType,
        industryId: _selectedIndustryId,
        industryName: _selectedIndustryName,
        locationId: _selectedLocationId ?? '',
        locationName: _selectedLocationName ?? '',
        monitoringDateTime: _monitoringDateTime,
        submittedBy: _user!.uid,
        submittedByName: _user!.name,
        lat: _lat,
        lng: _lng,
        samples: _samples,
        chemistName: _chemistCtrl.text.isNotEmpty ? _chemistCtrl.text : null,
        scientistName:
            _scientistCtrl.text.isNotEmpty ? _scientistCtrl.text : null,
      );
      await _fs.submitWaterReading(reading);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Water report submitted successfully'),
            backgroundColor: AppTheme.accentColor,
          ),
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
  void dispose() {
    _chemistCtrl.dispose();
    _scientistCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isWaste ? 'Waste Water Report' : 'Natural Water Report'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              _isWaste
                  ? 'Industrial waste water analysis'
                  : 'Natural water body analysis',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
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
              // Report Info
              FormCard(
                title: 'Report Information',
                children: [
                  LabeledDropdown<String>(
                    label: _isWaste ? 'Industry / Station' : 'Water Source',
                    required: true,
                    hint: _isWaste
                        ? '-- Select Industry --'
                        : '-- Select Source --',
                    value: _selectedIndustryId,
                    onChanged: (v) {
final ind = _industries.firstWhere(
  (i) => i['id'] == v,
  orElse: () => {},
);                      setState(() {
                        _selectedIndustryId = v;
                        _selectedIndustryName = ind['name'];
                      });
                    },
                    items: _industries
                        .map((i) => DropdownMenuItem(
                              value: i['id'] as String,
                              child: Text(i['name'] as String),
                            ))
                        .toList(),
                  ),
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
                    onTap: _captureGps,
                    isLoading: _gpsLoading,
                  ),
                ],
              ),

              // Samples
              FormCard(
                title: 'Water Samples (up to 4)',
                headerTrailing: _samples.length < 4
                    ? TextButton.icon(
                        onPressed: () => setState(() {
                          _samples.add(WaterSample(
                            sampleId: 'S-${_samples.length + 1}',
                          ));
                        }),
                        icon: const Icon(Icons.add,
                            color: Colors.white, size: 16),
                        label: const Text('Add Sample',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                      )
                    : null,
                children: [
                  ..._samples.asMap().entries.map((e) => _SampleCard(
                        index: e.key,
                        sample: e.value,
                        isWaste: _isWaste,
                        canRemove: _samples.length > 1,
                        onRemove: () =>
                            setState(() => _samples.removeAt(e.key)),
                      )),
                ],
              ),

              // Signatures (waste water only)
              if (_isWaste)
                FormCard(
                  title: 'Signatories',
                  children: [
                    LabeledTextField(
                      label: 'Chemist Name',
                      controller: _chemistCtrl,
                      hint: 'Name of analysing chemist',
                    ),
                    LabeledTextField(
                      label: 'Scientist / RO Name',
                      controller: _scientistCtrl,
                      hint: 'Name of authorising scientist or RO',
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

// ── Sample Card ───────────────────────────────────────────────────────────────
class _SampleCard extends StatelessWidget {
  final int index;
  final WaterSample sample;
  final bool isWaste;
  final bool canRemove;
  final VoidCallback onRemove;

  const _SampleCard({
    required this.index,
    required this.sample,
    required this.isWaste,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Sample ${index + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppTheme.errorColor, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Sample Location
          _InlineField(
            label: 'Sample Location',
            hint: 'e.g. Upstream / Intake point',
            onChanged: (v) => sample.sampleLocation = v,
          ),
          const SizedBox(height: 10),

          // Basic params
          _ParamRow(children: [
            _InlineNumField(
                label: 'Temperature (°C)',
                hint: '—',
                onChanged: (v) => sample.temperature = v),
            _InlineNumField(
                label: 'pH',
                hint: '—',
                limit: '6.5–8.5',
                onChanged: (v) {
                  sample.ph = v;
                }),
          ]),
          _ParamRow(children: [
            _InlineNumField(
                label: 'Turbidity (NTU)',
                hint: '—',
                onChanged: (v) => sample.turbidity = v),
            _InlineNumField(
                label: 'Conductivity (µS/cm)',
                hint: '—',
                onChanged: (v) => sample.conductivity = v),
          ]),
          _ParamRow(children: [
            _InlineNumField(
                label: 'Total Solids (mg/L)',
                hint: '—',
                onChanged: (v) => sample.totalSolids = v),
            _InlineTextField(
                label: 'Appearance',
                hint: 'e.g. Clear',
                onChanged: (v) => sample.appearance = v),
          ]),

          // Waste water only
          if (isWaste) ...[
            const Divider(height: 20),
            const Text('Industrial Parameters',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor)),
            const SizedBox(height: 8),
            _ParamRow(children: [
              _InlineNumField(
                  label: 'BOD (mg/L)',
                  hint: '—',
                  limit: '30',
                  onChanged: (v) => sample.bod = v),
              _InlineNumField(
                  label: 'COD (mg/L)',
                  hint: '—',
                  limit: '250',
                  onChanged: (v) => sample.cod = v),
            ]),
            _ParamRow(children: [
              _InlineNumField(
                  label: 'Dissolved Solids (mg/L)',
                  hint: '—',
                  onChanged: (v) => sample.dissolvedSolids = v),
              _InlineNumField(
                  label: 'Suspended Solids (mg/L)',
                  hint: '—',
                  limit: '100',
                  onChanged: (v) => sample.suspendedSolids = v),
            ]),
            _ParamRow(children: [
              _InlineNumField(
                  label: 'Oil & Grease (mg/L)',
                  hint: '—',
                  limit: '10',
                  onChanged: (v) => sample.oilGrease = v),
              const Spacer(),
            ]),
          ],
        ],
      ),
    );
  }
}

class _ParamRow extends StatelessWidget {
  final List<Widget> children;
  const _ParamRow({required this.children});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .expand((w) => [Expanded(child: w), const SizedBox(width: 10)])
            .toList()
          ..removeLast(),
      );
}

class _InlineField extends StatelessWidget {
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  const _InlineField(
      {required this.label, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          TextFormField(
            onChanged: onChanged,
            decoration: InputDecoration(
                hintText: hint,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      );
}

class _InlineTextField extends StatelessWidget {
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  const _InlineTextField(
      {required this.label, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          TextFormField(
            onChanged: onChanged,
            decoration: InputDecoration(
                hintText: hint,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      );
}

class _InlineNumField extends StatelessWidget {
  final String label;
  final String hint;
  final String? limit;
  final ValueChanged<double?> onChanged;
  const _InlineNumField(
      {required this.label,
      required this.hint,
      this.limit,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
              if (limit != null) ...[
                const SizedBox(width: 4),
                Text('(Limit: $limit)',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.primaryColor)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            onChanged: (v) => onChanged(double.tryParse(v)),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                hintText: hint,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      );
}
