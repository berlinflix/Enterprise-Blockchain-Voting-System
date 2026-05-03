import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/app_providers.dart';
import '../services/api_service.dart';

class VotingScreen extends ConsumerStatefulWidget {
  const VotingScreen({super.key});

  @override
ConsumerState<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<VotingScreen> {
  final _hashController = TextEditingController();
  String? _selectedCandidate;
  bool _loading = false;
  String _encryptionAnim = '';
  bool _showEncryption = false;
  List<Map<String, dynamic>> _candidates = [];

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    try {
      final api = ref.read(apiServiceProvider);
      final status = await api.getElectionStatus();
      if (mounted) {
        setState(() {
          _candidates = (status['candidates'] as List?)
              ?.map((c) => Map<String, dynamic>.from(c))
              .toList() ?? [];
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _hashController.dispose();
    super.dispose();
  }

  Future<void> _castVote() async {
    final hash = _hashController.text.trim();
    if (hash.isEmpty || _selectedCandidate == null) return;

    setState(() {
      _loading = true;
      _showEncryption = true;
      _encryptionAnim = '';
    });

    const plain = 'VOTE_SELECT: ';
    final cipherChars = '█▓▒░@#\$%&*!?;:<>[]{}()';
    for (int i = 0; i < 40; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 30));
      final buf = StringBuffer();
      for (int j = 0; j < i && j < 30; j++) {
        buf.write(cipherChars[j % cipherChars.length]);
      }
      setState(() => _encryptionAnim = buf.toString());
    }

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.castVote(hash, _selectedCandidate!);

      if (result['success'] == true) {
        ref.read(activityLogProvider.notifier).addLog('VOTE', 'Vote cast: TX ${result['txId']}');
        ref.invalidate(electionStatusProvider);
        ref.invalidate(blocksProvider);
        ref.invalidate(tallyProvider);

        _hashController.clear();
        setState(() => _selectedCandidate = null);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vote recorded! Block #${result['blockIndex']}'),
              backgroundColor: AppTheme.neonGreen.withOpacity(0.8),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Vote failed'),
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
    return Container(
      color: AppTheme.deepNavy,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_vote, color: AppTheme.neonCyan, size: 32),
                const SizedBox(width: 12),
                Text(
                  'VOTING BOOTH',
                  style: TextStyle(
                    color: AppTheme.neonCyan,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cast your vote. The ballot is RSA-encrypted client-side before transmission.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            GlassCard(
              glowing: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AUTHENTICATE & VOTE',
                    style: TextStyle(
                      color: AppTheme.neonCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _hashController,
                    decoration: const InputDecoration(
                      labelText: 'Voter Hash (SHA-256)',
                      hintText: 'Enter your 64-character voter hash',
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'SELECT CANDIDATE',
                    style: TextStyle(
                      color: AppTheme.neonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._candidates.map((c) => _CandidateTile(
                    candidate: c,
                    selected: _selectedCandidate == c['id'],
                    onTap: () => setState(() => _selectedCandidate = c['id']),
                  )),
                  const SizedBox(height: 24),
                  if (_showEncryption) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.neonRed.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.neonRed.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RSA ENCRYPTION IN PROGRESS',
                            style: TextStyle(
                              color: AppTheme.neonRed,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _encryptionAnim,
                            style: TextStyle(
                              color: AppTheme.neonOrange,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (!_loading)
                            Text(
                              'Encryption complete. Ballot secured.',
                              style: TextStyle(color: AppTheme.neonGreen, fontSize: 11),
                            ),
                        ],
                      ).animate().fadeIn().scale().shimmer(duration: 2000.ms, color: AppTheme.neonRed.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Center(
                    child: GlowingButton(
                      label: 'Cast Encrypted Vote',
                      icon: Icons.lock,
                      onPressed: _selectedCandidate != null ? _castVote : null,
                      loading: _loading,
                      color: AppTheme.neonGreen,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),
          ].animate(interval: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad),
        ),
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  final Map<String, dynamic> candidate;
  final bool selected;
  final VoidCallback onTap;

  const _CandidateTile({
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.neonCyan.withOpacity(0.1) : AppTheme.glassBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.neonCyan : AppTheme.glassBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.neonCyan : AppTheme.textSecondary,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.neonCyan,
                          boxShadow: [BoxShadow(color: AppTheme.neonCyan, blurRadius: 6)],
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate['name'] ?? '',
                    style: TextStyle(
                      color: selected ? AppTheme.neonCyan : AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    candidate['party'] ?? '',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: AppTheme.neonCyan, size: 20),
          ],
        ),
      ),
    );
  }
}
