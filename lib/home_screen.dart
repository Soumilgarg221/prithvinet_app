import 'package:flutter/material.dart';

import 'air_monitoring_form.dart';
import 'air_monitoring_list.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'noise_monitoring_list.dart';
import 'theme.dart';
import 'water_monitoring_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  UserModel? _user;
  Map<String, int> _monthlyCount = {'air': 0, 'water': 0, 'noise': 0};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final user = await _authService.getCurrentUserModel();
      if (user != null) {
        final counts =
            await _firestoreService.getMonthlySubmissionCount(user.uid);
        if (mounted) {
          setState(() {
            _user = user;
            _monthlyCount = counts;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _daysUntilDeadline {
    final now = DateTime.now();
    final deadline = DateTime(now.year, now.month, 10);
    if (now.day > 10) {
      final nextMonth = DateTime(now.year, now.month + 1, 10);
      return nextMonth.difference(now).inDays;
    }
    return deadline.difference(now).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            const Text('PrithviNet'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            onSelected: (v) async {
              if (v == 'logout') {
                await _authService.signOut();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_user?.name ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(_user?.role ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryLight
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${_user?.name.split(' ').first ?? 'Officer'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _user?.roName ?? 'Monitoring Team',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$_daysUntilDeadline',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Text(
                                  'days left',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Deadline reminder
                    if (_daysUntilDeadline <= 5)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.warningColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule,
                                color: AppTheme.warningColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Monthly submission deadline in $_daysUntilDeadline days (10th of the month)',
                                style: const TextStyle(
                                  color: AppTheme.warningColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Monthly stats
                    const Text(
                      'This Month\'s Submissions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatCard(
                          label: 'Air',
                          count: _monthlyCount['air'] ?? 0,
                          icon: Icons.air,
                          color: const Color(0xFF2E86C1),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Water',
                          count: _monthlyCount['water'] ?? 0,
                          icon: Icons.water_drop,
                          color: const Color(0xFF27AE60),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Noise',
                          count: _monthlyCount['noise'] ?? 0,
                          icon: Icons.volume_up,
                          color: const Color(0xFFE67E22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Submit
                    const Text(
                      'Submit New Report',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _QuickSubmitCard(
                      icon: Icons.air,
                      title: 'Air Monitoring Report',
                      subtitle: 'Stack emissions & ambient air quality',
                      color: const Color(0xFF2E86C1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AirMonitoringForm()),
                      ).then((_) => _loadData()),
                    ),
                    const SizedBox(height: 10),
                    _QuickSubmitCard(
                      icon: Icons.water_drop,
                      title: 'Water Monitoring Report',
                      subtitle: 'Natural & industrial waste water analysis',
                      color: const Color(0xFF27AE60),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WaterMonitoringList()),
                      ).then((_) => _loadData()),
                    ),
                    const SizedBox(height: 10),
                    _QuickSubmitCard(
                      icon: Icons.volume_up,
                      title: 'Noise Monitoring Report',
                      subtitle: 'Zone-based noise level monitoring',
                      color: const Color(0xFFE67E22),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NoiseMonitoringList()),
                      ).then((_) => _loadData()),
                    ),
                    const SizedBox(height: 24),

                    // Recent activity section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Reports',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AirMonitoringList()),
                          ),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickSubmitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickSubmitCard({
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
