import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/app_providers.dart';
import '../services/api_service.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;
  String _animatingHash = '';
  String _currentHash = '';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _loading = true;
      _animatingHash = '';
      _currentHash = '';
    });

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.registerVoter(name);

      if (result['success'] == true) {
        final hash = result['voterHash'] as String;
        setState(() => _currentHash = hash);

        final random = Random();
        const chars = '0123456789abcdef';

        for (int i = 0; i <= hash.length; i++) {
          if (!mounted) return;
          await Future.delayed(const Duration(milliseconds: 30));
          
          String scrambled = '';
          for (int j = i; j < hash.length; j++) {
            scrambled += chars[random.nextInt(chars.length)];
          }
          
          setState(() => _animatingHash = hash.substring(0, i) + scrambled);
        }

        setState(() {
           _animatingHash = hash;
           _currentHash = hash;
        });

        ref.read(registeredVotersProvider.notifier).addVoter({
          'name': name,
          'hash': hash,
          'timestamp': DateTime.now().toIso8601String(),
        });
        ref.read(activityLogProvider.notifier).addLog('SYSTEM', 'Voter registered: ${hash.substring(0, 16)}...');
        ref.invalidate(electionStatusProvider);

        _nameController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voter registered: ${hash.substring(0, 16)}...'),
              backgroundColor: AppTheme.neonGreen.withOpacity(0.8),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Registration failed'),
              backgroundColor: AppTheme.neonRed.withOpacity(0.8),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.neonRed.withOpacity(0.8),
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voters = ref.watch(registeredVotersProvider);

    return Container(
      color: AppTheme.deepNavy,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_add, color: AppTheme.neonGreen, size: 32),
                const SizedBox(width: 12),
                Text(
                  'VOTER REGISTRATION',
                  style: TextStyle(
                    color: AppTheme.neonGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Register voters by generating their SHA-256 identity hash. Names are never stored on-chain.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            GlassCard(
              glowing: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REGISTER NEW VOTER',
                    style: TextStyle(
                      color: AppTheme.neonCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter voter\'s full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          onSubmitted: (_) => _register(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GlowingButton(
                        label: 'Generate Hash',
                        icon: Icons.tag,
                        onPressed: _register,
                        loading: _loading,
                        color: AppTheme.neonGreen,
                      ),
                    ],
                  ),
                  if (_animatingHash.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.neonCyan.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SHA-256 HASH GENERATION',
                            style: TextStyle(
                              color: AppTheme.neonCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _animatingHash,
                            style: TextStyle(
                              color: AppTheme.neonGreen,
                              fontSize: 14,
                              fontFamily: 'monospace',
                              shadows: [
                                Shadow(color: AppTheme.neonGreen, blurRadius: 8),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_currentHash.isNotEmpty)
                            Text(
                              'Hash complete. This is the voter\'s on-chain identity.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
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
                        'REGISTERED VOTERS',
                        style: TextStyle(
                          color: AppTheme.neonGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${voters.length} total',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (voters.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No voters registered yet.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: voters.length,
                      itemBuilder: (ctx, i) {
                        final voter = voters[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.glassBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.neonGreen.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.neonGreen.withOpacity(0.2),
                                child: Text(
                                  (voter['name'] as String).substring(0, 1).toUpperCase(),
                                  style: TextStyle(color: AppTheme.neonGreen, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      voter['name'] ?? '',
                                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                    ),
                                    Text(
                                      'Hash: ${(voter['hash'] as String).substring(0, 32)}...',
                                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.check_circle, color: AppTheme.neonGreen, size: 18),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideX(begin: 0.1, curve: Curves.easeOutQuad),
        ),
      ),
    );
  }
}
