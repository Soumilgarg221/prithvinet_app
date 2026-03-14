import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'firestore_service.dart';
import 'theme.dart';
import 'water_monitoring_form.dart';

class WaterMonitoringList extends StatefulWidget {
  const WaterMonitoringList({super.key});

  @override
  State<WaterMonitoringList> createState() => _WaterMonitoringListState();
}

class _WaterMonitoringListState extends State<WaterMonitoringList>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _fs = FirestoreService();
  UserModel? _user;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _auth.getCurrentUserModel().then((u) => setState(() => _user = u));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showTypeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Report Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _TypeTile(
              icon: Icons.water,
              title: 'Natural Water Analysis',
              subtitle: 'Rivers, lakes, groundwater sampling',
              color: const Color(0xFF27AE60),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const WaterMonitoringForm(waterType: 'natural')));
              },
            ),
            const SizedBox(height: 12),
            _TypeTile(
              icon: Icons.factory,
              title: 'Industrial Waste Water',
              subtitle: 'Effluent treatment plant, discharge points',
              color: const Color(0xFFE67E22),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const WaterMonitoringForm(waterType: 'waste')));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTs(dynamic ts) {
    if (ts == null) return '—';
    final dt = (ts as Timestamp).toDate();
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Monitoring Reports'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Natural Water'),
            Tab(text: 'Waste Water'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTypeSelector,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Report', style: TextStyle(color: Colors.white)),
      ),
      body: _user == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _WaterList(
                    uid: _user!.uid,
                    type: 'natural',
                    fs: _fs,
                    formatTs: _formatTs),
                _WaterList(
                    uid: _user!.uid,
                    type: 'waste',
                    fs: _fs,
                    formatTs: _formatTs),
              ],
            ),
    );
  }
}

class _WaterList extends StatelessWidget {
  final String uid;
  final String type;
  final FirestoreService fs;
  final String Function(dynamic) formatTs;

  const _WaterList({
    required this.uid,
    required this.type,
    required this.fs,
    required this.formatTs,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.getWaterReadings(uid: uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }
        final all = snapshot.data ?? [];
        final readings = all.where((r) => r['waterType'] == type).toList();

        if (readings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop, size: 64, color: AppTheme.borderColor),
                const SizedBox(height: 12),
                Text(
                  'No ${type == 'natural' ? 'natural water' : 'waste water'} reports yet',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 15),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: readings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = readings[i];
            final hasViolation = r['hasViolation'] as bool? ?? false;
            final sampleCount = (r['samples'] as List?)?.length ?? 0;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasViolation
                      ? AppTheme.errorColor.withOpacity(0.4)
                      : AppTheme.borderColor,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.water_drop,
                      color: Color(0xFF27AE60), size: 22),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        r['locationName'] ?? '—',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    if (hasViolation)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Violation',
                            style: TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                        '$sampleCount sample${sampleCount != 1 ? 's' : ''} collected',
                        style: const TextStyle(fontSize: 12)),
                    Text(formatTs(r['monitoringDateTime']),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right,
                    color: AppTheme.textSecondary, size: 18),
              ),
            );
          },
        );
      },
    );
  }
}

class _TypeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TypeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
