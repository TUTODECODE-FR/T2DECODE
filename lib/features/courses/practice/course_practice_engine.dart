import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';
import 'package:tutodecode/features/courses/practice/widgets/mini_dns_sandbox.dart';
import 'package:tutodecode/features/courses/practice/widgets/mini_sql_injection_sandbox.dart';
import 'package:tutodecode/features/courses/practice/widgets/practice_flow.dart';

class CoursePracticeLink {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final List<PracticeNode> flow;
  final String? toolRoute;
  final Map<String, dynamic>? labArgs;
  final Widget? embeddedSandbox;

  const CoursePracticeLink({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.flow,
    this.toolRoute,
    this.labArgs,
    this.embeddedSandbox,
  });
}

class CoursePracticeEngine {
  static List<CoursePracticeLink> recommend(Course course, CourseChapter chapter) {
    switch (course.category) {
      case 'network':
        return [
          CoursePracticeLink(
            title: 'Diagnostiquer un réseau (virtuel)',
            subtitle: 'Résolution DNS → connexion → latence',
            icon: Icons.lan,
            tint: TdcColors.network,
            labArgs: const {'sim': 'network'},
            toolRoute: '/tools/dns',
            flow: const [
              PracticeNode(icon: Icons.laptop_mac, label: 'Client', color: TdcColors.network),
              PracticeNode(icon: Icons.dns, label: 'DNS', color: TdcColors.info),
              PracticeNode(icon: Icons.public, label: 'Serveur', color: TdcColors.network),
            ],
            embeddedSandbox: const MiniDnsSandbox(),
          ),
        ];

      case 'security':
        return [
          CoursePracticeLink(
            title: 'Injection SQL (virtuel)',
            subtitle: 'Comprendre le “pourquoi” avant de tester',
            icon: Icons.shield_outlined,
            tint: TdcColors.security,
            labArgs: const {'sim': 'security'},
            flow: const [
              PracticeNode(icon: Icons.person, label: 'Attaquant', color: TdcColors.security),
              PracticeNode(icon: Icons.web, label: 'Web app', color: TdcColors.warning),
              PracticeNode(icon: Icons.storage, label: 'Base', color: TdcColors.security),
            ],
            embeddedSandbox: const MiniSqlInjectionSandbox(),
          ),
          CoursePracticeLink(
            title: 'Préparer un lab CTF (offline)',
            subtitle: 'Vulnérable, mais isolé et contrôlé',
            icon: Icons.flag_outlined,
            tint: TdcColors.warning,
            labArgs: const {'sim': 'ctf_prep'},
            flow: const [
              PracticeNode(icon: Icons.computer, label: 'VM Attaque', color: TdcColors.warning),
              PracticeNode(icon: Icons.router, label: 'Réseau isolé', color: TdcColors.info),
              PracticeNode(icon: Icons.shield, label: 'VM Logs', color: TdcColors.security),
            ],
          ),
        ];

      case 'linux':
        return [
          CoursePracticeLink(
            title: 'Linux : permissions & chemins (virtuel)',
            subtitle: 'Comprendre chmod/chown et l’impact',
            icon: Icons.terminal,
            tint: TdcColors.system,
            labArgs: const {'sim': 'linux'},
            toolRoute: '/tools/chmod',
            flow: const [
              PracticeNode(icon: Icons.person, label: 'Utilisateur', color: TdcColors.system),
              PracticeNode(icon: Icons.folder, label: 'Fichiers', color: TdcColors.info),
              PracticeNode(icon: Icons.lock_outline, label: 'Permissions', color: TdcColors.system),
            ],
          ),
        ];

      case 'sql':
        return [
          CoursePracticeLink(
            title: 'SQL : requête & impact (virtuel)',
            subtitle: 'Du SELECT aux erreurs communes',
            icon: Icons.storage_outlined,
            tint: TdcColors.warning,
            labArgs: const {'sim': 'security'},
            flow: const [
              PracticeNode(icon: Icons.code, label: 'Entrée', color: TdcColors.warning),
              PracticeNode(icon: Icons.storage, label: 'SQL', color: TdcColors.security),
              PracticeNode(icon: Icons.receipt_long, label: 'Résultat', color: TdcColors.info),
            ],
          ),
        ];

      case 'devops':
        return [
          CoursePracticeLink(
            title: 'DevOps : pipeline (virtuel)',
            subtitle: 'Build → package → déploiement local',
            icon: Icons.cloud_outlined,
            tint: TdcColors.cloud,
            labArgs: const {'sim': 'cloud'},
            flow: const [
              PracticeNode(icon: Icons.build, label: 'Build', color: TdcColors.cloud),
              PracticeNode(icon: Icons.inventory_2, label: 'Artefact', color: TdcColors.info),
              PracticeNode(icon: Icons.rocket_launch, label: 'Déploiement', color: TdcColors.cloud),
            ],
          ),
        ];

      case 'web':
      case 'javascript':
        return [
          CoursePracticeLink(
            title: 'Web : requête HTTP (virtuel)',
            subtitle: 'Statuts, latence, erreurs',
            icon: Icons.public,
            tint: TdcColors.info,
            toolRoute: '/tools/http-status',
            labArgs: const {'sim': 'theory'},
            flow: const [
              PracticeNode(icon: Icons.phone_iphone, label: 'Client', color: TdcColors.info),
              PracticeNode(icon: Icons.http, label: 'HTTP', color: TdcColors.warning),
              PracticeNode(icon: Icons.dns, label: 'DNS', color: TdcColors.info),
            ],
          ),
        ];

      case 'python':
      case 'programming':
      default:
        return [
          CoursePracticeLink(
            title: 'Réviser avec une simulation',
            subtitle: 'Rejouer le concept au lieu de juste lire',
            icon: Icons.science_outlined,
            tint: TdcColors.accent,
            labArgs: const {'sim': 'algorithms'},
            flow: const [
              PracticeNode(icon: Icons.account_tree, label: 'Algorithme', color: TdcColors.accent),
              PracticeNode(icon: Icons.memory, label: 'États', color: TdcColors.info),
              PracticeNode(icon: Icons.check_circle_outline, label: 'Résultat', color: TdcColors.success),
            ],
          ),
        ];
    }
  }
}

