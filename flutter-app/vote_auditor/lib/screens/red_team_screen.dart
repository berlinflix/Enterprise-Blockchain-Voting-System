import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/app_providers.dart';
import '../services/api_service.dart';

class RedTeamScreen extends ConsumerStatefulWidget {
  const RedTeamScreen({super.key});

  @override
  ConsumerState<RedTeamScreen> createState() => _RedTeamScreenState();
}

class _RedTeamScreenState extends ConsumerState<RedTeamScreen> {
  bool _sybilLoading = false;
  bool _replayLoading = false;
  bool _tamperLoading = false;
  bool _mitmLoading = false;

  Future<void> _launchSybil() async {
    setState(() => _sybilLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.launchSybilAttack(count: 100);
      ref.read(attackLogProvider.notifier).addLog({
        'attack': 'Sybil',
        'result': 'REJECTED',
        'details': '${result['rejected']}/${result['attempted']} unauthorized hashes rejected',
        'timestamp': DateTime.now().toIso8601String(),
      });
      ref.read(activityLogProvider.notifier).addLog('ATTACK', 'Sybil attack: ${result['rejected']} fake votes rejected');
    } catch (e) {
      ref.read(attackLogProvider.notifier).addLog({
        'attack': 'Sybil',
        'result': 'ERROR',
        'details': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } finally {
      setState(() => _sybilLoading = false);
    }
  }

  Future<void> _launchReplay() async {
    setState(() => _replayLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.launchReplayAttack();
      ref.read(attackLogProvider.notifier).addLog({
        'attack': 'Replay',
        'result': result['result'] ?? 'REJECTED',
        'details': result['defense'] ?? 'Double voting prevented',
        'timestamp': DateTime.now().toIso8601String(),
      });
      ref.read(activityLogProvider.notifier).addLog('ATTACK', 'Replay attack: ${result['result']}');
    } catch (e) {
      ref.read(attackLogProvider.notifier).addLog({
        'attack': 'Replay',
        'result': 'ERROR',
        'details': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } finally {
      setState(() => _replayLoading = false);
    }
  }

  Future<void> _launchTamper() async {
    setState(() => _tamperLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.launchTamperAttack();
      ref.read(attackLogProvider.notifier).addLog({
        'attack': 'Tamper',
        'result': result['result'] ?? 'DETECTED',
        'details': result['defense'] ?? 'State hash mismatch detected',
        'timestamp': DateTime.now().toIso8601String(),
      });
      ref.read(activityLogProvider.notifier).addLog('ATTACK', 'Tamper attack: ${result['result']}');
    } catch (e) {
      ref.read(attackLogProvider.notifier).addLog({
        'attack': 'Tamper',
        'result': 'ERROR',
        'details': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } finally {
      setState(() => _tamperLoading = false);
    }
  }

  Future<void> _launchMitm() async {
    setState(() => _mitmLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.launchMitmAttack();
      ref.read(attackLogProvider.notifier).addLog({
        'attack': 'MITM',
        'result': result['result'] ?? 'DATA PROTECTED',
        'details': result['defense'] ?? 'Client-side encryption protects data in transit',
        'timestamp': DateTime.now().toIso8601String(),
      });
      ref.read(activityLogProvider.notifier).addLog('ATTACK', 'MITM attack: ${result['result']}');
    } catch (e) {
      ref.read(attackLogProvider.notifier).addLog({
        'attack': 'MITM',
        'result': 'ERROR',
        'details': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } finally {
      setState(() => _mitmLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(attackLogProvider);

    return Container(
      color: AppTheme.deepNavy,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: AppTheme.neonRed, size: 32),
                const SizedBox(width: 12),
                Text(
                  'RED TEAM CONTROL ROOM',
                  style: TextStyle(
                    color: AppTheme.neonRed,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Launch simulated attacks against the blockchain network to demonstrate its security resilience.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _AttackCard(
                      width: cardWidth,
                      title: 'SYBIL ATTACK',
                      subtitle: 'Voter Fraud Simulation',
                      description: 'Flood the network with 100 unauthorized voter hashes to test registration validation.',
                      icon: Icons.people_alt,
                      color: AppTheme.neonOrange,
                      loading: _sybilLoading,
                      onLaunch: _launchSybil,
                      expectedDefense: 'All unauthorized hashes rejected by registration validation',
                    ),
                    _AttackCard(
                      width: cardWidth,
                      title: 'REPLAY ATTACK',
                      subtitle: 'Double Voting Attempt',
                      description: 'Replay a previously cast vote payload to test double-voting prevention.',
                      icon: Icons.replay,
                      color: AppTheme.neonRed,
                      loading: _replayLoading,
                      onLaunch: _launchReplay,
                      expectedDefense: 'Chaincode detects hasVoted=true state and rejects the transaction',
                    ),
                    _AttackCard(
                      width: cardWidth,
                      title: 'NODE COMPROMISE',
                      subtitle: 'Ledger Tampering',
                      description: 'Attempt to alter vote data on a single node to test state consistency.',
                      icon: Icons.bug_report,
                      color: AppTheme.neonRed,
                      loading: _tamperLoading,
                      onLaunch: _launchTamper,
                      expectedDefense: 'State hash mismatch between Org1 and Org2 triggers endorsement failure',
                    ),
                    _AttackCard(
                      width: cardWidth,
                      title: 'MITM ATTACK',
                      subtitle: 'Traffic Interception',
                      description: 'Intercept network traffic to verify client-side encryption protects ballot secrecy.',
                      icon: Icons.wifi_tethering,
                      color: AppTheme.neonOrange,
                      loading: _mitmLoading,
                      onLaunch: _launchMitm,
                      expectedDefense: 'Intercepted data contains only ciphertext — vote choice is unreadable',
                    ),
                  ].animate(interval: 200.ms).fadeIn(duration: 500.ms).scale(curve: Curves.easeOutBack),
                );
              },
            ),
            const SizedBox(height: 24),
            GlassCard(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ATTACK LOG',
                        style: TextStyle(
                          color: AppTheme.neonRed,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${logs.length} attacks',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (logs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.shield, color: AppTheme.neonGreen, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              'No attacks launched yet. The network is secure.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      itemBuilder: (ctx, i) {
                        final log = logs[i];
                        final resultColor = log['result'] == 'ERROR'
                            ? AppTheme.neonOrange
                            : AppTheme.neonGreen;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.glassBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: resultColor.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.neonRed.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      log['attack'] ?? '',
                                      style: TextStyle(
                                        color: AppTheme.neonRed,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: resultColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      log['result'] ?? '',
                                      style: TextStyle(
                                        color: resultColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    (log['timestamp'] ?? '').toString().substring(0, 19),
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                log['details'] ?? '',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideX(begin: 0.1);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttackCard extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onLaunch;
  final String expectedDefense;

  const _AttackCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onLaunch,
    required this.expectedDefense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.neonGreen.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield, color: AppTheme.neonGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Defense: $expectedDefense',
                    style: TextStyle(color: AppTheme.neonGreen, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GlowingButton(
              label: 'Launch Attack',
              icon: Icons.rocket_launch,
              onPressed: onLaunch,
              loading: loading,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
