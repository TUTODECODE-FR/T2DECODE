// ============================================================
// Gamification Dashboard — Tableau de bord progression
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/features/courses/providers/gamification_provider.dart';
import 'package:tutodecode/features/courses/models/gamification_models.dart';

class GamificationDashboardScreen extends StatefulWidget {
  const GamificationDashboardScreen({super.key});

  @override
  State<GamificationDashboardScreen> createState() => _GamificationDashboardScreenState();
}

class _GamificationDashboardScreenState extends State<GamificationDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Progression',
        showBackButton: true,
        actions: [],
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationProvider>(
      builder: (context, provider, child) {
        if (!provider.loaded) {
          return const Center(
            child: CircularProgressIndicator(color: TdcColors.accent),
          );
        }

        return Column(
          children: [
            _buildProfileHeader(provider.profile, provider),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(provider),
                  _buildAchievementsTab(provider),
                  _buildChallengesTab(provider),
                  _buildLeaderboardTab(provider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeader(UserProfile profile, GamificationProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TdcColors.surface,
            TdcColors.surfaceAlt.withOpacity(0.3),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: TdcColors.accent,
                child: Text(
                  profile.username.isNotEmpty ? profile.username[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.username,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRankColor(profile.rank),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            profile.rank,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Niveau ${profile.currentLevel}',
                          style: const TextStyle(
                            color: TdcColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${profile.totalPoints}',
                    style: const TextStyle(
                      color: TdcColors.accent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'points',
                    style: TextStyle(
                      color: TdcColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLevelProgress(profile),
          const SizedBox(height: 16),
          _buildStatsRow(profile, provider),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression Niveau ${profile.currentLevel}',
              style: const TextStyle(
                color: TdcColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              '${profile.pointsToNextLevel} XP',
              style: const TextStyle(
                color: TdcColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: TdcColors.surfaceAlt,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: profile.levelProgress,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [TdcColors.accent, TdcColors.success],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(UserProfile profile, GamificationProvider provider) {
    return Row(
      children: [
        _buildStatItem('🔥', '${profile.streakDays}', 'Jours consécutifs'),
        const SizedBox(width: 16),
        _buildStatItem('📚', '${profile.completedChapters.length}', 'Chapitres'),
        const SizedBox(width: 16),
        _buildStatItem('🏆', '${provider.unlockedAchievements.length}', 'Achievements'),
      ],
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: TdcColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: TdcColors.accent,
        labelColor: TdcColors.accent,
        unselectedLabelColor: TdcColors.textMuted,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Aperçu'),
          Tab(text: 'Achievements'),
          Tab(text: 'Défis'),
          Tab(text: 'Classement'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(GamificationProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressByCategory(provider),
          const SizedBox(height: 24),
          _buildSkillTrees(provider),
          const SizedBox(height: 24),
          _buildLearningPaths(provider),
        ],
      ),
    );
  }

  Widget _buildProgressByCategory(GamificationProvider provider) {
    final progress = provider.getProgressByCategory();
    
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progression par Catégorie',
              style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...progress.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCategoryProgress(entry.key, entry.value),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgress(String category, double progress) {
    final categoryData = _getCategoryData(category);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(categoryData['icon'], color: categoryData['color'], size: 16),
            const SizedBox(width: 8),
            Text(
              categoryData['title'],
              style: const TextStyle(
                color: TdcColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: categoryData['color'],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: TdcColors.surfaceAlt,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: categoryData['color'],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillTrees(GamificationProvider provider) {
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Arbres de Compétences',
              style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...provider.skillTrees.map((tree) => _buildSkillTreeCard(tree)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillTreeCard(SkillTree tree) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TdcColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tree.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(tree.icon, color: tree.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tree.title,
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  tree.description,
                  style: const TextStyle(
                    color: TdcColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: TdcColors.textMuted, size: 16),
        ],
      ),
    );
  }

  Widget _buildLearningPaths(GamificationProvider provider) {
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parcours d\'Apprentissage',
              style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...provider.learningPaths.map((path) => _buildPathCard(path)),
          ],
        ),
      ),
    );
  }

  Widget _buildPathCard(LearningPath path) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                path.title,
                style: const TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (path.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: TdcColors.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '✓ Complété',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            path.description,
            style: const TextStyle(
              color: TdcColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${path.estimatedHours}h',
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                path.difficulty,
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                width: 100,
                height: 4,
                decoration: BoxDecoration(
                  color: TdcColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: path.progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: TdcColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(GamificationProvider provider) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Débloqués'),
              Tab(text: 'En cours'),
              Tab(text: 'Disponibles'),
            ],
            indicatorColor: TdcColors.accent,
            labelColor: TdcColors.accent,
            unselectedLabelColor: TdcColors.textMuted,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAchievementList(provider.unlockedAchievements),
                _buildAchievementList(provider.inProgressAchievements),
                _buildAchievementList(provider.availableAchievements),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementList(List<Achievement> achievements) {
    if (achievements.isEmpty) {
      return Center(
        child: Text(
          'Aucun achievement dans cette catégorie',
          style: TextStyle(color: TdcColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(achievements[index]);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achievement.isUnlocked 
            ? achievement.color.withOpacity(0.1)
            : TdcColors.surfaceAlt.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.isUnlocked 
              ? achievement.color.withOpacity(0.3)
              : TdcColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: achievement.isUnlocked 
                  ? achievement.color.withOpacity(0.2)
                  : TdcColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              achievement.icon,
              color: achievement.isUnlocked ? achievement.color : TdcColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: achievement.isUnlocked ? TdcColors.textPrimary : TdcColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    color: TdcColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (!achievement.isUnlocked && achievement.progress > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: TdcColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: achievement.progress / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: achievement.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '+${achievement.points}',
                style: TextStyle(
                  color: achievement.isUnlocked ? achievement.color : TdcColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (achievement.isUnlocked)
                const Icon(Icons.check_circle, color: TdcColors.success, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab(GamificationProvider provider) {
    final activeChallenges = provider.getActiveChallenges();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeChallenges.length,
      itemBuilder: (context, index) {
        return _buildChallengeCard(activeChallenges[index]);
      },
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    final hoursLeft = challenge.deadline.difference(DateTime.now()).inHours;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(challenge.difficulty),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Niv. ${challenge.difficulty}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: const TextStyle(
              color: TdcColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.timer, color: TdcColors.textMuted, size: 16),
              const SizedBox(width: 4),
              Text(
                '$hoursLeft h restantes',
                style: const TextStyle(
                  color: TdcColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Icon(Icons.star, color: TdcColors.accent, size: 16),
              const SizedBox(width: 4),
              Text(
                '+${challenge.pointsReward}',
                style: const TextStyle(
                  color: TdcColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...challenge.requiredChapters.map((chapter) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.radio_button_unchecked, color: TdcColors.textMuted, size: 12),
                const SizedBox(width: 8),
                Text(
                  chapter,
                  style: const TextStyle(
                    color: TdcColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(GamificationProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.leaderboard.length,
      itemBuilder: (context, index) {
        return _buildLeaderboardEntry(provider.leaderboard[index], index + 1);
      },
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TdcColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank == 1 ? Colors.amber : rank == 2 ? Colors.blueGrey : rank == 3 ? Colors.brown : Colors.grey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                rank <= 3 ? _getRankEmoji(rank) : '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            entry.avatar,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  entry.rank,
                  style: const TextStyle(
                    color: TdcColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
                style: const TextStyle(
                  color: TdcColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Niv. ${entry.level}',
                style: const TextStyle(
                  color: TdcColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCategoryData(String category) {
    switch (category) {
      case 'linux':
        return {'title': 'Linux', 'icon': Icons.computer, 'color': Colors.green};
      case 'network':
        return {'title': 'Réseau', 'icon': Icons.router, 'color': Colors.blue};
      case 'security':
        return {'title': 'Sécurité', 'icon': Icons.security, 'color': Colors.red};
      case 'development':
        return {'title': 'Développement', 'icon': Icons.code, 'color': Colors.purple};
      default:
        return {'title': category, 'icon': Icons.help, 'color': Colors.grey};
    }
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Légende': return Colors.purple;
      case 'Master': return Colors.red;
      case 'Expert': return Colors.orange;
      case 'Apprenti': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1: return Colors.green;
      case 2: return Colors.blue;
      case 3: return Colors.orange;
      case 4: return Colors.red;
      case 5: return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '$rank';
    }
  }
}
