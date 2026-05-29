import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../services/app_refresh_service.dart';
import '../widgets/app_state_widgets.dart';

class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  List<Achievement> _achievements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AppRefreshService.achievementsVersion.addListener(_loadAchievements);
    _loadAchievements();
  }

  @override
  void dispose() {
    AppRefreshService.achievementsVersion.removeListener(_loadAchievements);
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final achievements = await AchievementService.getAll();
      if (!mounted) return;
      setState(() {
        _achievements = achievements;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  int get _unlockedCount =>
      _achievements.where((achievement) => achievement.isUnlocked).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievement')),
      body: _isLoading
          ? const AppLoading()
          : _errorMessage != null
              ? AppErrorState(
                  message: _errorMessage!,
                  onRetry: _loadAchievements,
                )
              : RefreshIndicator(
                  onRefresh: _loadAchievements,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Expanded(
                                child: AppStatCard(
                                  title: 'Unlocked',
                                  value: '$_unlockedCount/${_achievements.length}',
                                  icon: Icons.emoji_events,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppStatCard(
                                  title: 'Progress',
                                  value: _achievements.isEmpty
                                      ? '0%'
                                      : '${((_unlockedCount / _achievements.length) * 100).round()}%',
                                  icon: Icons.trending_up,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_achievements.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppEmptyState(
                            icon: Icons.emoji_events_outlined,
                            title: 'Belum ada achievement',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _AchievementTile(
                                    achievement: _achievements[index],
                                  ),
                                );
                              },
                              childCount: _achievements.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;

  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final progress = achievement.isUnlocked
        ? 1.0
        : (achievement.progressPercentage / 100).clamp(0.0, 1.0);
    final color = achievement.isUnlocked ? Colors.amber.shade700 : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: achievement.isUnlocked ? Colors.amber.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: achievement.isUnlocked
            ? Border.all(color: Colors.amber.shade300)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? Colors.amber.shade100
                  : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: achievement.isUnlocked
                  ? Text(achievement.icon, style: const TextStyle(fontSize: 22))
                  : Icon(Icons.lock, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: achievement.isUnlocked
                              ? Colors.black
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Icon(
                      achievement.isUnlocked
                          ? Icons.check_circle
                          : Icons.lock_outline,
                      color: achievement.isUnlocked
                          ? Colors.green
                          : Colors.grey.shade500,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: color,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  achievement.isUnlocked
                      ? 'Unlocked'
                      : '${achievement.progressCurrent.toStringAsFixed(0)} / ${achievement.progressTarget.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
