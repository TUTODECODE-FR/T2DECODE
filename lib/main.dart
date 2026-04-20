// ============================================================
// main.dart — Point d'entrée de TUTODECODE
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';

// Screens
import 'features/home/screens/home_screen.dart';
import 'features/courses/screens/chapter_screen.dart';
import 'features/courses/screens/cheat_sheet_screen.dart';
import 'features/courses/screens/cheat_sheet_detail_screen.dart';
import 'features/tools/screens/toolbox_screen.dart';
import 'features/tools/screens/ip_calc_screen.dart';
import 'features/tools/screens/script_generator_screen.dart';
import 'features/tools/screens/hardware_screen.dart';
import 'features/tools/screens/survival_screen.dart';
import 'features/tools/screens/glossary_screen.dart';
import 'features/tools/screens/safe_tools_screen.dart';
import 'features/tools/screens/data_converter_screen.dart';
import 'features/tools/screens/base64_tool_screen.dart';
import 'features/tools/screens/hash_tool_screen.dart';
import 'features/tools/screens/chmod_tool_screen.dart';
import 'features/tools/screens/password_tool_screen.dart';
import 'features/tools/screens/json_tool_screen.dart';
import 'features/tools/screens/ascii_tool_screen.dart';
import 'features/tools/screens/raid_tool_screen.dart';
import 'features/tools/screens/http_status_tool_screen.dart';
import 'features/tools/screens/port_ref_tool_screen.dart';
import 'features/tools/screens/bandwidth_tool_screen.dart';
import 'features/tools/screens/cron_tool_screen.dart';
import 'features/tools/screens/syslog_tool_screen.dart';
import 'features/tools/screens/archive_tool_screen.dart';
import 'features/tools/screens/ssh_tool_screen.dart';
import 'features/tools/screens/dns_ref_tool_screen.dart';
import 'features/tools/screens/anonymity_tool_screen.dart';
import 'features/ghost_ai/screens/ai_chat_screen.dart';
import 'features/ghost_ai/screens/ai_config_screen.dart';
import 'features/ghost_ai/screens/ai_tutor_screen.dart';
import 'features/ghost_ai/providers/ai_tutor_provider.dart';
import 'features/netkit/screens/netkit_screen.dart';
import 'features/home/screens/dashboard_screen.dart';

import 'features/roadmap/screens/roadmap_screen.dart';
import 'features/lab/screens/professional_lab_screen.dart';
import 'features/admin/screens/admin_screen.dart';
import 'features/legal/screens/legal_screen.dart';
import 'features/settings/screens/settings_screen.dart'; // To be moved later if needed
import 'features/ghost_link/screens/ghost_link_screen.dart';
import 'features/ghost_link/screens/ghost_chat_screen.dart';
import 'features/ghost_link/service/ghost_link_service.dart';

// Providers
import 'features/courses/providers/courses_provider.dart';
import 'widgets/app_shell.dart';
import 'core/providers/shell_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/search_provider.dart';

// Theme & Navigation
import 'core/theme/app_theme.dart';
import 'core/navigation/nav_keys.dart';
import 'core/security/identity_verification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Vérification d'intégrité des assets au démarrage (100% local, aucun réseau).
  await IdentityVerificationService.verifyIdentity();
  runApp(const TutoDeCodeApp());
}

class TutoDeCodeApp extends StatelessWidget {
  const TutoDeCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CoursesProvider()),
        ChangeNotifierProvider(create: (_) => ShellProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => GhostLinkService()),
        ChangeNotifierProvider(create: (_) => AiTutorProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'T2CODE',
          debugShowCheckedModeBanner: false,
          theme: buildAppLightTheme(),
          darkTheme: buildAppTheme(),
          themeMode: settings.themeMode,
          navigatorKey: AppNavigator.key,
          navigatorObservers: [AppNavigator.observer],
          initialRoute: '/',
          builder: (context, child) => Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => AppShell(child: child!),
              ),
            ],
          ),
          onGenerateRoute: (settings) {
            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (context, animation, secondaryAnimation) {
                switch (settings.name) {
                  case '/':                     return HomeScreen();
                  case '/chapter':              return ChapterScreen();
                  case '/ai':                   return const AIChatScreen();
                  case '/ai-tutor':             return const AiTutorScreen();
                  case '/ai-config':            return const AIConfigScreen();
                  case '/netkit':               return const NetKitScreen();
                  case '/roadmap':              return RoadmapScreen();
                  case '/lab':                  return const ProfessionalLabScreen();
                  case '/cheat-sheets':         return CheatSheetScreen();
                  case '/cheat-sheets/details':
                    final entry = settings.arguments as CheatSheetEntry;
                    return CheatSheetDetailScreen(entry: entry);
                  case '/tools':                return const ToolboxScreen();
                  case '/tools/safe-tools':     return const SafeToolsScreen();
                  case '/tools/ip-calc':        return const IPCalcScreen();
                  case '/tools/scripts':        return const ScriptGeneratorScreen();
                  case '/tools/hardware':       return const HardwareScreen();
                  case '/tools/survival':       return const SurvivalScreen();
                  case '/tools/glossary':       return const GlossaryScreen();
                  case '/tools/password-gen':   return const PasswordToolScreen();
                  case '/tools/data-converter': return const DataConverterScreen();
                  case '/tools/base64':         return const Base64ToolScreen();
                  case '/tools/hash':           return const HashToolScreen();
                  case '/tools/chmod':          return const ChmodToolScreen();
                  case '/tools/json':           return const JsonToolScreen();
                  case '/tools/ascii':          return const AsciiToolScreen();
                  case '/tools/raid':           return const RaidToolScreen();
                  case '/tools/http-status':    return const HttpStatusToolScreen();
                  case '/tools/ports':          return const PortRefToolScreen();
                  case '/tools/bandwidth':      return const BandwidthToolScreen();
                  case '/tools/cron':           return const CronToolScreen();
                  case '/tools/syslog':         return const SyslogToolScreen();
                  case '/tools/archive':        return const ArchiveToolScreen();
                  case '/tools/ssh':            return const SshToolScreen();
                  case '/tools/dns':            return const DnsRefToolScreen();
                  case '/tools/anonymity':      return const AnonymityToolScreen();
                  case '/dashboard':            return const DashboardScreen();

                  case '/admin':                return AdminScreen();
                  case '/legal':                return LegalScreen();
                  case '/settings':             return const SettingsScreen();
                  case '/ghost-link':            return const GhostLinkScreen();
                  case '/ghost-link/chat':
                    final peer = settings.arguments as GhostPeer;
                    return GhostChatScreen(peer: peer);
                  default:                      return HomeScreen();
                }
              },
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeThroughTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  fillColor: TdcColors.bg,
                  child: child,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
