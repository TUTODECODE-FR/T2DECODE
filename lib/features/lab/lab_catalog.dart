import 'package:flutter/material.dart';
import 'package:tutodecode/features/lab/simulators/algorithms_simulator.dart';
import 'package:tutodecode/features/lab/simulators/cloud_simulator.dart';
import 'package:tutodecode/features/lab/simulators/cryptography_simulator.dart';
import 'package:tutodecode/features/lab/simulators/ctf_prep_simulator.dart';
import 'package:tutodecode/features/lab/simulators/how_internet_works_simulator.dart';
import 'package:tutodecode/features/lab/simulators/linux_simulator.dart';
import 'package:tutodecode/features/lab/simulators/network_simulator.dart';
import 'package:tutodecode/features/lab/simulators/security_simulator.dart';
import 'package:tutodecode/features/lab/simulators/system_simulator.dart';

class LabCatalogEntry {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget Function() build;
  final bool hasOwnHeader;

  const LabCatalogEntry({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.build,
    this.hasOwnHeader = false,
  });
}

final List<LabCatalogEntry> labCatalog = <LabCatalogEntry>[
  LabCatalogEntry(
    id: 'network',
    label: 'Reseau',
    subtitle: 'Ping · Scan · Traceroute',
    icon: Icons.lan,
    color: Colors.blue,
    hasOwnHeader: true,
    build: () => const NetworkSimulator(),
  ),
  LabCatalogEntry(
    id: 'security',
    label: 'Securite',
    subtitle: 'Attaques · Defense · CTF',
    icon: Icons.shield,
    color: Colors.red,
    hasOwnHeader: true,
    build: () => const SecuritySimulator(),
  ),
  LabCatalogEntry(
    id: 'ctf_prep',
    label: 'CTF Prep',
    subtitle: 'Offline · Vulnérable · Contrôlé',
    icon: Icons.flag,
    color: Colors.yellow,
    build: () => const CtfPrepSimulator(),
  ),
  LabCatalogEntry(
    id: 'system',
    label: 'Systeme',
    subtitle: 'CPU · RAM · Processus',
    icon: Icons.memory,
    color: Colors.orange,
    hasOwnHeader: true,
    build: () => const SystemSimulator(),
  ),
  LabCatalogEntry(
    id: 'cloud',
    label: 'Cloud',
    subtitle: 'Conteneurs · K8s · CI/CD',
    icon: Icons.cloud,
    color: Colors.cyan,
    hasOwnHeader: true,
    build: () => const CloudSimulator(),
  ),
  LabCatalogEntry(
    id: 'crypto',
    label: 'Cryptographie',
    subtitle: 'AES · RSA · Hashes',
    icon: Icons.lock,
    color: Colors.purple,
    hasOwnHeader: true,
    build: () => const CryptographySimulator(),
  ),
  LabCatalogEntry(
    id: 'theory',
    label: 'Theorie Internet',
    subtitle: 'Ping · DNS · TCP · SSH',
    icon: Icons.public,
    color: Colors.teal,
    build: () => const HowInternetWorksSimulator(),
  ),
  LabCatalogEntry(
    id: 'linux',
    label: 'Linux',
    subtitle: 'Boot · FS · Processus · Bash',
    icon: Icons.terminal,
    color: Colors.green,
    build: () => const LinuxSimulator(),
  ),
  LabCatalogEntry(
    id: 'algorithms',
    label: 'Algorithmes',
    subtitle: 'Tri · Graphes · Crypto · DP',
    icon: Icons.account_tree,
    color: Colors.amber,
    build: () => const AlgorithmsSimulator(),
  ),
];
