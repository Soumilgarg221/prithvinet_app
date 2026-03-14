import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'firestore_service.dart';
import 'noise_monitoring_form.dart';
import 'theme.dart';

class NoiseMonitoringList extends StatefulWidget {
  const NoiseMonitoringList({super.key});

  @override
  State<NoiseMonitoringList> createState() => _NoiseMonitoringListState();
}

class _NoiseMonitoringListState extends State<NoiseMonitoringList> {
  final _auth = AuthService();
  final _fs = FirestoreService();
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _auth.getCurrentUserModel().then((u) => setState(() => _user = u));
  }

  String _formatTs(dynamic ts) {
    if (ts == null) return '—';
    final dt = (ts as Timestamp).toDate();
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Noise Monitoring Reports')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoiseMonitoringForm()),
        ),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Report', style: TextStyle(color: Colors.white)),
      ),
      body: _user == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fs.getNoiseReadings(uid: _user!.uid),
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
                        Icon(Icons.volume_up,
                            size: 64, color: AppTheme.borderColor),
                        const SizedBox(height: 12),
                        const Text(
                          'No noise reports yet',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 15),
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
                  itemBuilder: (context, i) {
                    final r = readings[i];
                    final hasViolation = r['hasViolation'] as bool? ?? false;
                    final rowList = r['readings'] as List? ?? [];
                    final violationCount =
                        rowList.where((row) => row['isHigh'] == true).length;

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
                            color: const Color(0xFFE67E22).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.volume_up,
                              color: Color(0xFFE67E22), size: 22),
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
                                child: Text(
                                  '$violationCount violation${violationCount != 1 ? 's' : ''}',
                                  style: const TextStyle(
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
                              '${rowList.length} reading${rowList.length != 1 ? 's' : ''} recorded',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              _formatTs(r['monitoringDateTime']),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: AppTheme.textSecondary, size: 18),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
