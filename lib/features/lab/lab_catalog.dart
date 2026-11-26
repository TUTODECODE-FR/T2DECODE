// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
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

import 'package:tutodecode/features/training/conversion_trainer.dart';
import 'package:tutodecode/features/training/packet_decoder_trainer.dart';
import 'package:tutodecode/features/training/permissions_trainer.dart';
import 'package:tutodecode/features/training/routing_trainer.dart';
import 'package:tutodecode/features/training/subnet_trainer.dart';
import 'package:tutodecode/features/training/terminal_missions.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

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
  // Entraînements : exercices générés à chaque fois, vérifiés et corrigés.
  LabCatalogEntry(
    id: 'training-terminal',
    label: 'Terminal : missions',
    subtitle: 'Entraînement · commandes Linux vérifiées',
    icon: Icons.terminal,
    color: TdcColors.system,
    hasOwnHeader: true,
    build: () => const TerminalMissions(),
  ),
  LabCatalogEntry(
    id: 'training-subnet',
    label: 'Sous-réseaux IPv4',
    subtitle: 'Entraînement · calcul, même réseau, VLSM',
    icon: Icons.calculate,
    color: TdcColors.network,
    hasOwnHeader: true,
    build: () => const SubnetTrainer(),
  ),
  LabCatalogEntry(
    id: 'training-routing',
    label: 'Tables de routage',
    subtitle: 'Entraînement · préfixe le plus long',
    icon: Icons.alt_route,
    color: TdcColors.network,
    hasOwnHeader: true,
    build: () => const RoutingTrainer(),
  ),
  LabCatalogEntry(
    id: 'training-packets',
    label: 'Décoder une trame',
    subtitle: 'Entraînement · Ethernet, IPv4, TCP, UDP',
    icon: Icons.data_object,
    color: TdcColors.network,
    hasOwnHeader: true,
    build: () => const PacketDecoderTrainer(),
  ),
  LabCatalogEntry(
    id: 'training-permissions',
    label: 'Droits Linux',
    subtitle: 'Entraînement · chmod, ls -l, umask',
    icon: Icons.lock_outline,
    color: TdcColors.security,
    hasOwnHeader: true,
    build: () => const PermissionsTrainer(),
  ),
  LabCatalogEntry(
    id: 'training-conversions',
    label: 'Binaire et hexadécimal',
    subtitle: 'Entraînement · conversions, masques',
    icon: Icons.swap_horiz,
    color: TdcColors.algorithms,
    hasOwnHeader: true,
    build: () => const ConversionTrainer(),
  ),
  LabCatalogEntry(
    id: 'network',
    label: 'Reseau',
    subtitle: 'Ping · Scan · Traceroute',
    icon: Icons.lan,
    color: TdcColors.network,
    hasOwnHeader: true,
    build: () => const NetworkSimulator(),
  ),
  LabCatalogEntry(
    id: 'security',
    label: 'Securite',
    subtitle: 'Attaques · Defense · CTF',
    icon: Icons.shield,
    color: TdcColors.security,
    hasOwnHeader: true,
    build: () => const SecuritySimulator(),
  ),
  LabCatalogEntry(
    id: 'ctf_prep',
    label: 'CTF Prep',
    subtitle: 'Offline · Vulnérable · Contrôlé',
    icon: Icons.flag,
    color: TdcColors.danger,
    build: () => const CtfPrepSimulator(),
  ),
  LabCatalogEntry(
    id: 'system',
    label: 'Systeme',
    subtitle: 'CPU · RAM · Processus',
    icon: Icons.memory,
    color: TdcColors.system,
    hasOwnHeader: true,
    build: () => const SystemSimulator(),
  ),
  LabCatalogEntry(
    id: 'cloud',
    label: 'Cloud',
    subtitle: 'Conteneurs · K8s · CI/CD',
    icon: Icons.cloud,
    color: TdcColors.cloud,
    hasOwnHeader: true,
    build: () => const CloudSimulator(),
  ),
  LabCatalogEntry(
    id: 'crypto',
    label: 'Cryptographie',
    subtitle: 'AES · RSA · Hashes',
    icon: Icons.lock,
    color: TdcColors.crypto,
    hasOwnHeader: true,
    build: () => const CryptographySimulator(),
  ),
  LabCatalogEntry(
    id: 'theory',
    label: 'Theorie Internet',
    subtitle: 'Ping · DNS · TCP · SSH',
    icon: Icons.public,
    color: TdcColors.textSecondary,
    build: () => const HowInternetWorksSimulator(),
  ),
  LabCatalogEntry(
    id: 'linux',
    label: 'Linux',
    subtitle: 'Boot · FS · Processus · Bash',
    icon: Icons.terminal,
    color: TdcColors.system,
    build: () => const LinuxSimulator(),
  ),
  LabCatalogEntry(
    id: 'algorithms',
    label: 'Algorithmes',
    subtitle: 'Tri · Graphes · Crypto · DP',
    icon: Icons.account_tree,
    color: TdcColors.algorithms,
    build: () => const AlgorithmsSimulator(),
  ),
];
