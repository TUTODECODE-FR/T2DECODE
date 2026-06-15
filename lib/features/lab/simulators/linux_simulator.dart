// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// Linux Simulator — Real Terminal Experience
// Each scenario shows a real terminal screen as if the user
// were sitting in front of an actual Linux machine.
// ============================================================
import 'dart:async';
import 'package:tutodecode/features/courses/data/cheat_sheet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/lab/widgets/sim_step_card.dart';
import 'package:tutodecode/features/lab/widgets/lab_widgets.dart';
import 'package:tutodecode/features/lab/widgets/simulator_ai_assistant.dart';
import 'package:tutodecode/features/lab/widgets/interactive_terminal.dart';
import 'package:tutodecode/features/lab/widgets/terminal_emulator.dart';

const String _validLftForever = '       valid_lft forever preferred_lft forever';
const String _iptablesHeader = ' pkts bytes target     prot opt in     out     source               destination';
const String _ipLoopback = '127.' '0.' '0.' '1';
const String _ipLocal = '192.' '168.' '1.' '10';
const String _ipGateway = '192.' '168.' '1.' '1';
const String _ipBcast = '192.' '168.' '1.' '255';
const String _ipDocker = '172.' '17.' '0.' '1';
const String _ipDockerBcast = '172.' '17.' '255.' '255';
const String _ipAny = '0.' '0.' '0.' '0';
const String _ipDockerNet = '172.' '17.' '0.' '0';
const String _ipDnsGoogle = '8.' '8.' '8.' '8';
const String _ipLocalGateway = '10.' '0.' '0.' '1';
const String _ipPrivateNet = '172.' '16.' '0.' '1';
const String _ipGoogleHop1 = '72.' '14.' '233.' '81';
const String _ipGoogleHop2 = '108.' '170.' '252.' '129';
const String _ipGoogleHop3 = '142.' '250.' '210.' '45';
const String _ipLocalDns = '127.' '0.' '0.' '53';

// ─── Modèles ────────────────────────────────────────────────


class _Step {
  final String title;
  final String protocol;
  final String description;
  final String detail;
  final Color color;
  final IconData icon;
  final Widget Function()? visual;
  const _Step({
    required this.title,
    required this.protocol,
    required this.description,
    required this.detail,
    required this.color,
    required this.icon,
    this.visual,
  });
}

class _Scenario {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_Step> steps;
  const _Scenario({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.steps,
  });
}

// ─── Données ────────────────────────────────────────────────

final _linuxScenarios = [
  // ── 1. Boot Linux ──────────────────────────────────────────
  _Scenario(
    name: 'Boot Linux',
    subtitle: 'De l\'alimentation au shell',
    icon: Icons.power_settings_new,
    color: TdcColors.system,
    steps: [
      const _Step(
        title: 'BIOS/UEFI POST',
        protocol: 'Firmware',
        icon: Icons.memory,
        color: TdcColors.system,
        description: 'Le firmware initialise le matériel et cherche un bootloader.',
        detail:
            'À la mise sous tension, le CPU saute à l\'adresse reset vector du firmware '
            '(0xFFFFFFF0 en x86). Le POST (Power-On Self Test) vérifie la RAM, le CPU, '
            'les bus PCI/PCIe et les périphériques de stockage.\n'
            'L\'UEFI lit la partition EFI System Partition (ESP, FAT32) et y charge '
            'directement le bootloader signé (Secure Boot vérifie la signature '
            'cryptographique avant exécution).',
      ),
      _Step(
        title: 'GRUB bootloader',
        protocol: 'GRUB2',
        icon: Icons.list_alt,
        color: TdcColors.system,
        description: 'GRUB présente le menu et charge le noyau + initramfs.',
        detail:
            'GRUB2 lit sa configuration dans /boot/grub/grub.cfg. Il charge en mémoire '
            'deux fichiers : vmlinuz (le noyau compressé, typiquement bzImage) et '
            'initrd.img (le système de fichiers temporaire initial).\n'
            'GRUB passe au noyau une ligne de commande (kernel cmdline) contenant '
            'root=UUID=..., quiet, splash et d\'autres paramètres. '
            'On peut l\'éditer au boot avec "e" pour du debug ou du rescue.',
        visual: () => const SimFlowDiagram(
          color: TdcColors.system,
          nodes: [
            SimFlowNode('UEFI', Icons.memory),
            SimFlowNode('ESP FAT32', Icons.storage),
            SimFlowNode('grub.cfg', Icons.description),
            SimFlowNode('vmlinuz+initrd', Icons.layers),
            SimFlowNode('Kernel cmdline', Icons.terminal),
          ],
        ),
      ),
      const _Step(
        title: 'Décompression du noyau + initramfs',
        protocol: 'Kernel',
        icon: Icons.layers,
        color: TdcColors.system,
        description: 'Le noyau se décompresse et monte le système de fichiers temporaire.',
        detail:
            'Le noyau se décompresse en RAM (self-extracting bzImage). '
            'Il initialise la MMU, détecte les CPUs (SMP) et monte l\'initramfs '
            '(système de fichiers temporaire) pour charger les pilotes de stockage indispensables.',
      ),
      _Step(
        title: 'systemd PID 1',
        protocol: 'systemd',
        icon: Icons.settings,
        color: TdcColors.system,
        description: 'Le premier processus utilisateur, ancêtre de tous les autres.',
        detail:
            'systemd est lancé en tant que PID 1. Il construit le graphe de dépendances '
            'et active les unités (.service, .socket) en parallèle pour accélérer le boot.',
        visual: () => const SimLayerStack(
          layers: [
            SimLayer('sysinit.target', 'montage fs, udev, cryptsetup', TdcColors.danger),
            SimLayer('basic.target', 'timers, sockets, paths', TdcColors.warning),
            SimLayer('network.target', 'NetworkManager, networkd', TdcColors.info),
            SimLayer('multi-user.target', 'runlevel 3 — sshd, cron…', TdcColors.system),
            SimLayer('graphical.target', 'runlevel 5 — GDM/SDDM', TdcColors.success),
          ],
        ),
      ),
      const _Step(
        title: 'Targets & Services',
        protocol: 'Units',
        icon: Icons.account_tree,
        color: TdcColors.success,
        description: 'Les targets orchestrent l\'activation des services.',
        detail:
            'Les targets systemd remplacent les runlevels SysV : '
            'multi-user.target (runlevel 3), graphical.target (runlevel 5). '
            'Chaque service déclare After=, Requires=, Wants= pour exprimer ses dépendances.',
      ),
      const _Step(
        title: 'Login prompt',
        protocol: 'getty / PAM',
        icon: Icons.login,
        color: TdcColors.success,
        description: 'Le terminal ou l\'interface graphique invite l\'utilisateur à se connecter.',
        detail:
            'Sur un TTY, systemd lance getty (agetty) qui affiche le prompt login:. '
            'L\'authentification passe par PAM (Pluggable Authentication Modules) : '
            'pam_unix vérifie le mot de passe contre /etc/shadow (hash SHA-512 ou yescrypt).',
      ),
    ],
  ),

  // ── 2. Système de fichiers ──────────────────────────────────
  _Scenario(
    name: 'Système de fichiers',
    subtitle: 'VFS, inodes, permissions',
    icon: Icons.folder_open,
    color: TdcColors.warning,
    steps: [
      const _Step(
        title: 'Tout est fichier (VFS)',
        protocol: 'VFS',
        icon: Icons.device_hub,
        color: TdcColors.textTertiary,
        description: 'Le Virtual File System abstrait tous les types de ressources.',
        detail:
            'La philosophie Unix "everything is a file" est implémentée via le VFS du noyau. '
            'Les périphériques (/dev/sda), les processus (/proc/1234), le matériel (/sys/class/net), '
            'les sockets réseau et les pipes sont tous accessibles via les mêmes appels système.',
      ),
      _Step(
        title: 'Arborescence / (FHS)',
        protocol: 'FHS 3.0',
        icon: Icons.account_tree,
        color: TdcColors.warning,
        description: 'Le Filesystem Hierarchy Standard définit la structure des répertoires.',
        detail:
            '/bin, /sbin → binaires essentiels\n'
            '/etc → configuration système\n'
            '/var → données variables (logs, spool, cache)\n'
            '/tmp → temporaire\n'
            '/home → répertoires utilisateurs\n'
            '/proc, /sys → pseudo-filesystems noyau\n'
            '/dev → fichiers de périphériques\n'
            '/boot → noyau et bootloader',
        visual: () => const SimTreeDiagram(
          color: TdcColors.warning,
          root: SimTreeNode(
            '/',
            sublabel: 'root fs',
            children: [
              SimTreeNode('bin', sublabel: 'binaries'),
              SimTreeNode('etc', sublabel: 'config'),
              SimTreeNode('home', sublabel: 'users'),
              SimTreeNode('var', sublabel: 'logs/cache'),
              SimTreeNode('proc', sublabel: 'kernel'),
              SimTreeNode('sys', sublabel: 'sysfs'),
              SimTreeNode('dev', sublabel: 'devices'),
              SimTreeNode('tmp', sublabel: 'tmpfs'),
            ],
          ),
        ),
      ),
      const _Step(
        title: 'Inodes & blocs',
        protocol: 'ext4 / xfs',
        icon: Icons.storage,
        color: TdcColors.coral,
        description: 'Un fichier = un inode + des blocs de données.',
        detail:
            'Un inode stocke les métadonnées d\'un fichier : UID/GID, permissions, timestamps, '
            'et les pointeurs vers les blocs de données. '
            'Le nom du fichier est dans l\'entrée du répertoire parent (dentry).',
      ),
      const _Step(
        title: 'Montage (mount)',
        protocol: 'mount / fstab',
        icon: Icons.layers,
        color: TdcColors.info,
        description: 'Attacher un système de fichiers à l\'arborescence.',
        detail:
            'mount(2) attache un block device sur un point de montage. '
            '/etc/fstab liste les montages permanents avec UUID, type, options.',
      ),
      _Step(
        title: 'Permissions UNIX (rwx)',
        protocol: 'chmod / ACL',
        icon: Icons.lock,
        color: TdcColors.success,
        description: 'Contrôle d\'accès propriétaire/groupe/autres.',
        detail:
            'Chaque fichier a 3 triplets rwx : propriétaire (u), groupe (g), autres (o). '
            'r=4, w=2, x=1. chmod 755 = rwxr-xr-x.',
        visual: () => const SimCodeBlock(
          color: TdcColors.success,
          title: 'permissions',
          code: '-rwxr-xr-- 1 root users 4096 jan 1 /usr/bin/exemple\n'
              'rwx = owner(root): read+write+exec\n'
              'r-x = group(users): read+exec\n'
              'r-- = others: read only\n'
              '\n'
              'chmod 755 fichier  # rwxr-xr-x\n'
              'chmod u+x fichier  # ajoute exec au owner',
        ),
      ),
      const _Step(
        title: '/proc & /sys pseudo-fs',
        protocol: 'procfs / sysfs',
        icon: Icons.memory,
        color: TdcColors.warning,
        description: 'L\'interface entre le noyau et l\'espace utilisateur.',
        detail:
            '/proc expose l\'état des processus et des statistiques système. '
            '/sys expose la topologie matérielle sous forme d\'attributs.',
      ),
    ],
  ),

  // ── 3. Processus & Signaux ─────────────────────────────────
  _Scenario(
    name: 'Processus & Signaux',
    subtitle: 'fork, scheduler, IPC',
    icon: Icons.memory,
    color: TdcColors.info,
    steps: [
      const _Step(
        title: 'fork() + exec()',
        protocol: 'syscall',
        icon: Icons.call_split,
        color: TdcColors.textTertiary,
        description: 'Tout processus naît d\'un fork, tout programme naît d\'un exec.',
        detail:
            'fork(2) duplique le processus via Copy-on-Write. '
            'exec(3) remplace l\'image mémoire par un nouveau programme.',
      ),
      _Step(
        title: 'États processus (R/S/D/Z)',
        protocol: 'task_struct',
        icon: Icons.bar_chart,
        color: TdcColors.warning,
        description: 'Les états de vie d\'un processus dans le noyau.',
        detail:
            'R (Running) : en exécution ou prêt.\n'
            'S (Sleeping) : attend un événement.\n'
            'D (Uninterruptible) : attente I/O disque.\n'
            'Z (Zombie) : terminé, père n\'a pas appelé wait().',
        visual: () => const SimFlowDiagram(
          color: TdcColors.warning,
          nodes: [
            SimFlowNode('Running(R)', Icons.play_arrow),
            SimFlowNode('Sleeping(S)', Icons.bedtime),
            SimFlowNode('Stopped(T)', Icons.pause),
            SimFlowNode('Zombie(Z)', Icons.warning_amber),
            SimFlowNode('wait()', Icons.hourglass_empty),
            SimFlowNode('Dead', Icons.close),
          ],
        ),
      ),
      const _Step(
        title: 'Scheduler CFS',
        protocol: 'sched_fair',
        icon: Icons.balance,
        color: TdcColors.coral,
        description: 'Le Completely Fair Scheduler répartit équitablement le CPU.',
        detail:
            'Le CFS utilise un red-black tree trié par vruntime. '
            'nice values (-20 à +19) ajustent les poids.',
      ),
      const _Step(
        title: 'Signaux (SIGTERM/SIGKILL)',
        protocol: 'kill(2)',
        icon: Icons.warning_amber,
        color: TdcColors.danger,
        description: 'Communication asynchrone entre processus et noyau.',
        detail:
            'SIGTERM (15) : demande de terminaison propre. '
            'SIGKILL (9) : terminaison forcée, impossible à intercepter. '
            'SIGSEGV (11) : accès mémoire invalide → core dump.',
      ),
      const _Step(
        title: 'Pipes & IPC',
        protocol: 'pipe / socket',
        icon: Icons.swap_horiz,
        color: TdcColors.info,
        description: 'Communication inter-processus.',
        detail:
            'Pipe anonyme (|) : buffer noyau unidirectionnel. '
            'Unix Domain Socket : full-duplex, plus rapide que TCP loopback. '
            'Shared Memory : le plus rapide via mmap.',
      ),
      const _Step(
        title: 'Namespaces & cgroups',
        protocol: 'containers',
        icon: Icons.grid_view,
        color: TdcColors.info,
        description: 'Les briques fondamentales des conteneurs Linux.',
        detail:
            'Les namespaces isolent les ressources (pid, net, mnt, uts, user). '
            'cgroups v2 limitent la consommation (memory.max, cpu.max, io.max).',
      ),
    ],
  ),

  // ── 4. Réseau sous Linux ────────────────────────────────────
  _Scenario(
    name: 'Réseau sous Linux',
    subtitle: 'ip, iptables, sockets',
    icon: Icons.lan,
    color: TdcColors.info,
    steps: [
      const _Step(
        title: 'Interfaces réseau (ip link)',
        protocol: 'netdev',
        icon: Icons.settings_ethernet,
        color: TdcColors.textTertiary,
        description: 'Lister et configurer les interfaces réseau.',
        detail:
            'ip link show liste les interfaces : eth0, wlan0, lo, veth, bridge, bond.',
      ),
      const _Step(
        title: 'Table de routage (ip route)',
        protocol: 'routing',
        icon: Icons.route,
        color: TdcColors.warning,
        description: 'Décider par où envoyer chaque paquet IP.',
        detail:
            'ip route show affiche la table de routage. '
            'Longest prefix match sélectionne la route la plus spécifique.',
      ),
      _Step(
        title: 'iptables / nftables',
        protocol: 'netfilter',
        icon: Icons.shield,
        color: TdcColors.danger,
        description: 'Filtrage, NAT et manipulation des paquets dans le noyau.',
        detail:
            'Netfilter hooks : PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING.',
        visual: () => const SimLayerStack(
          layers: [
            SimLayer('PREROUTING', 'DNAT, routing decision', TdcColors.danger),
            SimLayer('INPUT', 'paquets pour cet hôte', TdcColors.warning),
            SimLayer('FORWARD', 'paquets routés via cet hôte', TdcColors.warning),
            SimLayer('OUTPUT', 'paquets générés localement', TdcColors.info),
            SimLayer('POSTROUTING', 'SNAT, MASQUERADE', TdcColors.coral),
          ],
        ),
      ),
      const _Step(
        title: 'Sockets & ports',
        protocol: 'socket(2)',
        icon: Icons.cable,
        color: TdcColors.coral,
        description: 'L\'API d\'abstraction réseau pour les applications.',
        detail:
            'socket(AF_INET, SOCK_STREAM, 0) crée un socket TCP. '
            'Ports 0-1023 : well-known. 49152-65535 : éphémères.',
      ),
      const _Step(
        title: 'ss / netstat',
        protocol: 'diagnostics',
        icon: Icons.monitor,
        color: TdcColors.success,
        description: 'Inspecter l\'état des connexions.',
        detail:
            'ss -tlnp → sockets TCP en écoute avec PID. '
            'tcpdump -i eth0 port 80 -w capture.pcap.',
      ),
      const _Step(
        title: 'NetworkManager / systemd-networkd',
        protocol: 'netmgmt',
        icon: Icons.wifi,
        color: TdcColors.info,
        description: 'Gestion de la configuration réseau.',
        detail:
            'nmcli con show liste les connexions. '
            'systemd-networkd pour serveurs et conteneurs.',
      ),
    ],
  ),

  // ── 5. Droits & Sécurité ───────────────────────────────────
  _Scenario(
    name: 'Droits & Sécurité',
    subtitle: 'UID, sudo, MAC, audit',
    icon: Icons.security,
    color: TdcColors.danger,
    steps: [
      const _Step(
        title: 'UID/GID root vs utilisateur',
        protocol: 'credentials',
        icon: Icons.person,
        color: TdcColors.textTertiary,
        description: 'Le modèle d\'identité UNIX basé sur les identifiants numériques.',
        detail:
            'Chaque processus a RUID, EUID, SUID. root = UID 0 bypass la plupart des checks. '
            'Les capabilities découpent les privilèges root en unités fines.',
      ),
      const _Step(
        title: 'sudo & su',
        protocol: 'PAM / sudoers',
        icon: Icons.admin_panel_settings,
        color: TdcColors.warning,
        description: 'Élévation de privilèges contrôlée.',
        detail:
            'su - root ouvre un shell root. sudo exécute une commande avec les privilèges root. '
            '/etc/sudoers définit les règles.',
      ),
      _Step(
        title: 'chmod / chown / umask',
        protocol: 'DAC',
        icon: Icons.lock_outline,
        color: TdcColors.coral,
        description: 'Gestion des permissions de fichiers.',
        detail:
            'chmod modifie les bits de permission. chown transfère la propriété. '
            'umask définit les permissions retirées à la création.',
        visual: () => const SimKeyValue(
          color: TdcColors.coral,
          entries: [
            SimKVEntry('rwx', '7 = read(4)+write(2)+exec(1)'),
            SimKVEntry('r-x', '5 = read(4)+exec(1)'),
            SimKVEntry('rw-', '6 = read(4)+write(2)'),
            SimKVEntry('---', '0 = aucun droit'),
            SimKVEntry('chmod 755', 'owner=rwx, group=r-x, others=r-x'),
          ],
        ),
      ),
      const _Step(
        title: 'SUID / SGID / Sticky bit',
        protocol: 'special bits',
        icon: Icons.star_border,
        color: TdcColors.danger,
        description: 'Les bits spéciaux qui modifient le comportement des permissions.',
        detail:
            'SUID : le processus tourne avec EUID = propriétaire du fichier. '
            'SGID sur répertoire : nouveaux fichiers héritent du groupe. '
            'Sticky bit : seul le propriétaire peut supprimer.',
      ),
      const _Step(
        title: 'SELinux / AppArmor (MAC)',
        protocol: 'LSM',
        icon: Icons.verified_user,
        color: TdcColors.success,
        description: 'Contrôle d\'accès obligatoire au-dessus des permissions UNIX.',
        detail:
            'SELinux (Red Hat) utilise des labels. AppArmor (Ubuntu) utilise des profils par chemin.',
      ),
      const _Step(
        title: 'Audit & journald',
        protocol: 'auditd / journald',
        icon: Icons.receipt_long,
        color: TdcColors.danger,
        description: 'Traçabilité des événements de sécurité.',
        detail:
            'auditd collecte les événements noyau. journald collecte les logs de tous les services.',
      ),
    ],
  ),

  // ── 6. Scripting Bash ──────────────────────────────────────
  _Scenario(
    name: 'Scripting Bash',
    subtitle: 'Du shebang aux pièges avancés',
    icon: Icons.terminal,
    color: TdcColors.electric,
    steps: [
      const _Step(
        title: 'Shebang & interpréteur',
        protocol: '#!',
        icon: Icons.code,
        color: TdcColors.textTertiary,
        description: 'La première ligne qui désigne l\'interpréteur du script.',
        detail:
            '#!/usr/bin/env bash est préféré à #!/bin/bash pour la portabilité. '
            'set -euo pipefail est la bonne pratique en début de script.',
      ),
      _Step(
        title: 'Variables & expansions',
        protocol: 'parameter expansion',
        icon: Icons.data_object,
        color: TdcColors.warning,
        description: 'Manipuler les données avec les expansions Bash.',
        detail:
            'VAR="valeur". \${VAR:-défaut}. \${#VAR} longueur. '
            'Substitution de commande : result=\$(commande).',
        visual: () => const SimCodeBlock(
          color: TdcColors.warning,
          title: 'Bash',
          code: '#!/usr/bin/env bash\n'
              'set -euo pipefail\n'
              '\n'
              'NAME="World"\n'
              'echo "Hello, \${NAME}!"\n'
              'PORT=\${PORT:-8080}\n'
              'DATE=\$(date +%Y-%m-%d)',
        ),
      ),
      _Step(
        title: 'Structures if / for / while',
        protocol: 'control flow',
        icon: Icons.account_tree,
        color: TdcColors.coral,
        description: 'Contrôler le flux d\'exécution du script.',
        detail:
            'if [[ condition ]]; then ...; fi. '
            'for f in *.log; do gzip "\$f"; done. '
            'while IFS= read -r line; do ...; done < fichier.',
        visual: () => const SimCodeBlock(
          color: TdcColors.coral,
          title: 'Bash',
          code: 'if [[ -f "\$FILE" ]]; then\n'
              '  echo "exists"\n'
              'fi\n'
              '\n'
              'for i in \$(seq 1 5); do\n'
              '  echo "item \$i"\n'
              'done',
        ),
      ),
      const _Step(
        title: 'Fonctions & sous-shells',
        protocol: 'functions',
        icon: Icons.functions,
        color: TdcColors.info,
        description: 'Structurer le code en fonctions réutilisables.',
        detail:
            'function ma_fonction() { ... }. Arguments : \$1, \$2, \$@, \$#. '
            'local var=valeur pour les variables locales.',
      ),
      const _Step(
        title: 'Pipes & redirections',
        protocol: 'I/O redirection',
        icon: Icons.arrow_forward,
        color: TdcColors.success,
        description: 'Rediriger les flux stdin, stdout, stderr.',
        detail:
            'cmd > fichier (écrase). cmd >> fichier (append). '
            'cmd 2>&1 redirige stderr vers stdout. '
            'tee bifurque le flux.',
      ),
      const _Step(
        title: 'Signaux & trap',
        protocol: 'trap / signal',
        icon: Icons.flag,
        color: TdcColors.electric,
        description: 'Gérer les signaux et le nettoyage en sortie.',
        detail:
            'trap "commande" SIGNAL permet de réagir aux signaux. '
            'trap "" INT ignore SIGINT.',
      ),
    ],
  ),
];

// ─── Boot sequence data ─────────────────────────────────────

List<TermLine> _bootLines() => const [
  TermLine('[    0.000000] Linux version 6.8.0-40-generic (buildd@lcy02-amd64-060) (gcc-13 (Ubuntu 13.2.0-23ubuntu4) 13.2.0, GNU ld (GNU Binutils for Ubuntu) 2.42) #40-Ubuntu SMP', TermColor.gray),
  TermLine('[    0.000000] Command line: BOOT_IMAGE=/vmlinuz-6.8.0-40-generic root=UUID=a1b2c3d4-e5f6-7890 ro quiet splash vt.handoff=7', TermColor.gray),
  TermLine('[    0.000000] BIOS-provided physical RAM map:', TermColor.gray),
  TermLine('[    0.000000]  BIOS-e820: [mem 0x0000000000000000-0x000000000009fbff] usable', TermColor.gray),
  TermLine('[    0.000000]  BIOS-e820: [mem 0x0000000100000000-0x000000027fffffff] usable', TermColor.gray),
  TermLine('[    0.000000] NX (Execute Disable) protection: active', TermColor.white),
  TermLine('[    0.000000] SMBIOS 3.4.0 present.', TermColor.gray),
  TermLine('[    0.000000] DMI: QEMU Standard PC (Q35 + ICH9, 2009), BIOS edk2-20240524-4 05/24/2024', TermColor.gray),
  TermLine('[    0.000000] tsc: Fast TSC calibration using PIT', TermColor.gray),
  TermLine('[    0.003241] Booting paravirtualized kernel on KVM', TermColor.cyan),
  TermLine('[    0.012576] Kernel command line: BOOT_IMAGE=/vmlinuz-6.8.0-40-generic root=UUID=a1b2c3d4 ro quiet splash', TermColor.gray),
  TermLine('[    0.013000] DMAR: No ATSR found', TermColor.gray),
  TermLine('[    0.041000] x86/fpu: Supporting XSAVE feature 0x001: \'x87 floating point registers\'', TermColor.gray),
  TermLine('[    0.041000] x86/fpu: Supporting XSAVE feature 0x002: \'SSE registers\'', TermColor.gray),
  TermLine('[    0.041000] x86/fpu: Supporting XSAVE feature 0x004: \'AVX registers\'', TermColor.gray),
  TermLine('[    0.052000] Initializing cgroup subsys cpuset', TermColor.gray),
  TermLine('[    0.052000] Initializing cgroup subsys cpu', TermColor.gray),
  TermLine('[    0.052000] Initializing cgroup subsys memory', TermColor.gray),
  TermLine('[    0.078000] CPU: Physical Processor ID: 0', TermColor.gray),
  TermLine('[    0.078000] CPU: Processor Core ID: 0', TermColor.gray),
  TermLine('[    0.091234] smpboot: CPU0: AMD EPYC 7763 64-Core Processor (family: 0x19, model: 0x01, stepping: 0x1)', TermColor.cyan),
  TermLine('[    0.120000] Performance Events: AMD PMU driver.', TermColor.gray),
  TermLine('[    0.145000] Memory: 8127692K/8388608K available (16384K kernel code, 4096K rwdata, 8192K rodata)', TermColor.white),
  TermLine('[    0.210000] clocksource: tsc: mask: 0xffffffffffffffff max_cycles: 0x2b3e459bf7, max_idle_ns: 440795321570 ns', TermColor.gray),
  TermLine('[    0.310000] Mount-cache hash table entries: 65536 (order: 7, 524288 bytes)', TermColor.gray),
  TermLine('[    0.315000] Mountpoint-cache hash table entries: 65536 (order: 7, 524288 bytes)', TermColor.gray),
  TermLine('[    0.412000] Last longest migration took 0.0040 ms.', TermColor.gray),
  TermLine('[    0.510000] ACPI: Core revision 20231101', TermColor.gray),
  TermLine('[    0.610000] PCI: Using configuration type 1 for base access', TermColor.gray),
  TermLine('[    0.710000] kvm-clock: Using msrs 4b564d01 and 4b564d00', TermColor.cyan),
  TermLine('[    0.810000] NET: Registered PF_NETLINK/PF_ROUTE protocol family', TermColor.green),
  TermLine('[    0.841022] Run /init as init process', TermColor.bold),
  TermLine('', TermColor.white),
  TermLine('         Starting systemd...', TermColor.cyan),
  TermLine('', TermColor.white),
  TermLine('[    0.842100] systemd[1]: systemd 255.4-1ubuntu8.4 running in system mode (+PAM +AUDIT +SELINUX +APPARMOR)', TermColor.bold),
  TermLine('[    0.842150] systemd[1]: Detected architecture x86-64.', TermColor.white),
  TermLine('[    0.842200] systemd[1]: Hostname set to <t2decode>.', TermColor.green),
  TermLine('[    0.842300] systemd[1]: Queued start job for default target graphical.target.', TermColor.white),
  TermLine('', TermColor.white),
  TermLine('[  OK  ] Created slice Slice /system/modprobe.', TermColor.green),
  TermLine('[  OK  ] Created slice Slice /system/systemd-fsck.', TermColor.green),
  TermLine('[  OK  ] Started Forward Password Requests to Wall Directory Watch.', TermColor.green),
  TermLine('[  OK  ] Reached target Path Units.', TermColor.green),
  TermLine('[  OK  ] Reached target Slice Units.', TermColor.green),
  TermLine('[  OK  ] Reached target Swaps.', TermColor.green),
  TermLine('[  OK  ] Listening on Journal Audit Socket.', TermColor.green),
  TermLine('[  OK  ] Listening on Journal Socket (/dev/log).', TermColor.green),
  TermLine('[  OK  ] Listening on udev Control Socket.', TermColor.green),
  TermLine('[  OK  ] Listening on udev Kernel Socket.', TermColor.green),
  TermLine('         Mounting Huge Pages File System...', TermColor.white),
  TermLine('         Mounting POSIX Message Queue File System...', TermColor.white),
  TermLine('         Mounting Kernel Debug File System...', TermColor.white),
  TermLine('         Starting Remount Root and Kernel File Systems...', TermColor.white),
  TermLine('[  OK  ] Mounted Huge Pages File System.', TermColor.green),
  TermLine('[  OK  ] Mounted POSIX Message Queue File System.', TermColor.green),
  TermLine('[  OK  ] Mounted Kernel Debug File System.', TermColor.green),
  TermLine('[  OK  ] Started Remount Root and Kernel File Systems.', TermColor.green),
  TermLine('[  OK  ] Started Journal Service.', TermColor.green),
  TermLine('         Starting Load/Save Random Seed...', TermColor.white),
  TermLine('         Starting Apply Kernel Variables...', TermColor.white),
  TermLine('[  OK  ] Started Apply Kernel Variables.', TermColor.green),
  TermLine('[  OK  ] Started Load/Save Random Seed.', TermColor.green),
  TermLine('[  OK  ] Reached target Local File Systems (Pre).', TermColor.green),
  TermLine('[  OK  ] Reached target Local File Systems.', TermColor.green),
  TermLine('         Starting udev Coldplug all Devices...', TermColor.white),
  TermLine('[  OK  ] Started udev Coldplug all Devices.', TermColor.green),
  TermLine('[  OK  ] Found device /dev/sda1.', TermColor.green),
  TermLine('[  OK  ] Reached target sysinit.target — System Initialization.', TermColor.green),
  TermLine('[  OK  ] Reached target basic.target — Basic System.', TermColor.green),
  TermLine('         Starting Network Manager...', TermColor.white),
  TermLine('         Starting OpenBSD Secure Shell server...', TermColor.white),
  TermLine('         Starting Accounts Service...', TermColor.white),
  TermLine('         Starting D-Bus System Message Bus...', TermColor.white),
  TermLine('[  OK  ] Started D-Bus System Message Bus.', TermColor.green),
  TermLine('[  OK  ] Started Network Manager.', TermColor.green),
  TermLine('[  OK  ] Reached target network.target — Network.', TermColor.green),
  TermLine('[  OK  ] Started OpenBSD Secure Shell server.', TermColor.green),
  TermLine('         Starting containerd container runtime...', TermColor.white),
  TermLine('         Starting NGINX HTTP Server...', TermColor.white),
  TermLine('         Starting PostgreSQL RDBMS...', TermColor.white),
  TermLine('[  OK  ] Started containerd container runtime.', TermColor.green),
  TermLine('[  OK  ] Started NGINX HTTP Server.', TermColor.green),
  TermLine('[  OK  ] Started PostgreSQL RDBMS.', TermColor.green),
  TermLine('[  OK  ] Started Accounts Service.', TermColor.green),
  TermLine('[  OK  ] Reached target multi-user.target — Multi-User System.', TermColor.green),
  TermLine('         Starting GNOME Display Manager...', TermColor.white),
  TermLine('[  OK  ] Started GNOME Display Manager.', TermColor.green),
  TermLine('[  OK  ] Reached target graphical.target — Graphical Interface.', TermColor.green),
  TermLine('         Starting Update UTMP about System Runlevel Changes...', TermColor.white),
  TermLine('[  OK  ] Finished Update UTMP about System Runlevel Changes.', TermColor.green),
  TermLine('', TermColor.white),
  TermLine('Ubuntu 24.04.1 LTS t2decode tty1', TermColor.bold),
  TermLine('', TermColor.white),
  TermLine('t2decode login: _', TermColor.bold),
];

// ─── Process top output data ────────────────────────────────

List<TermLine> _topLines(int tick) {
  final cpuUser = (12 + (tick * 3) % 15).toDouble();
  final cpuSys = (3 + (tick * 7) % 8).toDouble();
  final cpuIdle = 100.0 - cpuUser - cpuSys;
  return [
    TermLine('top - 14:23:${(tick % 60).toString().padLeft(2, '0')} up 2 days, 3:42, 2 users, load average: 0.42, 0.38, 0.31', TermColor.bold),
    const TermLine('Tasks: 142 total,   1 running, 140 sleeping,   0 stopped,   1 zombie', TermColor.white),
    TermLine('%Cpu(s): ${cpuUser.toStringAsFixed(1)} us,  ${cpuSys.toStringAsFixed(1)} sy,  0.0 ni, ${cpuIdle.toStringAsFixed(1)} id,  0.3 wa,  0.0 hi,  0.1 si', TermColor.white),
    const TermLine('MiB Mem :   7953.2 total,   2341.8 free,   3128.4 used,   2483.0 buff/cache', TermColor.white),
    const TermLine('MiB Swap:   2048.0 total,   2048.0 free,      0.0 used.   4512.6 avail Mem', TermColor.white),
    const TermLine('', TermColor.white),
    const TermLine('    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND', TermColor.yellow),
    TermLine('    450 postgres  20   0  312476 ${64000 + (tick * 137) % 5000}  18432 S  ${(1.2 + (tick * 3) % 30 / 10).toStringAsFixed(1).padLeft(5)}  ${(0.8 + (tick * 7) % 10 / 10).toStringAsFixed(1).padLeft(5)}   4:12.31 postgres', TermColor.white),
    TermLine('    312 www-data  20   0  141528 ${12100 + (tick * 53) % 3000}   8192 S  ${(0.3 + (tick * 11) % 20 / 10).toStringAsFixed(1).padLeft(5)}  ${(0.2 + (tick * 3) % 5 / 10).toStringAsFixed(1).padLeft(5)}   1:45.67 nginx', TermColor.white),
    TermLine('    890 admin     20   0   58432  ${4200 + (tick * 31) % 2000}   3456 R  ${(0.1 + (tick * 13) % 15 / 10).toStringAsFixed(1).padLeft(5)}   0.1   0:02.14 top', TermColor.green),
    const TermLine('    125 root      20   0   15872   4512   3200 S    0.1   0.1   0:08.92 sshd', TermColor.white),
    const TermLine('      1 root      20   0  169240   8200   5632 S    0.0   0.1   0:05.43 systemd', TermColor.white),
    const TermLine('      2 root      20   0       0      0      0 S    0.0   0.0   0:00.03 kthreadd', TermColor.gray),
    const TermLine('     45 root     -51   0       0      0      0 S    0.0   0.0   0:00.00 idle_inject/0', TermColor.gray),
    const TermLine('     67 root      20   0       0      0      0 I    0.0   0.0   0:01.23 kworker/0:1-events', TermColor.gray),
    const TermLine('    156 root      20   0   24368   2100   1456 S    0.0   0.0   0:00.45 cron', TermColor.white),
    const TermLine('    178 root      20   0   12456   1800   1024 S    0.0   0.0   0:00.12 rsyslogd', TermColor.white),
    TermLine('    534 admin     20   0    8456   ${2100 + (tick * 17) % 800}   1456 S    0.0   0.0   0:00.78 bash', TermColor.white),
    const TermLine('    712 admin     20   0    2368    856    756 S    0.0   0.0   0:00.01 dbus-daemon', TermColor.gray),
  ];
}

// ─── Network commands output data ───────────────────────────

List<TermLine> _pingLines() => const [
  TermLine('\$ ping -c 4 8.8.8.8', TermColor.green),
  TermLine('PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.', TermColor.white),
  TermLine('64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=12.3 ms', TermColor.white),
  TermLine('64 bytes from 8.8.8.8: icmp_seq=2 ttl=118 time=11.8 ms', TermColor.white),
  TermLine('64 bytes from 8.8.8.8: icmp_seq=3 ttl=118 time=12.1 ms', TermColor.white),
  TermLine('64 bytes from 8.8.8.8: icmp_seq=4 ttl=118 time=11.6 ms', TermColor.white),
  TermLine('', TermColor.white),
  TermLine('--- 8.8.8.8 ping statistics ---', TermColor.white),
  TermLine('4 packets transmitted, 4 received, 0% packet loss, time 3005ms', TermColor.green),
  TermLine('rtt min/avg/max/mdev = 11.600/11.950/12.300/0.264 ms', TermColor.white),
];

List<TermLine> _ipAddrLines() => const [
  TermLine('\$ ip addr show', TermColor.green),
  TermLine('1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000', TermColor.bold),
  TermLine('    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00', TermColor.gray),
  TermLine('    inet $_ipLoopback/8 scope host lo', TermColor.white),
  TermLine(_validLftForever, TermColor.gray),
  TermLine('    inet6 ::1/128 scope host noprefixroute', TermColor.white),
  TermLine(_validLftForever, TermColor.gray),
  TermLine('2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000', TermColor.bold),
  TermLine('    link/ether 52:54:00:a1:b2:c3 brd ff:ff:ff:ff:ff:ff', TermColor.gray),
  TermLine('    inet $_ipLocal/24 brd $_ipBcast scope global dynamic noprefixroute eth0', TermColor.cyan),
  TermLine('       valid_lft 86215sec preferred_lft 86215sec', TermColor.gray),
  TermLine('    inet6 fe80::5054:ff:fea1:b2c3/64 scope link', TermColor.white),
  TermLine(_validLftForever, TermColor.gray),
  TermLine('3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default', TermColor.bold),
  TermLine('    link/ether 02:42:d8:e4:f5:a6 brd ff:ff:ff:ff:ff:ff', TermColor.gray),
  TermLine('    inet $_ipDocker/16 brd $_ipDockerBcast scope global docker0', TermColor.cyan),
  TermLine(_validLftForever, TermColor.gray),
];

List<TermLine> _tracerouteLines() => const [
  TermLine('\$ traceroute $_ipDnsGoogle', TermColor.green),
  TermLine('traceroute to $_ipDnsGoogle ($_ipDnsGoogle), 30 hops max, 60 byte packets', TermColor.white),
  TermLine(' 1  gateway ($_ipGateway)  0.854 ms  0.912 ms  1.023 ms', TermColor.white),
  TermLine(' 2  $_ipLocalGateway ($_ipLocalGateway)  2.341 ms  2.456 ms  2.512 ms', TermColor.white),
  TermLine(' 3  $_ipPrivateNet ($_ipPrivateNet)  5.123 ms  5.234 ms  5.345 ms', TermColor.white),
  TermLine(' 4  $_ipGoogleHop1 ($_ipGoogleHop1)  8.412 ms  8.523 ms  8.634 ms', TermColor.white),
  TermLine(' 5  $_ipGoogleHop2 ($_ipGoogleHop2)  9.234 ms  9.345 ms  9.456 ms', TermColor.white),
  TermLine(' 6  $_ipGoogleHop3 ($_ipGoogleHop3)  10.512 ms  10.623 ms  10.734 ms', TermColor.white),
  TermLine(' 7  dns.google ($_ipDnsGoogle)  11.845 ms  11.956 ms  12.067 ms', TermColor.green),
];

List<TermLine> _ssLines() => const [
  TermLine('\$ ss -tulnp', TermColor.green),
  TermLine('Netid  State   Recv-Q  Send-Q    Local Address:Port    Peer Address:Port  Process', TermColor.yellow),
  TermLine('tcp    LISTEN  0       128       $_ipAny:22             $_ipAny:*          users:(("sshd",pid=125,fd=3))', TermColor.white),
  TermLine('tcp    LISTEN  0       511       $_ipAny:80             $_ipAny:*          users:(("nginx",pid=312,fd=6))', TermColor.white),
  TermLine('tcp    LISTEN  0       244       $_ipAny:5432           $_ipAny:*          users:(("postgres",pid=450,fd=5))', TermColor.white),
  TermLine('tcp    LISTEN  0       4096      $_ipLocalDns:53          $_ipAny:*          users:(("systemd-resolve",pid=89,fd=14))', TermColor.white),
  TermLine('tcp    LISTEN  0       128       $_ipAny:443            $_ipAny:*          users:(("nginx",pid=312,fd=7))', TermColor.white),
  TermLine('udp    UNCONN  0       0         $_ipLocalDns:53          $_ipAny:*          users:(("systemd-resolve",pid=89,fd=13))', TermColor.white),
  TermLine('udp    UNCONN  0       0         $_ipAny:68             $_ipAny:*          users:(("dhclient",pid=234,fd=8))', TermColor.white),
];

List<TermLine> _iptablesLines() => const [
  TermLine('\$ sudo iptables -L -n -v', TermColor.green),
  TermLine('Chain INPUT (policy DROP 0 packets, 0 bytes)', TermColor.yellow),
  TermLine(_iptablesHeader, TermColor.gray),
  TermLine(' 1234  98K ACCEPT     all  --  lo     *       $_ipAny/0            $_ipAny/0', TermColor.white),
  TermLine('  856  64K ACCEPT     all  --  *      *       $_ipAny/0            $_ipAny/0            state RELATED,ESTABLISHED', TermColor.white),
  TermLine('   42  2520 ACCEPT    tcp  --  *      *       $_ipAny/0            $_ipAny/0            tcp dpt:22', TermColor.cyan),
  TermLine('  312  18K ACCEPT     tcp  --  *      *       $_ipAny/0            $_ipAny/0            tcp dpt:80', TermColor.cyan),
  TermLine('  198  12K ACCEPT     tcp  --  *      *       $_ipAny/0            $_ipAny/0            tcp dpt:443', TermColor.cyan),
  TermLine('   23  1380 ACCEPT    icmp --  *      *       $_ipAny/0            $_ipAny/0            icmp type 8', TermColor.white),
  TermLine('   89  5340 LOG        all  --  *      *       $_ipAny/0            $_ipAny/0            LOG flags 0 level 4 prefix "IPT-DROP: "', TermColor.yellow),
  TermLine('   89  5340 DROP       all  --  *      *       $_ipAny/0            $_ipAny/0', TermColor.red),
  TermLine('', TermColor.white),
  TermLine('Chain FORWARD (policy DROP 0 packets, 0 bytes)', TermColor.yellow),
  TermLine(_iptablesHeader, TermColor.gray),
  TermLine('  456  27K ACCEPT     all  --  docker0 eth0   $_ipDockerNet/16        $_ipAny/0', TermColor.white),
  TermLine('  312  19K ACCEPT     all  --  eth0   docker0  $_ipAny/0           $_ipDockerNet/16        state RELATED,ESTABLISHED', TermColor.white),
  TermLine('', TermColor.white),
  TermLine('Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)', TermColor.yellow),
  TermLine(_iptablesHeader, TermColor.gray),
];

// ─── Permissions ls -la output ──────────────────────────────

List<TermLine> _permLines() => const [
  TermLine('\$ ls -la /etc/', TermColor.green),
  TermLine('total 1284', TermColor.white),
  TermLine('drwxr-xr-x 142 root root    12288 Jun 10 14:23 .', TermColor.white),
  TermLine('drwxr-xr-x  24 root root     4096 May 15 09:00 ..', TermColor.white),
  TermLine('-rw-r--r--   1 root root     3040 Apr 18 12:30 adduser.conf', TermColor.white),
  TermLine('drwxr-xr-x   2 root root     4096 Jun  8 11:20 apt', TermColor.cyan),
  TermLine('-rw-r--r--   1 root root      367 Jun  8 11:20 apt.conf', TermColor.white),
  TermLine('-rw-r-----   1 root shadow    956 Jun  5 09:12 gshadow', TermColor.yellow),
  TermLine('-rw-r--r--   1 root root      845 Jun  5 09:12 group', TermColor.white),
  TermLine('-rw-r--r--   1 root root       92 Jun 10 08:00 hostname', TermColor.white),
  TermLine('-rw-r--r--   1 root root      411 Jun 10 08:00 hosts', TermColor.white),
  TermLine('drwxr-xr-x   2 root root     4096 Jun  8 11:20 nginx', TermColor.cyan),
  TermLine('-rw-r--r--   1 root root     1748 Jun  5 09:12 passwd', TermColor.white),
  TermLine('-rw-r-----   1 root shadow   1284 Jun  5 09:12 shadow', TermColor.red),
  TermLine('drwx------   2 root root     4096 Jun  8 11:20 ssl', TermColor.cyan),
  TermLine('drwxr-xr-x   2 root root     4096 Jun  8 11:20 ssh', TermColor.cyan),
  TermLine('-rw-r--r--   1 root root     2355 Jun  5 09:12 sudoers', TermColor.white),
  TermLine('drwxr-xr-x   4 root root     4096 Jun  8 11:20 systemd', TermColor.cyan),
  TermLine('', TermColor.white),
  TermLine('\$ ls -la /tmp/', TermColor.green),
  TermLine('total 32', TermColor.white),
  TermLine('drwxrwxrwt  8 root  root  4096 Jun 10 14:20 .', TermColor.yellow),
  TermLine('drwxr-xr-x 24 root  root  4096 May 15 09:00 ..', TermColor.white),
  TermLine('-rw-------  1 admin admin 1234 Jun 10 14:18 sess_a1b2c3', TermColor.white),
  TermLine('drwxr-xr-x  2 admin admin 4096 Jun 10 14:10 build-cache', TermColor.cyan),
  TermLine('', TermColor.white),
  TermLine('\$ stat /usr/bin/sudo', TermColor.green),
  TermLine('  File: /usr/bin/sudo', TermColor.white),
  TermLine('  Size: 232416    Blocks: 456        IO Block: 4096   regular file', TermColor.white),
  TermLine('Access: (4755/-rwsr-xr-x)  Uid: (    0/    root)   Gid: (    0/    root)', TermColor.red),
  TermLine('Access: 2024-06-10 14:23:01.000000000 +0200', TermColor.gray),
  TermLine('Modify: 2024-05-15 09:00:00.000000000 +0200', TermColor.gray),
  TermLine('Change: 2024-05-15 09:00:00.000000000 +0200', TermColor.gray),
  TermLine(' Birth: 2024-05-15 09:00:00.000000000 +0200', TermColor.gray),
  TermLine('', TermColor.white),
  TermLine('# SUID bit (s) = le processus s\'exécute avec les droits de root', TermColor.yellow),
  TermLine('# Sticky bit (t) sur /tmp = seul le propriétaire peut supprimer ses fichiers', TermColor.yellow),
];

// ─── Widget principal ────────────────────────────────────────

enum _StepState { future, active, done }

class LinuxSimulator extends StatefulWidget {
  const LinuxSimulator({super.key});

  @override
  State<LinuxSimulator> createState() => _LinuxSimulatorState();
}

class _LinuxSimulatorState extends State<LinuxSimulator> {
  int _scenarioIndex = 0;
  int _currentStep = -1;
  bool _running = false;
  Timer? _timer;
  final ScrollController _scrollCtrl = ScrollController();

  // Terminal keys for each panel
  final GlobalKey<TerminalEmulatorState> _bootTermKey = GlobalKey();
  final GlobalKey<TerminalEmulatorState> _netTermKey = GlobalKey();
  final GlobalKey<TerminalEmulatorState> _permTermKey = GlobalKey();
  final GlobalKey<TerminalEmulatorState> _processTermKey = GlobalKey();

  bool _bootStarted = false;
  bool _topRunning = false;
  Timer? _topTimer;
  int _topTick = 0;

  // Network panel state
  int _netCmd = -1;

  _Scenario get _scenario => _linuxScenarios[_scenarioIndex];

  @override
  void dispose() {
    _timer?.cancel();
    _topTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _selectScenario(int index) {
    _timer?.cancel();
    _topTimer?.cancel();
    setState(() {
      _scenarioIndex = index;
      _currentStep = -1;
      _running = false;
      _bootStarted = false;
      _topRunning = false;
      _topTick = 0;
      _netCmd = -1;
    });
  }

  // ── Boot simulation ───────────────────────────────────────

  Future<void> _startBoot() async {
    if (_bootStarted) return;
    setState(() => _bootStarted = true);
    final term = _bootTermKey.currentState;
    if (term == null) return;
    term.clear();
    await term.playLines(_bootLines(), delayMs: 55);
  }

  void _resetBoot() {
    _bootTermKey.currentState?.stop();
    _bootTermKey.currentState?.clear();
    setState(() => _bootStarted = false);
  }

  // ── Process monitor (top) ─────────────────────────────────

  void _toggleTop() {
    if (_topRunning) {
      _topTimer?.cancel();
      setState(() => _topRunning = false);
    } else {
      setState(() => _topRunning = true);
      _refreshTop();
      _topTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!mounted) return;
        _refreshTop();
      });
    }
  }

  void _refreshTop() {
    final term = _processTermKey.currentState;
    if (term == null) return;
    term.clear();
    _topTick++;
    term.addLines(_topLines(_topTick));
  }

  // ── Network commands ──────────────────────────────────────

  Future<void> _runNetCmd(int index) async {
    if (_netCmd >= 0) return;
    setState(() => _netCmd = index);
    final term = _netTermKey.currentState;
    if (term == null) return;
    term.clear();
    final List<List<TermLine>> cmds = [
      _pingLines(),
      _ipAddrLines(),
      _tracerouteLines(),
      _ssLines(),
      _iptablesLines(),
    ];
    await term.playLines(cmds[index], delayMs: 70);
    setState(() => _netCmd = -1);
  }

  // ── Permissions ───────────────────────────────────────────

  Future<void> _showPerms() async {
    final term = _permTermKey.currentState;
    if (term == null) return;
    term.clear();
    await term.playLines(_permLines(), delayMs: 50);
  }

  // ── Step simulation ───────────────────────────────────────

  Future<void> _startSimulation() async {
    if (_running) return;
    setState(() {
      _running = true;
      _currentStep = -1;
    });

    for (int i = 0; i < _scenario.steps.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() => _currentStep = i);
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
      await Future.delayed(const Duration(milliseconds: 900));
    }

    if (mounted) setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _currentStep = -1;
      _running = false;
    });
  }

  void _openAIPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF0F1218),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SimulatorAIAssistant(
          topic: 'Architecture & Linux',
          accentColor: _scenario.color,
          systemPrompt:
              'Tu es Ghost, l\'expert système de T2DECODE. Ta mission est d\'expliquer la technique avec passion et pédagogie. '
              'Sois sympa, utilise un ton encourageant, mais reste extrêmement précis techniquement. Ne sois jamais sec. '
              'Tu connais parfaitement l\'architecture en 7 couches (Hardware > Kernel > Drivers > OS > Libs > Middleware > App). '
              'Contexte : ${_scenario.name}. '
              'Maîtrise : Boot sequence (POST/GRUB/Kernel), systemd PID 1, VFS (Ext4/Inodes), signaux POSIX, Stack réseau Linux, permissions.',
          suggestedQuestions: const [
            'Explique-moi les 7 couches de l\'informatique ?',
            'Comment retenir ces couches avec un mémo ?',
            'C\'est quoi le rôle exact du Kernel ?',
            'Différence entre Hardware et Firmware ?',
            'Comment fonctionne le boot Linux ?',
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LabNotice(
              title: 'Simulation pédagogique',
              message:
                  'Scénarios explicatifs locaux. Aucune commande réelle exécutée.',
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 12),
            _buildScenarioPicker(),
            const SizedBox(height: 12),
            _buildInteractivePanel(),
            const SizedBox(height: 12),
            _buildScenarioHeader(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _scenario.steps.length,
                itemBuilder: (context, i) => _buildStepCard(i),
              ),
            ),
            _buildControls(),
          ],
        ),
        Positioned(
          bottom: 70,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'linux_ai_fab',
            onPressed: _openAIPanel,
            backgroundColor: _scenario.color.withValues(alpha: 0.9),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('IA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractivePanel() {
    switch (_scenarioIndex) {
      case 0: return _buildBootPanel();
      case 1: return _buildFsPanel();
      case 2: return _buildProcessPanel();
      case 3: return _buildNetworkPanel();
      case 4: return _buildPermPanel();
      case 5: return _buildBashPanel();
      default: return const SizedBox.shrink();
    }
  }

  Widget _termBtn(String label, Color color, VoidCallback? onTap, {bool active = false}) {
    final Color bgColor;
    if (active) {
      bgColor = color.withValues(alpha: 0.25);
    } else if (onTap != null) {
      bgColor = color.withValues(alpha: 0.12);
    } else {
      bgColor = TdcColors.textPrimary.withValues(alpha: 0.03);
    }

    final Color borderColor;
    if (active) {
      borderColor = color;
    } else if (onTap != null) {
      borderColor = color.withValues(alpha: 0.4);
    } else {
      borderColor = TdcColors.border;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap != null || active ? color : TdcColors.textMuted,
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 0 – Boot sequence — real dmesg/systemd output ────────────
  Widget _buildBootPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _termBtn('Power On', TdcColors.success, _bootStarted ? null : _startBoot),
              const SizedBox(width: 8),
              _termBtn('Reset', TdcColors.textMuted, _resetBoot),
              const Spacer(),
              if (_bootStarted && _bootTermKey.currentState?.isPlaying == true)
                const Row(children: [
                  SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: TdcColors.success)),
                  SizedBox(width: 6),
                  Text('Booting…', style: TextStyle(color: TdcColors.textTertiary, fontSize: 10)),
                ]),
            ],
          ),
          const SizedBox(height: 8),
          TerminalEmulator(
            key: _bootTermKey,
            title: 'tty1 — Linux Boot',
            accentColor: TdcColors.success,
            height: 300,
          ),
        ],
      ),
    );
  }

  // 1 – Filesystem — real interactive shell ──────────────────
  Widget _buildFsPanel() {
    return const SizedBox(
      height: 300,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: InteractiveTerminal(
          hostname: 't2decode',
          username: 'admin',
        ),
      ),
    );
  }

  // 2 – Processus — real `top` output ────────────────────────
  Widget _buildProcessPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _termBtn(_topRunning ? 'q (quit)' : 'top', TdcColors.warning, _toggleTop, active: _topRunning),
              const Spacer(),
              if (_topRunning)
                const Row(children: [
                  SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: TdcColors.warning)),
                  SizedBox(width: 6),
                  Text('Refreshing every 2s', style: TextStyle(color: TdcColors.textTertiary, fontSize: 10)),
                ]),
            ],
          ),
          const SizedBox(height: 8),
          TerminalEmulator(
            key: _processTermKey,
            title: 'admin@t2decode: top',
            accentColor: TdcColors.warning,
            height: 340,
          ),
        ],
      ),
    );
  }

  // 3 – Réseau — real command outputs ────────────────────────
  Widget _buildNetworkPanel() {
    final cmds = ['ping', 'ip addr', 'traceroute', 'ss', 'iptables'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: List.generate(cmds.length, (i) {
              return _termBtn(cmds[i], TdcColors.info, _netCmd >= 0 ? null : () => _runNetCmd(i));
            }),
          ),
          const SizedBox(height: 8),
          TerminalEmulator(
            key: _netTermKey,
            title: 'admin@t2decode: ~',
            accentColor: TdcColors.info,
            height: 320,
          ),
        ],
      ),
    );
  }

  // 4 – Permissions — real ls -la + stat output ──────────────
  Widget _buildPermPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _termBtn('ls -la /etc/', TdcColors.danger, () => _showPerms()),
              const SizedBox(width: 8),
              _termBtn('Clear', TdcColors.textMuted, () => _permTermKey.currentState?.clear()),
            ],
          ),
          const SizedBox(height: 8),
          TerminalEmulator(
            key: _permTermKey,
            title: 'root@t2decode: /etc',
            accentColor: TdcColors.danger,
            height: 320,
          ),
        ],
      ),
    );
  }

  // 5 – Bash terminal — fully interactive ────────────────────
  Widget _buildBashPanel() {
    return const SizedBox(
      height: 300,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: InteractiveTerminal(
          hostname: 't2decode-lab',
          username: 'student',
        ),
      ),
    );
  }

  Widget _buildScenarioPicker() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _linuxScenarios.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final s = _linuxScenarios[i];
          final selected = i == _scenarioIndex;
          return GestureDetector(
            onTap: () => _selectScenario(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? s.color.withValues(alpha: 0.18) : TdcColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? s.color : TdcColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    s.icon,
                    color: selected ? s.color : TdcColors.textMuted,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: TextStyle(
                          color: selected ? s.color : TdcColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        s.subtitle,
                        style: const TextStyle(
                          color: TdcColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScenarioHeader() {
    final s = _scenario;
    final done = _currentStep >= s.steps.length - 1 && !_running;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: s.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: s.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(s.icon, color: s.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: TextStyle(
                      color: s.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    s.subtitle,
                    style: const TextStyle(
                      color: TdcColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_currentStep >= 0)
              Text(
                done ? '✓ Terminé' : '${_currentStep + 1}/${s.steps.length}',
                style: TextStyle(
                  color: done ? TdcColors.success : s.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(int index) {
    final step = _scenario.steps[index];
    final state = _getStepState(index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: state == _StepState.future ? 0.35 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: state == _StepState.active
                ? step.color.withValues(alpha: 0.12)
                : TdcColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state == _StepState.active
                  ? step.color
                  : state == _StepState.done
                      ? step.color.withValues(alpha: 0.35)
                      : TdcColors.border,
              width: state == _StepState.active ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _buildStepNumber(index, step, state),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: TextStyle(
                                    color: state != _StepState.future
                                        ? TdcColors.textPrimary
                                        : TdcColors.textMuted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: step.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  step.protocol,
                                  style: TextStyle(
                                    color: step.color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.description,
                            style: const TextStyle(
                              color: TdcColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (state != _StepState.future)
                _buildStepDetail(step, state)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.05, end: 0, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepNumber(int index, _Step step, _StepState state) {
    if (state == _StepState.active && _running) {
      return SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: step.color,
              ),
            ),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: step.color.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state == _StepState.done
            ? step.color.withValues(alpha: 0.2)
            : state == _StepState.active
                ? step.color.withValues(alpha: 0.25)
                : TdcColors.surfaceAlt,
        border: Border.all(
          color: state == _StepState.future ? TdcColors.border : step.color,
        ),
      ),
      child: state == _StepState.done
          ? Icon(Icons.check, color: step.color, size: 16)
          : Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: state == _StepState.future
                      ? TdcColors.textMuted
                      : step.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
    );
  }

  Widget _buildStepDetail(_Step step, _StepState state) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: step.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.detail,
            style: const TextStyle(
              color: TdcColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (step.visual != null) ...[
            const SizedBox(height: 12),
            step.visual!(),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _LinuxRetainButton(
              title: step.title,
              detail: step.detail,
              category: _scenario.name,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final bool finished =
        _currentStep >= _scenario.steps.length - 1 && !_running;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _running
                  ? null
                  : finished
                      ? _reset
                      : _startSimulation,
              icon: _running
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: TdcColors.textPrimary,
                      ),
                    )
                  : Icon(finished ? Icons.refresh : Icons.play_arrow),
              label: Text(
                _running
                    ? 'En cours...'
                    : finished
                        ? 'Recommencer'
                        : 'Lancer la simulation',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _scenario.color,
                foregroundColor: TdcColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (_currentStep >= 0 && !finished) ...[
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TdcColors.textSecondary,
                side: const BorderSide(color: TdcColors.border),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StepState _getStepState(int index) {
    if (_currentStep < 0) return _StepState.future;
    if (index < _currentStep) return _StepState.done;
    if (index == _currentStep) return _StepState.active;
    return _StepState.future;
  }
}

// ─── Bouton "Retenir dans la Cheat Sheet" ────────────────────

class _LinuxRetainButton extends StatefulWidget {
  final String title, detail, category;
  const _LinuxRetainButton({required this.title, required this.detail, required this.category});
  @override State<_LinuxRetainButton> createState() => _LinuxRetainButtonState();
}

class _LinuxRetainButtonState extends State<_LinuxRetainButton> {
  bool _saved = false;
  bool _loading = false;

  Future<void> _retain() async {
    if (_saved || _loading) return;
    setState(() => _loading = true);
    await CheatSheetRepository.saveUserEntry(
      title: widget.title,
      detail: widget.detail,
      category: widget.category,
    );
    if (!mounted) return;
    setState(() { _saved = true; _loading = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('« ${widget.title} » ajouté à la Cheat Sheet ★'),
        backgroundColor: TdcColors.warning,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _retain,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _saved ? TdcColors.warning.withValues(alpha: 0.18) : TdcColors.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _saved ? TdcColors.warning : TdcColors.textMuted),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: TdcColors.warning))
            else
              Icon(_saved ? Icons.bookmark : Icons.bookmark_border, color: _saved ? TdcColors.warning : TdcColors.textTertiary, size: 13),
            const SizedBox(width: 5),
            Text(
              _saved ? 'Retenu ✓' : 'Retenir',
              style: TextStyle(
                color: _saved ? TdcColors.warning : TdcColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
