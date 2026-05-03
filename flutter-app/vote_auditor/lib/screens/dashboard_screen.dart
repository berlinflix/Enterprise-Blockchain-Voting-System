import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/app_providers.dart';
import '../services/api_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _loading = false;

  Future<void> _initElection() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.setupElection();
      ref.invalidate(electionStatusProvider);
      ref.invalidate(blocksProvider);
      ref.read(activityLogProvider.notifier).addLog('SYSTEM', 'Election initialized successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Election initialized successfully'),
            backgroundColor: AppTheme.neonGreen.withOpacity(0.8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppTheme.neonRed.withOpacity(0.8),
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(electionStatusProvider);
    ref.invalidate(blocksProvider);
    ref.invalidate(tallyProvider);
    ref.invalidate(ledgerVerificationProvider);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(electionStatusProvider);
    final blocks = ref.watch(blocksProvider);
    final tally = ref.watch(tallyProvider);
    final verification = ref.watch(ledgerVerificationProvider);
    final activities = ref.watch(activityLogProvider);

    return Container(
      color: AppTheme.deepNavy,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: AppTheme.neonCyan, size: 32),
                const SizedBox(width: 12),
                Text(
                  'AUDITOR DASHBOARD',
                  style: TextStyle(
                    color: AppTheme.neonCyan,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                StatusBadge(
                  status: status.when(
                    data: (d) => (d['status'] ?? 'OFFLINE').toString().toUpperCase(),
                    loading: () => 'LOADING',
                    error: (_, __) => 'OFFLINE',
                  ),
                  color: status.when(
                    data: (d) => d['status'] == 'ACTIVE' ? AppTheme.neonGreen : AppTheme.neonOrange,
                    loading: () => AppTheme.neonOrange,
                    error: (_, __) => AppTheme.neonRed,
                  ),
                ),
                const SizedBox(width: 12),
                GlowingButton(
                  label: 'Initialize Election',
                  icon: Icons.rocket_launch,
                  onPressed: _initElection,
                  loading: _loading,
                ),
                const SizedBox(width: 8),
                GlowingButton(
                  label: 'Refresh',
                  icon: Icons.refresh,
                  onPressed: _refresh,
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 48) / 4;
                return Row(
                  children: [
                    StatCard(
                      width: cardWidth,
                      label: 'VOTES CAST',
                      value: status.when(
                        data: (d) => (d['totalVotesCast'] ?? 0).toString(),
                        loading: () => '...',
                        error: (_, __) => '0',
                      ),
                      icon: Icons.how_to_vote,
                      color: AppTheme.neonCyan,
                    ),
                    const SizedBox(width: 16),
                    StatCard(
                      width: cardWidth,
                      label: 'REGISTERED VOTERS',
                      value: status.when(
                        data: (d) => (d['registeredVoters'] ?? 0).toString(),
                        loading: () => '...',
                        error: (_, __) => '0',
                      ),
                      icon: Icons.people,
                      color: AppTheme.neonGreen,
                    ),
                    const SizedBox(width: 16),
                    StatCard(
                      width: cardWidth,
                      label: 'BLOCKS MINTED',
                      value: blocks.when(
                        data: (d) => (d['totalBlocks'] ?? 0).toString(),
                        loading: () => '...',
                        error: (_, __) => '0',
                      ),
                      icon: Icons.link,
                      color: AppTheme.neonOrange,
                    ),
                    const SizedBox(width: 16),
                    StatCard(
                      width: cardWidth,
                      label: 'CHAIN STATUS',
                      value: verification.when(
                        data: (d) => d['valid'] == true ? 'VALID' : 'CHECK',
                        loading: () => '...',
                        error: (_, __) => 'N/A',
                      ),
                      icon: Icons.verified,
                      color: verification.when(
                        data: (d) => d['valid'] == true ? AppTheme.neonGreen : AppTheme.neonRed,
                        loading: () => AppTheme.neonOrange,
                        error: (_, __) => AppTheme.textSecondary,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      GlassCard(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LIVE BLOCKCHAIN VISUALIZER',
                              style: TextStyle(
                                color: AppTheme.neonCyan,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            blocks.when(
                              data: (d) {
                                final blockList = (d['blocks'] as List?) ?? [];
                                if (blockList.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Text(
                                        'No blocks yet. Initialize the election to begin.',
                                        style: TextStyle(color: AppTheme.textSecondary),
                                      ),
                                    ),
                                  );
                                }
                                return SizedBox(
                                  height: 300,
                                  child: ListView.builder(
                                    itemCount: blockList.length,
                                    itemBuilder: (ctx, i) {
                                      final block = blockList[i];
                                      return _BlockWidget(block: block, index: i);
                                    },
                                  ),
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, _) => Text('Error: $e', style: TextStyle(color: AppTheme.neonRed)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ELECTION RESULTS',
                              style: TextStyle(
                                color: AppTheme.neonGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            tally.when(
                              data: (d) {
                                final results = (d['results'] as List?) ?? [];
                                if (results.isEmpty) {
                                  return Text(
                                    'No votes cast yet.',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  );
                                }
                                final total = results.fold<int>(
                                  0,
                                  (sum, c) => sum + ((c['votes'] as int?) ?? 0),
                                );
                                return SizedBox(
                                  height: 250,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: total > 0 ? total.toDouble() + 2 : 10,
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          tooltipBgColor: AppTheme.glassBg,
                                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                            return BarTooltipItem(
                                              '${results[group.x.toInt()]['name']}\n${rod.toY.round()} votes',
                                              TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
                                            );
                                          },
                                        ),
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              if (value.toInt() >= 0 && value.toInt() < results.length) {
                                                final name = results[value.toInt()]['name'] as String;
                                                final initials = name.split(' ').map((e) => e[0]).join('');
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: Text(initials, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                                                );
                                              }
                                              return const Text('');
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.glassBorder, strokeWidth: 1),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barGroups: results.asMap().entries.map((e) {
                                        final index = e.key;
                                        final votes = (e.value['votes'] as int?) ?? 0;
                                        return BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              toY: votes.toDouble(),
                                              color: index == 0 ? AppTheme.neonCyan : (index == 1 ? AppTheme.neonGreen : AppTheme.neonOrange),
                                              width: 32,
                                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                                              backDrawRodData: BackgroundBarChartRodData(
                                                show: true,
                                                toY: total > 0 ? total.toDouble() + 2 : 10,
                                                color: AppTheme.glassBg,
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ).animate().fadeIn(duration: 600.ms).scaleXY(begin: 0.9, duration: 600.ms, curve: Curves.easeOutBack),
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, _) => Text('Error: $e', style: TextStyle(color: AppTheme.neonRed)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: GlassCard(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVITY LOG',
                          style: TextStyle(
                            color: AppTheme.neonOrange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (activities.isEmpty)
                          Text(
                            'No activity yet.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          )
                        else
                          SizedBox(
                            height: 500,
                            child: ListView.builder(
                              itemCount: activities.length,
                              itemBuilder: (ctx, i) {
                                final a = activities[i];
                                final color = _typeColor(a['type']);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(top: 6, right: 8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: color,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          a['message'] ?? '',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad),
        ),
      ),
    );
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'VOTE':
        return AppTheme.neonCyan;
      case 'ATTACK':
        return AppTheme.neonRed;
      case 'SYSTEM':
        return AppTheme.neonGreen;
      default:
        return AppTheme.textSecondary;
    }
  }
}

class _BlockWidget extends StatelessWidget {
  final Map<String, dynamic> block;
  final int index;

  const _BlockWidget({required this.block, required this.index});

  @override
  Widget build(BuildContext context) {
    final hash = (block['hash'] ?? '').toString();
    final prevHash = (block['previousHash'] ?? '').toString();
    final data = block['data'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.glassBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                '#${block['index'] ?? index}',
                style: TextStyle(
                  color: AppTheme.neonCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hash: ${hash.substring(0, hash.length > 24 ? 24 : hash.length)}...',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  'Prev: ${prevHash.substring(0, prevHash.length > 24 ? 24 : prevHash.length)}...',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  'Type: ${data is Map ? data['type'] ?? 'UNKNOWN' : 'DATA'}',
                  style: TextStyle(color: AppTheme.neonGreen, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            (block['timestamp'] ?? '').toString().substring(0, 19),
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _CandidateBar extends StatelessWidget {
  final String name;
  final String party;
  final int votes;
  final double percentage;

  const _CandidateBar({
    required this.name,
    required this.party,
    required this.votes,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
            Text('$votes votes', style: TextStyle(color: AppTheme.neonCyan, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        Text(party, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: AppTheme.glassBg,
            valueColor: AlwaysStoppedAnimation(
              AppTheme.neonCyan.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}
