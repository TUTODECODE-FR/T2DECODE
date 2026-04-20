// ============================================================
// home_screen.dart — Page d'accueil responsive TutoDeCode
// ── Desktop  : sidebar + grille 3 cols + panneau droit
// ── Tablet   : drawer + grille 2 cols + panneau droit
// ── Mobile   : BottomNav + liste verticale + panneau accordéon
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../courses/providers/courses_provider.dart';
import '../../courses/data/course_repository.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/responsive/responsive.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../ghost_ai/service/ollama_service.dart';
import '../../ghost_link/service/ghost_link_service.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/providers/settings_provider.dart';
import 'package:tutodecode/core/services/snapshot_service.dart';
import 'package:tutodecode/core/providers/search_provider.dart';
import 'package:tutodecode/core/services/asset_integrity_service.dart';
import 'package:tutodecode/core/navigation/nav_keys.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OllamaStatus? _aiStatus;
  final SnapshotService _snapshots = SnapshotService();
  bool _integrityChecked = false;

  bool get isSmall => MediaQuery.of(context).size.width < 360;

  @override
  void initState() {
    super.initState();
    _checkAI();
    // Configure shell on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Accueil',
        showBackButton: false,
        actions: [],
      );
      _snapshots.maybeCreateDailySnapshot();
      _maybeVerifyAssets();
    });
  }

  Future<void> _maybeVerifyAssets() async {
    if (_integrityChecked) return;
    _integrityChecked = true;
    final settings = context.read<SettingsProvider>();
    if (!settings.securityUpdates) return;
    try {
      final mismatched = await AssetIntegrityService().verify();
      if (!mounted) return;
      if (mismatched.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Alerte intégrité: certains assets semblent modifiés.'),
            backgroundColor: TdcColors.danger,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _checkAI() async {
    final s = await OllamaService.checkStatus();
    if (mounted) setState(() => _aiStatus = s);
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<CoursesProvider>(builder: (context, prov, _) {
      if (!prov.loaded) {
        return Container(
          color: TdcColors.bg,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                      color: TdcColors.accent, strokeWidth: 2.5),
                ).animate(onPlay: (c) => c.repeat()).shimmer(
                    duration: 1400.ms,
                    color: TdcColors.accent.withValues(alpha: 0.35)),
                const SizedBox(height: 20),
                Text(
                  'Chargement…',
                  style: TextStyle(
                      color: TdcColors.textMuted,
                      fontSize: 13,
                      letterSpacing: 0.8),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
        );
      }

      final search = context.watch<SearchProvider>();
      if (!search.ready) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.read<SearchProvider>().init(prov);
        });
      }

      return ResponsiveBuilder(
        builder: (ctx, type) {
          if (type.isDesktop) return _buildDesktopBody(ctx, prov);
          if (type.isTablet) return _buildTabletBody(ctx, prov);
          return _buildMobileBody(ctx, prov);
        },
      );
    });
  }

  // ════════════════════════════════════════════════════════
  // DESKTOP : contenu + panneau droit (300px)
  // ════════════════════════════════════════════════════════
  Widget _buildDesktopBody(BuildContext context, CoursesProvider prov) {
    return TdcPageWrapper(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainHeader(context, prov),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.xl)),
            _buildQuickStatusRow(context, prov),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.xl)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAIPanel(context)),
                SizedBox(width: TdcAdaptive.space(context, TdcSpacing.md)),
                Expanded(child: _buildGhostLinkPanel(context)),
              ],
            ),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.xl)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, prov),
                      SizedBox(
                          height: TdcAdaptive.space(context, TdcSpacing.md)),
                      _buildCourseGrid(context, prov, crossAxisCount: 3),
                    ],
                  ),
                ),
                SizedBox(width: TdcAdaptive.space(context, TdcSpacing.xl)),
                SizedBox(
                  width: TdcAdaptive.space(context, 310),
                  child: Column(
                    children: [
                      _buildProgressPanel(prov),
                      SizedBox(
                          height: TdcAdaptive.space(context, TdcSpacing.lg)),
                      _buildToolsPanel(context),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.xl)),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // TABLET : grille 2 colonnes, panneau droit replié en bas
  // ════════════════════════════════════════════════════════
  Widget _buildTabletBody(BuildContext context, CoursesProvider prov) {
    return TdcPageWrapper(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainHeader(context, prov),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.xl)),
            _buildQuickStatusRow(context, prov),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.xl)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAIPanel(context)),
                SizedBox(width: TdcAdaptive.space(context, TdcSpacing.md)),
                Expanded(child: _buildGhostLinkPanel(context)),
              ],
            ),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.xl)),
            _buildSectionHeader(context, prov),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.md)),
            _buildCourseGrid(context, prov, crossAxisCount: 2),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.xl)),
            _buildProgressPanel(prov),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),
            _buildToolsPanel(context),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.xl)),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // MOBILE : liste en colonne, accordéon pour les outils
  // ════════════════════════════════════════════════════════
  Widget _buildMobileBody(BuildContext context, CoursesProvider prov) {
    return TdcPageWrapper(
      padding: EdgeInsets.all(TdcAdaptive.padding(context, TdcSpacing.md)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMobileHeader(context, prov),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),
            _buildProgressBar(prov),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),
            _buildContinueLearningCard(context, prov, compact: true),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.md)),
            _buildMobileServicePanels(context),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),
            Row(children: [
              Icon(Icons.menu_book,
                  color: TdcColors.textPrimary,
                  size: TdcAdaptive.icon(context, 18)),
              SizedBox(width: TdcAdaptive.space(context, TdcSpacing.sm)),
              Text('Mes parcours',
                  style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: TdcText.h3(context),
                      fontWeight: FontWeight.bold)),
            ]),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.md)),
            _buildCourseGrid(context, prov, crossAxisCount: 1),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),
            _buildMobileQuickActions(context),
            SizedBox(height: TdcAdaptive.space(context, 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainHeader(BuildContext context, CoursesProvider _) {
    final logo = Image.asset('assets/logo.png',
        width: TdcAdaptive.icon(context, 160),
        height: TdcAdaptive.icon(context, 160));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: TdcAdaptive.space(context, 56),
        horizontal: TdcAdaptive.space(context, 12),
      ),
      decoration: const BoxDecoration(
        color: TdcColors.bg,
        border: Border(bottom: BorderSide(color: TdcColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          logo,
          SizedBox(height: TdcAdaptive.space(context, 24)),
          Text(
            'APPRENDRE.\nCONSTRUIRE.\nCOMPRENDRE.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TdcColors.textPrimary,
              fontSize: TdcAdaptive.space(context, 56),
              fontWeight: FontWeight.w900,
              height: 0.88,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: TdcAdaptive.space(context, 20)),
          Text(
            'Comprendre l’informatique. Créer ses propres outils. Reprendre le contrôle.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TdcColors.textMuted,
              fontSize: TdcText.bodyLarge(context),
              height: 1.5,
            ),
          ),
          SizedBox(height: TdcAdaptive.space(context, 24)),
          ElevatedButton(
            onPressed: () => AppNavigator.pushNamed('/tools'),
            child: const Text('Explorer'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context, CoursesProvider _) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('T2DECODE',
            style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: TdcText.h2(context),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4)),
        const SizedBox(height: 6),
        Text('Apprendre. Construire. Comprendre.',
            style: TextStyle(
                color: TdcColors.textMuted, fontSize: TdcText.caption(context))),
      ],
    );
  }

  Widget _buildQuickStatusRow(BuildContext context, CoursesProvider prov) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildContinueLearningCard(context, prov)),
        SizedBox(width: TdcAdaptive.space(context, TdcSpacing.md)),
        Expanded(
          child: Wrap(
            spacing: TdcAdaptive.space(context, TdcSpacing.sm),
            runSpacing: TdcAdaptive.space(context, TdcSpacing.sm),
            children: [
              _buildInsightChip(
                context,
                icon: Icons.menu_book_outlined,
                label: '${prov.courses.length} parcours',
                tone: TdcColors.info,
              ),
              _buildInsightChip(
                context,
                icon: Icons.check_circle_outline,
                label: '${prov.completedCount} chapitres terminés',
                tone: TdcColors.success,
              ),
              _buildInsightChip(
                context,
                icon: Icons.smart_toy_outlined,
                label: _aiStatus?.running == true
                    ? '${_aiStatus!.models.length} modeles IA'
                    : 'IA locale optionnelle',
                tone:
                    _aiStatus?.running == true ? TdcColors.info : TdcColors.textMuted,
              ),
              _buildInsightChip(
                context,
                icon: Icons.search,
                label: 'Recherche globale integree',
                tone: TdcColors.accent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueLearningCard(BuildContext context, CoursesProvider prov,
      {bool compact = false}) {
    final course = _preferredCourse(prov);
    final chapter = _preferredChapter(prov, course);
    final done = course == null ? 0 : prov.courseCompletedCount(course.id);
    final total = course?.chapters.length ?? 0;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: EdgeInsets.all(TdcAdaptive.padding(
          context, compact ? TdcSpacing.md : TdcSpacing.lg)),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.lg,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(TdcAdaptive.padding(context, 8)),
                decoration: BoxDecoration(
                  color: TdcColors.accent.withValues(alpha: 0.1),
                  borderRadius: TdcRadius.sm,
                ),
                child: Icon(Icons.play_circle_fill,
                    color: TdcColors.accent, size: TdcAdaptive.icon(context, 18)),
              ),
              SizedBox(width: TdcAdaptive.space(context, TdcSpacing.sm)),
              Expanded(
                child: Text(
                  course == null ? 'Pret a commencer' : 'Reprendre la progression',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? TdcText.body(context) : TdcText.h3(context),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: TdcAdaptive.space(context, TdcSpacing.sm)),
          Text(
            course == null
                ? 'Choisis un parcours et commence directement depuis l accueil.'
                : course.title,
            style: TextStyle(
              color: TdcColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: compact ? TdcText.body(context) : TdcText.h3(context),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: TdcAdaptive.space(context, 6)),
          Text(
            chapter == null
                ? 'Accede a tes outils, cours et simulations en quelques secondes.'
                : 'Prochain chapitre : ${chapter.title}',
            style: TextStyle(
              color: TdcColors.textMuted,
              fontSize: TdcText.bodySmall(context),
              height: 1.4,
            ),
          ),
          SizedBox(height: TdcAdaptive.space(context, TdcSpacing.md)),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: TdcAdaptive.space(context, compact ? 6 : 7),
              backgroundColor: TdcColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(TdcColors.accent),
            ),
          ),
          SizedBox(height: TdcAdaptive.space(context, 8)),
          Row(
            children: [
              Expanded(
                child: Text(
                  course == null
                      ? '0 parcours demarre'
                      : '$done sur $total chapitres',
                  style: TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: TdcText.caption(context),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _resumeCourse(context, prov, course, chapter),
                child: Text(course == null ? 'Explorer' : 'Continuer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightChip(BuildContext context,
      {required IconData icon, required String label, required Color tone}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: TdcAdaptive.padding(context, 12),
        vertical: TdcAdaptive.padding(context, 10),
      ),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.sm,
        border: Border.all(color: TdcColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: TdcAdaptive.icon(context, 14), color: tone),
          SizedBox(width: TdcAdaptive.space(context, 8)),
          Text(
            label,
            style: TextStyle(
              color: TdcColors.textSecondary,
              fontSize: TdcText.caption(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileServicePanels(BuildContext context) {
    return Column(
      children: [
        _buildAIPanel(context),
        SizedBox(height: TdcAdaptive.space(context, TdcSpacing.md)),
        _buildGhostLinkPanel(context),
      ],
    );
  }

  Course? _preferredCourse(CoursesProvider prov) {
    if (prov.courses.isEmpty) return null;
    if (prov.currentCourse != null) return prov.currentCourse;
    for (final course in prov.courses) {
      if (prov.courseCompletedCount(course.id) < course.chapters.length) {
        return course;
      }
    }
    return prov.courses.first;
  }

  CourseChapter? _preferredChapter(CoursesProvider prov, Course? course) {
    if (course == null || course.chapters.isEmpty) return null;
    if (prov.currentCourseId == course.id && prov.currentChapter != null) {
      return prov.currentChapter;
    }
    for (final chapter in course.chapters) {
      final key = '${course.id}:${chapter.id}';
      if (!prov.completed.contains(key)) return chapter;
    }
    return course.chapters.first;
  }

  void _resumeCourse(BuildContext context, CoursesProvider prov, Course? course,
      CourseChapter? chapter) {
    if (course == null || chapter == null) {
      AppNavigator.pushNamed('/tools');
      return;
    }
    prov.selectChapter(course.id, chapter.id);
    AppNavigator.pushNamed('/chapter');
  }

  Widget _buildProgressBar(CoursesProvider prov) {
    return Container(
      padding: EdgeInsets.all(TdcAdaptive.padding(context, TdcSpacing.md)),
      decoration: BoxDecoration(
          color: TdcColors.surface,
          borderRadius: TdcRadius.lg,
          border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Progression globale',
                style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: TdcText.body(context))),
            Text('${(prov.overallProgress * 100).toInt()}%',
                style: TextStyle(
                    color: TdcColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: TdcText.h2(context))),
          ]),
          SizedBox(height: TdcAdaptive.space(context, 10)),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prov.overallProgress,
              minHeight: TdcAdaptive.space(context, 8),
              backgroundColor: TdcColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(TdcColors.accent),
            ),
          ),
          SizedBox(height: TdcAdaptive.space(context, 6)),
          Text(
              '${prov.completedCount} sur ${prov.totalChaptersCount} chapitres',
              style: TextStyle(
                  color: TdcColors.textMuted,
                  fontSize: TdcText.caption(context))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, CoursesProvider prov) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Icon(Icons.menu_book,
              color: TdcColors.textPrimary,
              size: TdcAdaptive.icon(context, 20)),
          SizedBox(width: TdcAdaptive.space(context, TdcSpacing.sm)),
          Text('Parcours informatiques',
              style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: TdcText.h2(context),
                  fontWeight: FontWeight.bold)),
          SizedBox(width: TdcAdaptive.space(context, TdcSpacing.sm)),
          IconButton(
            icon: Icon(Icons.refresh,
                size: TdcAdaptive.icon(context, 18),
                color: TdcColors.textSecondary),
            tooltip: 'Actualiser les modules externes',
            onPressed: () => prov.reload(),
          ),
        ]),
        Row(children: [
          SizedBox(
            width: TdcAdaptive.space(context, 120),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: prov.totalChaptersCount > 0
                    ? prov.completedCount / prov.totalChaptersCount
                    : 0.0,
                minHeight: TdcAdaptive.space(context, 5),
                backgroundColor: TdcColors.surfaceAlt,
                valueColor: const AlwaysStoppedAnimation(TdcColors.accent),
              ),
            ),
          ),
          SizedBox(width: TdcAdaptive.space(context, TdcSpacing.sm)),
          Text('${prov.completedCount}/${prov.totalChaptersCount}',
              style: TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: TdcText.label(context))),
        ]),
      ],
    );
  }

  Widget _buildCourseGrid(BuildContext context, CoursesProvider prov,
      {required int crossAxisCount}) {
    final courses = prov.courses;
    final double itemHeight = crossAxisCount == 1
        ? TdcAdaptive.space(context, 100)
        : TdcAdaptive.space(context, 195);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: itemHeight,
        crossAxisSpacing: TdcAdaptive.space(context, 12),
        mainAxisSpacing: TdcAdaptive.space(context, 12),
      ),
      itemCount: courses.length,
      itemBuilder: (context, i) =>
          _buildCourseCard(context, courses[i], i, prov, crossAxisCount == 1)
              .animate(delay: Duration(milliseconds: 80 + (i * 42)))
              .fadeIn(duration: 450.ms, curve: Curves.easeOutCubic)
              .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 480.ms,
                  curve: Curves.easeOutCubic)
              .scale(
                  begin: const Offset(0.92, 0.92),
                  duration: 480.ms,
                  curve: Curves.easeOutBack),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course, int index,
      CoursesProvider prov, bool horizontal) {
    final color = _levelColor(course.level);
    final done = prov.courseCompletedCount(course.id);
    final total = course.chapters.length;
    final progress = total > 0 ? done / total : 0.0;
    final icon = _courseIcon(course);
    final iconColor = _courseIconColor(course);
    final isImported = course.keywords.contains('EXTERNAL');

    return TdcCard(
      onTap: () => _openCourseSheet(context, course, prov),
      padding: EdgeInsets.all(TdcAdaptive.padding(context, TdcSpacing.md)),
      child: horizontal
          ? _buildHorizontalCard(
              context,
              course,
              icon,
              iconColor,
              color,
              done,
              total,
              progress,
              isImported)
          : _buildVerticalCard(
              context,
              course,
              icon,
              iconColor,
              color,
              done,
              total,
              progress,
              isImported),
    );
  }

  Widget _buildVerticalCard(BuildContext context, Course course, IconData icon,
      Color iconColor, Color color, int done, int total, double progress, bool isImported) {
    final sourceColor = isImported ? TdcColors.coral : TdcColors.info;
    final sourceIcon = isImported ? Icons.file_upload_outlined : Icons.verified_outlined;
    final sourceLabel = isImported ? 'Importé (local)' : 'Officiel';
    final sourceTooltip = isImported
        ? 'Cours importé depuis un fichier local. T2DECODE n’en revendique pas la paternité.'
        : 'Cours fourni avec T2DECODE.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(TdcAdaptive.padding(context, 10)),
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: TdcRadius.sm),
              child: Icon(icon,
                  color: iconColor, size: TdcAdaptive.icon(context, 22)),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (done == total && total > 0) ...[
                  const TdcStatusBadge(
                      label: 'Terminé',
                      color: TdcColors.success,
                      icon: Icons.check_circle),
                  const SizedBox(width: 8),
                ],
                Tooltip(
                  message: sourceTooltip,
                  child: TdcStatusBadge(
                    label: sourceLabel,
                    color: sourceColor,
                    icon: sourceIcon,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        Text(course.title,
            style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: TdcText.body(context),
                fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        SizedBox(height: TdcAdaptive.space(context, 5)),
        Text('${course.category.toUpperCase()} · $total chapitres',
            style: TextStyle(
                color: TdcColors.textMuted,
                fontSize: TdcText.caption(context),
                letterSpacing: 0.3)),
        SizedBox(height: TdcAdaptive.space(context, 8)),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: TdcAdaptive.space(context, 3),
            backgroundColor: TdcColors.surfaceAlt,
            valueColor: AlwaysStoppedAnimation(
                done > 0 ? TdcColors.success : TdcColors.surfaceAlt),
          ),
        ),
        SizedBox(height: TdcAdaptive.padding(context, TdcSpacing.sm)),
        Row(children: [
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: TdcAdaptive.padding(context, 7),
                vertical: TdcAdaptive.padding(context, 3)),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5)),
            child: Text(_levelLabel(course.level),
                style: TextStyle(
                    color: color,
                    fontSize: TdcText.label(context),
                    fontWeight: FontWeight.w600)),
          ),
          SizedBox(width: TdcAdaptive.space(context, TdcSpacing.sm)),
          Text(course.duration,
              style: TextStyle(
                  color: TdcColors.textMuted,
                  fontSize: TdcText.label(context))),
          const Spacer(),
          Icon(Icons.chevron_right,
              color: TdcColors.textMuted, size: TdcAdaptive.icon(context, 16)),
        ]),
      ],
    );
  }

  Widget _buildHorizontalCard(
      BuildContext context,
      Course course,
      IconData icon,
      Color iconColor,
      Color color,
      int done,
      int total,
      double progress,
      bool isImported) {
    final sourceColor = isImported ? TdcColors.coral : TdcColors.info;
    final sourceIcon = isImported ? Icons.file_upload_outlined : Icons.verified_outlined;
    final sourceTooltip = isImported
        ? 'Cours importé depuis un fichier local. T2DECODE n’en revendique pas la paternité.'
        : 'Cours fourni avec T2DECODE.';

    return Row(
      children: [
        Container(
          width: TdcAdaptive.icon(context, 52),
          height: TdcAdaptive.icon(context, 52),
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: TdcRadius.md),
          child:
              Icon(icon, color: iconColor, size: TdcAdaptive.icon(context, 26)),
        ),
        SizedBox(width: TdcAdaptive.space(context, TdcSpacing.md)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(course.title,
                  style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: TdcText.body(context),
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              SizedBox(height: TdcAdaptive.space(context, 4)),
              Text('${course.category.toUpperCase()} · $total chapitres',
                  style: TextStyle(
                      color: TdcColors.textMuted,
                      fontSize: TdcText.caption(context))),
              SizedBox(height: TdcAdaptive.space(context, 6)),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: TdcAdaptive.space(context, 3),
                  backgroundColor: TdcColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation(
                      done > 0 ? TdcColors.success : TdcColors.surfaceAlt),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: TdcAdaptive.space(context, TdcSpacing.sm)),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: TdcAdaptive.padding(context, 7),
                vertical: TdcAdaptive.padding(context, 3)),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5)),
            child: Text(_levelLabel(course.level),
                style: TextStyle(
                    color: color,
                    fontSize: TdcText.label(context),
                    fontWeight: FontWeight.w600)),
          ),
          SizedBox(height: TdcAdaptive.space(context, 6)),
          Tooltip(
            message: sourceTooltip,
            child: Icon(sourceIcon,
                size: TdcAdaptive.icon(context, 16), color: sourceColor),
          ),
          SizedBox(height: TdcAdaptive.space(context, 6)),
          Icon(Icons.chevron_right,
              color: TdcColors.textMuted, size: TdcAdaptive.icon(context, 18)),
        ]),
      ],
    );
  }

  Widget _buildMobileQuickActions(BuildContext context) {
    final actions = _getTools(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Outils & Services',
            style: TextStyle(
                color: TdcColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: TdcText.h3(context))),
        SizedBox(height: TdcAdaptive.space(context, TdcSpacing.md)),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: TdcAdaptive.space(context, 8),
          mainAxisSpacing: TdcAdaptive.space(context, 8),
          childAspectRatio: isSmall ? 2.5 : 2.8,
          children: actions.map((t) => _buildToolButton(context, t)).toList(),
        ),
      ],
    );
  }

  void _openCourseSheet(
      BuildContext context, Course course, CoursesProvider prov) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TdcColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(TdcAdaptive.space(context, 20)))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: EdgeInsets.all(TdcAdaptive.padding(context, TdcSpacing.lg)),
          children: [
            Center(
                child: Container(
                    width: TdcAdaptive.space(context, 40),
                    height: TdcAdaptive.space(context, 4),
                    decoration: BoxDecoration(
                        color: TdcColors.border,
                        borderRadius: BorderRadius.circular(2)))),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.md)),
            Text(course.title,
                style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: TdcText.h2(context),
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Tooltip(
                message: course.keywords.contains('EXTERNAL')
                    ? 'Cours importé depuis un fichier local. T2DECODE n’en revendique pas la paternité.'
                    : 'Cours fourni avec T2DECODE.',
                child: TdcStatusBadge(
                  label: course.keywords.contains('EXTERNAL') ? 'Importé (local)' : 'Officiel',
                  color: course.keywords.contains('EXTERNAL') ? TdcColors.coral : TdcColors.info,
                  icon: course.keywords.contains('EXTERNAL')
                      ? Icons.file_upload_outlined
                      : Icons.verified_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  course.keywords.contains('EXTERNAL')
                      ? 'Ajouté par vous (import).'
                      : 'Créé et fourni par T2DECODE.',
                  style: TextStyle(
                      color: TdcColors.textMuted,
                      fontSize: TdcText.bodySmall(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            SizedBox(height: 6),
            Text(course.description,
                style: TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: TdcText.bodySmall(context),
                    height: 1.5)),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),
            const Divider(color: TdcColors.border),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.sm)),
            ...course.chapters.asMap().entries.map((e) {
              final ch = e.value;
              final isDone = prov.completed.contains('${course.id}:${ch.id}');
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 2),
                leading: Container(
                  width: TdcAdaptive.icon(context, 32),
                  height: TdcAdaptive.icon(context, 32),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? TdcColors.success.withValues(alpha: 0.15)
                          : TdcColors.surfaceAlt,
                      border: Border.all(
                          color:
                              isDone ? TdcColors.success : TdcColors.border)),
                  child: Center(
                    child: isDone
                        ? Icon(Icons.check,
                            size: TdcAdaptive.icon(context, 15),
                            color: TdcColors.success)
                        : Text('${e.key + 1}',
                            style: TextStyle(
                                color: TdcColors.textMuted,
                                fontSize: TdcText.label(context),
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                title: Text(ch.title,
                    style: TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: TdcText.body(context))),
                subtitle: Text(ch.duration,
                    style: TextStyle(
                        color: TdcColors.textMuted,
                        fontSize: TdcText.bodySmall(context))),
                trailing: Icon(Icons.play_arrow,
                    color: TdcColors.accent,
                    size: TdcAdaptive.icon(context, 20)),
                onTap: () {
                  prov.selectChapter(course.id, ch.id);
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/chapter');
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAIPanel(BuildContext context) {
    final running = _aiStatus?.running ?? false;
    final models = _aiStatus?.models ?? [];
    return Container(
      padding: EdgeInsets.all(TdcAdaptive.padding(context, TdcSpacing.md)),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.lg,
        border: Border.all(
            color: running
                ? TdcColors.info.withValues(alpha: 0.35)
                : TdcColors.border),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.smart_toy,
                size: TdcAdaptive.icon(context, 16),
                color: running ? TdcColors.info : TdcColors.textMuted),
            SizedBox(width: TdcAdaptive.space(context, 8)),
            Text('Tuteur IA',
                style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: TdcText.body(context))),
            const Spacer(),
            if (running)
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: TdcColors.info),
              ),
          ]),
          SizedBox(height: TdcAdaptive.space(context, TdcSpacing.sm)),
          if (running && models.isNotEmpty) ...[
            ...models.take(3).map((m) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [
                    const Icon(Icons.circle, size: 6, color: TdcColors.info),
                    const SizedBox(width: 6),
                    Text(m.split(':').first,
                        style: TextStyle(
                            color: TdcColors.textSecondary,
                            fontSize: TdcText.bodySmall(context),
                            fontFamily: 'monospace')),
                  ]),
                )),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.sm)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/ai'),
                icon: Icon(Icons.chat, size: TdcAdaptive.icon(context, 14)),
                label: Text('Ouvrir le Chat',
                    style: TextStyle(fontSize: TdcText.button(context))),
                style: ElevatedButton.styleFrom(
                    backgroundColor: TdcColors.accent,
                    padding: EdgeInsets.symmetric(
                        vertical: TdcAdaptive.padding(context, 10))),
              ),
            ),
          ],
          if (!running) ...[
            Text('Assistant IA local optionnel.',
                style: TextStyle(
                    color: TdcColors.textMuted,
                    fontSize: TdcText.caption(context),
                    height: 1.4)),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.sm)),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/ai'),
                icon: Icon(Icons.settings, size: TdcAdaptive.icon(context, 14)),
                label: Text('Configurer',
                    style: TextStyle(fontSize: TdcText.button(context))),
                style: OutlinedButton.styleFrom(
                    foregroundColor: TdcColors.textSecondary,
                    side: const BorderSide(color: TdcColors.border),
                    padding: EdgeInsets.symmetric(
                        vertical: TdcAdaptive.padding(context, 10))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGhostLinkPanel(BuildContext context) {
    return Consumer<GhostLinkService>(
      builder: (context, gl, _) {
        final active = gl.isRunning;
        final peers = gl.peers.length;
        return Container(
          padding: EdgeInsets.all(TdcAdaptive.padding(context, TdcSpacing.md)),
          decoration: BoxDecoration(
            color: TdcColors.surface,
            borderRadius: TdcRadius.lg,
            border: Border.all(
                color: active
                    ? TdcColors.accent.withValues(alpha: 0.3)
                    : TdcColors.border),
            boxShadow: const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.link,
                    size: TdcAdaptive.icon(context, 16),
                    color: active ? TdcColors.accent : TdcColors.textMuted),
                SizedBox(width: TdcAdaptive.space(context, 8)),
                Text('Ghost Link',
                    style: TextStyle(
                        color: TdcColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: TdcText.body(context))),
                const Spacer(),
                if (active)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: TdcColors.accent),
                  ),
              ]),
              SizedBox(height: TdcAdaptive.space(context, TdcSpacing.sm)),
              if (active) ...[
                Row(children: [
                  Icon(Icons.people, size: 12, color: TdcColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    peers == 0
                        ? 'En attente de pairs…'
                        : '$peers pair${peers > 1 ? 's' : ''} connecté${peers > 1 ? 's' : ''}',
                    style: TextStyle(
                        color:
                            peers > 0 ? TdcColors.accent : TdcColors.textMuted,
                        fontSize: TdcText.caption(context)),
                  ),
                ]),
                SizedBox(height: TdcAdaptive.space(context, TdcSpacing.sm)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/ghost-link'),
                    icon: Icon(Icons.chat_bubble_outline,
                        size: TdcAdaptive.icon(context, 14)),
                    label: Text('Ouvrir le Chat',
                        style: TextStyle(fontSize: TdcText.button(context))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TdcColors.accent,
                      padding: EdgeInsets.symmetric(
                          vertical: TdcAdaptive.padding(context, 10)),
                    ),
                  ),
                ),
              ],
              if (!active) ...[
                Text('Chat P2P chiffré sur votre réseau local.',
                    style: TextStyle(
                        color: TdcColors.textMuted,
                        fontSize: TdcText.caption(context),
                        height: 1.4)),
                SizedBox(height: TdcAdaptive.space(context, TdcSpacing.sm)),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/ghost-link'),
                    icon: Icon(Icons.wifi_tethering,
                        size: TdcAdaptive.icon(context, 14)),
                    label: Text('Démarrer',
                        style: TextStyle(fontSize: TdcText.button(context))),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TdcColors.accent,
                      side: const BorderSide(color: TdcColors.accent),
                      padding: EdgeInsets.symmetric(
                          vertical: TdcAdaptive.padding(context, 10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolsPanel(BuildContext context) {
    final tools = _getTools(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(TdcAdaptive.padding(context, 6)),
            decoration: BoxDecoration(
                color: TdcColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.auto_awesome,
                size: TdcAdaptive.icon(context, 16), color: TdcColors.accent),
          ),
          SizedBox(width: TdcAdaptive.space(context, 10)),
          Text('Outils & Services',
              style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: TdcText.h3(context),
                  letterSpacing: 0.2)),
        ]),
        SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tools.length,
          separatorBuilder: (_, __) =>
              SizedBox(height: TdcAdaptive.space(context, 12)),
          itemBuilder: (context, i) => _buildToolButton(context, tools[i]),
        ),
      ],
    );
  }

  List<_ToolItem> _getTools(BuildContext context) {
    return [
      _ToolItem(
          Icons.map,
          'Roadmap',
          'Parcours & objectifs',
          const Color(0xFF8DA2A6),
          () => Navigator.pushNamed(context, '/roadmap')),
      _ToolItem(
          Icons.build,
          'Outils',
          'Diagnostic & Réseau',
          const Color(0xFF8B9AA3),
          () => Navigator.pushNamed(context, '/tools')),
      _ToolItem(
          Icons.network_check,
          'NetKit',
          'Outils Réseau Avançé',
          const Color(0xFF9B8E81),
          () => Navigator.pushNamed(context, '/netkit')),
      _ToolItem(
          Icons.description,
          'Cheat Sheets',
          'Mémos & commandes',
          const Color(0xFF8A98A1),
          () => Navigator.pushNamed(context, '/cheat-sheets')),
      _ToolItem(Icons.smart_toy, 'Chat IA', 'Posez vos questions',
          const Color(0xFF8C8196), () => Navigator.pushNamed(context, '/ai')),
      _ToolItem(
          Icons.analytics,
          'Diagnostic',
          'État du système local',
          const Color(0xFF7C92A8),
          () => Navigator.pushNamed(context, '/dashboard')),
      _ToolItem(
          Icons.settings,
          'Config IA',
          'Gérer Ollama',
          const Color(0xFFB39A76),
          () => Navigator.pushNamed(context, '/ai-config')),
    ];
  }

  Widget _buildToolButton(BuildContext context, _ToolItem tool) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tool.onTap,
        borderRadius: TdcRadius.md,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(
              TdcAdaptive.padding(context, isMobile ? 8 : TdcSpacing.md)),
          decoration: BoxDecoration(
            color: TdcColors.surfaceAlt,
            borderRadius: TdcRadius.md,
            border: Border.all(color: TdcColors.border),
          ),
          child: Row(children: [
            Container(
              width: TdcAdaptive.icon(context, isMobile ? 32 : 44),
              height: TdcAdaptive.icon(context, isMobile ? 32 : 44),
              decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: 0.12),
                  borderRadius: TdcRadius.sm,
                  border: Border.all(color: tool.color.withValues(alpha: 0.2))),
              child: Icon(tool.icon,
                  color: tool.color,
                  size: TdcAdaptive.icon(context, isMobile ? 16 : 22)),
            ),
            SizedBox(
                width:
                    TdcAdaptive.space(context, isMobile ? 8 : TdcSpacing.md)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tool.label,
                      style: TextStyle(
                          color: TdcColors.textPrimary,
                          fontSize: TdcText.body(context),
                          fontWeight: FontWeight.bold),
                      maxLines: 1),
                  if (!isMobile) ...[
                    const SizedBox(height: 2),
                    Text(tool.sub,
                        style: TextStyle(
                            color: TdcColors.textMuted,
                            fontSize: TdcText.caption(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: TdcColors.textMuted.withValues(alpha: 0.5),
                size: TdcAdaptive.icon(context, 16)),
          ]),
        ),
      ),
    );
  }

  Widget _buildProgressPanel(CoursesProvider prov) {
    return Container(
      padding: EdgeInsets.all(TdcAdaptive.padding(context, TdcSpacing.md)),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.lg,
        border: Border.all(color: TdcColors.border),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF95A7BB).withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(children: [
        Row(children: [
          Icon(Icons.bar_chart,
              size: TdcAdaptive.icon(context, 15), color: TdcColors.accent),
          SizedBox(width: TdcAdaptive.space(context, 7)),
          Text('Ma progression',
              style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: TdcText.body(context))),
        ]),
        SizedBox(height: TdcAdaptive.space(context, TdcSpacing.md)),
        Text('${(prov.overallProgress * 100).toInt()}%',
            style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: TdcText.scale(context, 48),
                fontWeight: FontWeight.bold)),
        Text('${prov.completedCount} sur ${prov.totalChaptersCount} chapitres',
            style: TextStyle(
                color: TdcColors.textSecondary,
                fontSize: TdcText.caption(context))),
        SizedBox(height: TdcAdaptive.space(context, TdcSpacing.md)),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: prov.overallProgress,
              minHeight: TdcAdaptive.space(context, 8),
              backgroundColor: TdcColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(TdcColors.accent)),
        ),
        SizedBox(height: TdcAdaptive.space(context, TdcSpacing.sm)),
        Text(
            prov.completedCount == 0
                ? 'Commencez votre premier cours !'
                : 'Continuez votre apprentissage',
            style: TextStyle(
                color: TdcColors.textMuted, fontSize: TdcText.label(context))),
      ]),
    );
  }

  Color _levelColor(String l) {
    switch (l.toLowerCase()) {
      case 'beginner':
        return TdcColors.levelBeginner;
      case 'intermediate':
        return TdcColors.levelIntermediate;
      case 'advanced':
        return TdcColors.levelAdvanced;
      default:
        return TdcColors.textMuted;
    }
  }

  String _levelLabel(String l) {
    switch (l.toLowerCase()) {
      case 'beginner':
        return 'Débutant';
      case 'intermediate':
        return 'Intermédiaire';
      case 'advanced':
        return 'Avancé';
      default:
        return l;
    }
  }

  IconData _courseIcon(Course course) {
    final cat = course.category.toLowerCase();
    final title = course.title.toLowerCase();
    if (cat.contains('linux') ||
        title.contains('linux') ||
        title.contains('bash')) {
      return Icons.terminal;
    }
    if (cat.contains('docker') || title.contains('docker')) {
      return Icons.view_in_ar;
    }
    if (cat.contains('network') ||
        title.contains('réseau') ||
        title.contains('cisco')) {
      return Icons.hub;
    }
    if (cat.contains('security') ||
        title.contains('sécurité') ||
        title.contains('hack')) {
      return Icons.security;
    }
    if (cat.contains('web') || title.contains('html') || title.contains('css')) {
      return Icons.language;
    }
    if (cat.contains('python') || title.contains('python')) {
      return Icons.code;
    }
    if (cat.contains('database') || title.contains('sql')) {
      return Icons.storage;
    }
    if (cat.contains('git') || title.contains('git')) {
      return Icons.merge_type;
    }
    if (cat.contains('cloud') ||
        title.contains('aws') ||
        title.contains('kubernetes')) {
      return Icons.cloud;
    }
    if (cat.contains('ai') ||
        cat.contains('ia') ||
        title.contains('intelligence')) {
      return Icons.smart_toy;
    }
    return Icons.school;
  }

  Color _courseIconColor(Course course) {
    final cat = course.category.toLowerCase();
    final title = course.title.toLowerCase();
    if (cat.contains('linux') ||
        title.contains('linux') ||
        title.contains('bash')) {
      return const Color(0xFFB39A76);
    }
    if (cat.contains('docker') || title.contains('docker')) {
      return const Color(0xFF8A98A1);
    }
    if (cat.contains('network') ||
        title.contains('réseau') ||
        title.contains('cisco')) {
      return const Color(0xFF8DA2A6);
    }
    if (cat.contains('security') ||
        title.contains('sécurité') ||
        title.contains('hack')) {
      return const Color(0xFF9A7C7A);
    }
    if (cat.contains('web') || title.contains('html') || title.contains('css')) {
      return const Color(0xFF9B8E81);
    }
    if (title.contains('javascript') || title.contains('react')) {
      return const Color(0xFFB09A7A);
    }
    if (cat.contains('python') || title.contains('python')) {
      return const Color(0xFF7C92A8);
    }
    if (cat.contains('database') || title.contains('sql')) {
      return const Color(0xFF8C8196);
    }
    if (cat.contains('git') || title.contains('git')) {
      return const Color(0xFFB07F76);
    }
    if (cat.contains('cloud') || title.contains('kubernetes')) {
      return const Color(0xFF7A8EA1);
    }
    if (cat.contains('ai') || cat.contains('ia')) {
      return const Color(0xFF8C8196);
    }
    return TdcColors.accent;
  }
}

class _ToolItem {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _ToolItem(this.icon, this.label, this.sub, this.color, this.onTap);
}
