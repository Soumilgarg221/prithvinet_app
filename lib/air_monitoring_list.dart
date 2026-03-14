import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'air_monitoring_form.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'theme.dart';

class AirMonitoringList extends StatefulWidget {
  const AirMonitoringList({super.key});

  @override
  State<AirMonitoringList> createState() => _AirMonitoringListState();
}

class _AirMonitoringListState extends State<AirMonitoringList> {
  final _auth = AuthService();
  final _fs = FirestoreService();
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _auth.getCurrentUserModel().then((u) => setState(() => _user = u));
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

  String _formatTs(dynamic ts) {
    if (ts == null) return '—';
    final dt = (ts as Timestamp).toDate();
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Air Monitoring Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AirMonitoringForm()),
        ),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Report', style: TextStyle(color: Colors.white)),
      ),
      body: _user == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fs.getAirReadings(uid: _user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor));
                }
                final readings = snapshot.data ?? [];
                if (readings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.air, size: 64, color: AppTheme.borderColor),
                        const SizedBox(height: 12),
                        const Text(
                          'No air reports yet',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to submit your first report',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: readings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final r = readings[index];
                    final aqi = r['aqi'];
                    final category = r['aqiCategory'] as String?;
                    final hasViolation = r['hasViolation'] as bool? ?? false;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasViolation
                              ? AppTheme.errorColor.withOpacity(0.4)
                              : AppTheme.borderColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: aqi != null
                                ? _aqiColor(category).withOpacity(0.12)
                                : AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: aqi != null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${(aqi as num).round()}',
                                        style: TextStyle(
                                          color: _aqiColor(category),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'AQI',
                                        style: TextStyle(
                                          color: _aqiColor(category),
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Icon(Icons.air,
                                    color: AppTheme.primaryColor, size: 22),
                          ),
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
                                child: const Text(
                                  'Violation',
                                  style: TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              r['industryName'] ?? r['monitoringType'] ?? '—',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTs(r['monitoringDateTime']),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
