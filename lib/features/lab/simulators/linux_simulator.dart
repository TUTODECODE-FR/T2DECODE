// ============================================================
// Linux Simulator
// Explications théoriques interactives et animées :
//   • Démarrage du système (boot)
//   • Système de fichiers Linux
//   • Processus & Signaux
//   • Réseau sous Linux
//   • Droits & Sécurité
//   • Scripting Bash
// ============================================================
import 'dart:async';
import 'package:tutodecode/features/courses/data/cheat_sheet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/lab/widgets/sim_step_card.dart';
import 'package:tutodecode/features/lab/widgets/lab_widgets.dart';
import 'package:tutodecode/features/lab/widgets/simulator_ai_assistant.dart';

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
    color: const Color(0xFF22C55E),
    steps: [
      const _Step(
        title: 'BIOS/UEFI POST',
        protocol: 'Firmware',
        icon: Icons.memory,
        color: Color(0xFF94A3B8),
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
        color: const Color(0xFFF59E0B),
        description: 'GRUB présente le menu et charge le noyau + initramfs.',
        detail:
            'GRUB2 lit sa configuration dans /boot/grub/grub.cfg. Il charge en mémoire '
            'deux fichiers : vmlinuz (le noyau compressé, typiquement bzImage) et '
            'initrd.img (le système de fichiers temporaire initial).\n'
            'GRUB passe au noyau une ligne de commande (kernel cmdline) contenant '
            'root=UUID=..., quiet, splash et d\'autres paramètres. '
            'On peut l\'éditer au boot avec "e" pour du debug ou du rescue.',
        visual: () => SimFlowDiagram(
          color: const Color(0xFFF59E0B),
          nodes: const [
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
        color: Color(0xFF8B5CF6),
        description: 'Le noyau se décompresse et monte le système de fichiers temporaire.',
        detail:
            'Le noyau se décompresse lui-même en RAM (self-extracting bzImage). '
            'Il initialise la MMU, détecte les CPUs (SMP), configure les interruptions (IDT/GDT) '
            'et monte l\'initramfs (cpio.gz) comme rootfs temporaire en tmpfs.\n'
            'L\'initramfs contient les modules nécessaires pour accéder au vrai disque '
            '(pilotes SATA/NVMe, dm-crypt pour LUKS, LVM). Une fois le vrai rootfs monté, '
            'init pivot_root vers lui et démonte l\'initramfs.',
      ),
      _Step(
        title: 'systemd PID 1',
        protocol: 'systemd',
        icon: Icons.settings,
        color: const Color(0xFF06B6D4),
        description: 'Le premier processus utilisateur, ancêtre de tous les autres.',
        detail:
            'systemd est lancé en tant que PID 1 — s\'il meurt, le kernel panique. '
            'Il lit /etc/systemd/system.conf et parcourt les units (.service, .socket, .mount, .target) '
            'pour construire un graphe de dépendances.\n'
            'systemd active en parallèle tous les services dont les dépendances sont satisfaites, '
            'ce qui accélère considérablement le boot par rapport à l\'ancien SysVinit séquentiel. '
            'journald est également démarré pour capturer les logs dès le début.',
        visual: () => const SimLayerStack(
          layers: [
            SimLayer('sysinit.target', 'montage fs, udev, cryptsetup', Color(0xFFEF4444)),
            SimLayer('basic.target', 'timers, sockets, paths', Color(0xFFF97316)),
            SimLayer('network.target', 'NetworkManager, networkd', Color(0xFF06B6D4)),
            SimLayer('multi-user.target', 'runlevel 3 — sshd, cron…', Color(0xFF3B82F6)),
            SimLayer('graphical.target', 'runlevel 5 — GDM/SDDM', Color(0xFF22C55E)),
          ],
        ),
      ),
      const _Step(
        title: 'Targets & Services',
        protocol: 'Units',
        icon: Icons.account_tree,
        color: Color(0xFF10B981),
        description: 'Les targets orchestrent l\'activation des services.',
        detail:
            'Les targets systemd remplacent les runlevels SysV : '
            'multi-user.target (runlevel 3), graphical.target (runlevel 5). '
            'Chaque service déclare After=, Requires=, Wants= pour exprimer ses dépendances.\n'
            'Des services critiques sont activés : udev (détection matériel), '
            'NetworkManager ou systemd-networkd, dbus, sshd, etc. '
            'La commande systemctl list-units --failed permet de voir les services en erreur.',
      ),
      const _Step(
        title: 'Login prompt',
        protocol: 'getty / PAM',
        icon: Icons.login,
        color: Color(0xFF22C55E),
        description: 'Le terminal ou l\'interface graphique invite l\'utilisateur à se connecter.',
        detail:
            'Sur un TTY, systemd lance getty (agetty) qui affiche le prompt login:. '
            'L\'authentification passe par PAM (Pluggable Authentication Modules) : '
            'pam_unix vérifie le mot de passe contre /etc/shadow (hash SHA-512 ou yescrypt), '
            'pam_limits applique les limites (ulimit), pam_env charge l\'environnement.\n'
            'En mode graphique, un display manager (GDM, SDDM, LightDM) gère la session Wayland/X11. '
            'Après authentification, le shell de l\'utilisateur (.bashrc, .profile) est sourcé.',
      ),
    ],
  ),

  // ── 2. Système de fichiers ──────────────────────────────────
  _Scenario(
    name: 'Système de fichiers',
    subtitle: 'VFS, inodes, permissions',
    icon: Icons.folder_open,
    color: const Color(0xFFF97316),
    steps: [
      const _Step(
        title: 'Tout est fichier (VFS)',
        protocol: 'VFS',
        icon: Icons.device_hub,
        color: Color(0xFF94A3B8),
        description: 'Le Virtual File System abstrait tous les types de ressources.',
        detail:
            'La philosophie Unix "everything is a file" est implémentée via le VFS du noyau. '
            'Les périphériques (/dev/sda), les processus (/proc/1234), le matériel (/sys/class/net), '
            'les sockets réseau et les pipes sont tous accessibles via les mêmes appels système : '
            'open(), read(), write(), close(), ioctl().\n'
            'Le VFS définit des interfaces (inode_operations, file_operations) que chaque '
            'système de fichiers concret (ext4, xfs, btrfs, tmpfs) implémente.',
      ),
      _Step(
        title: 'Arborescence / (FHS)',
        protocol: 'FHS 3.0',
        icon: Icons.account_tree,
        color: const Color(0xFFF59E0B),
        description: 'Le Filesystem Hierarchy Standard définit la structure des répertoires.',
        detail:
            'Les répertoires principaux et leur rôle :\n'
            '/bin, /sbin → binaires essentiels (souvent liens vers /usr/bin aujourd\'hui)\n'
            '/etc → configuration système\n'
            '/var → données variables (logs, spool, cache)\n'
            '/tmp → temporaire (vidé au reboot sur tmpfs)\n'
            '/home → répertoires utilisateurs\n'
            '/proc, /sys → pseudo-filesystems noyau\n'
            '/dev → fichiers de périphériques (udev)\n'
            '/boot → noyau et bootloader\n'
            '/lib, /usr → bibliothèques et programmes',
        visual: () => const SimTreeDiagram(
          color: Color(0xFFF59E0B),
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
        color: Color(0xFF8B5CF6),
        description: 'Un fichier = un inode + des blocs de données.',
        detail:
            'Un inode stocke les métadonnées d\'un fichier : UID/GID propriétaires, '
            'permissions (mode), timestamps (atime/mtime/ctime), taille, et les pointeurs '
            'vers les blocs de données (direct, indirect, doubly/triply indirect en ext4, '
            'ou extents pour les fichiers contigus).\n'
            'Le nom du fichier n\'est PAS dans l\'inode — il est dans l\'entrée du répertoire '
            'parent (dentry) qui mappe nom → numéro d\'inode. C\'est pourquoi les hard links '
            'pointent sur le même inode : stat(1) montre le même inode number.',
      ),
      const _Step(
        title: 'Montage (mount)',
        protocol: 'mount / fstab',
        icon: Icons.layers,
        color: Color(0xFF06B6D4),
        description: 'Attacher un système de fichiers à l\'arborescence.',
        detail:
            'mount(2) attache un block device (ex: /dev/sda2) ou un type spécial (tmpfs, '
            'proc) sur un répertoire existant appelé point de montage.\n'
            '/etc/fstab liste les montages permanents avec UUID, type, options (ro/rw, '
            'noexec, nosuid, relatime) et priorité fsck.\n'
            'systemd génère des units .mount depuis fstab. Les bind mounts permettent '
            'd\'exposer un sous-répertoire à un autre chemin — très utilisé dans les '
            'conteneurs (namespaces de mount).',
      ),
      _Step(
        title: 'Permissions UNIX (rwx)',
        protocol: 'chmod / ACL',
        icon: Icons.lock,
        color: const Color(0xFF10B981),
        description: 'Contrôle d\'accès propriétaire/groupe/autres.',
        detail:
            'Chaque fichier a 3 triplets rwx : propriétaire (u), groupe (g), autres (o). '
            'Chaque permission est un bit : r=4, w=2, x=1. chmod 755 = rwxr-xr-x.\n'
            'Pour les répertoires : r=lister, w=créer/supprimer, x=traverser (cd). '
            'Sans x sur un répertoire parent, impossible d\'accéder à son contenu même '
            'si les permissions du fichier le permettent.\n'
            'Les ACL POSIX (setfacl/getfacl) permettent des règles plus fines par utilisateur.',
        visual: () => SimCodeBlock(
          color: const Color(0xFF10B981),
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
        color: Color(0xFFF97316),
        description: 'L\'interface entre le noyau et l\'espace utilisateur.',
        detail:
            '/proc expose l\'état des processus (/proc/PID/maps, /proc/PID/fd), '
            'des statistiques système (/proc/meminfo, /proc/cpuinfo, /proc/net/dev) '
            'et des paramètres noyau (/proc/sys/ = sysctl). Les écritures modifient '
            'le comportement noyau en live (ex: echo 1 > /proc/sys/net/ipv4/ip_forward).\n'
            '/sys (sysfs) expose la topologie matérielle (PCI, USB, blocs, réseau) '
            'sous forme d\'attributs lisibles/modifiables. Udev l\'utilise pour créer '
            '/dev automatiquement lors de la détection des périphériques.',
      ),
    ],
  ),

  // ── 3. Processus & Signaux ─────────────────────────────────
  _Scenario(
    name: 'Processus & Signaux',
    subtitle: 'fork, scheduler, IPC',
    icon: Icons.memory,
    color: const Color(0xFF3B82F6),
    steps: [
      const _Step(
        title: 'fork() + exec()',
        protocol: 'syscall',
        icon: Icons.call_split,
        color: Color(0xFF94A3B8),
        description: 'Tout processus naît d\'un fork, tout programme naît d\'un exec.',
        detail:
            'fork(2) duplique le processus courant via le mécanisme Copy-on-Write (COW) : '
            'les pages mémoire sont partagées en lecture seule jusqu\'à la première écriture, '
            'évitant une copie immédiate coûteuse. Le père reçoit le PID fils, le fils reçoit 0.\n'
            'exec(3) remplace l\'image mémoire du processus par un nouveau programme '
            '(lit l\'ELF, mappe les segments, initialise la pile). '
            'Le shell combine les deux : fork() → le fils fait exec(commande) → '
            'le père wait(2) la terminaison.',
      ),
      _Step(
        title: 'États processus (R/S/D/Z)',
        protocol: 'task_struct',
        icon: Icons.bar_chart,
        color: const Color(0xFFF59E0B),
        description: 'Les états de vie d\'un processus dans le noyau.',
        detail:
            'R (Running/Runnable) : en cours d\'exécution ou prêt dans la run queue.\n'
            'S (Sleeping, interruptible) : attend un événement, réveillable par signal — '
            'c\'est l\'état le plus courant (ex: attente I/O réseau).\n'
            'D (Sleeping, uninterruptible) : attente I/O disque, NE PEUT PAS être tué — '
            'un processus bloqué en D souvent indique un problème NFS ou I/O.\n'
            'Z (Zombie) : terminé mais le père n\'a pas encore appelé wait() — '
            'l\'entrée dans la table des processus subsiste pour transmettre le code retour.',
        visual: () => SimFlowDiagram(
          color: const Color(0xFFF59E0B),
          nodes: const [
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
        color: Color(0xFF8B5CF6),
        description: 'Le Completely Fair Scheduler répartit équitablement le CPU.',
        detail:
            'Le CFS (Linux 2.6.23+) utilise un red-black tree trié par vruntime '
            '(temps CPU virtuel normalisé par la priorité). Il choisit toujours la tâche '
            'au vruntime le plus faible, garantissant l\'équité.\n'
            'nice values (-20 à +19) ajustent les poids. cgroups v2 permettent des '
            'quotas CPU par groupe (cpu.max = 50000 100000 = 50% d\'un core).\n'
            'SCHED_FIFO et SCHED_RR sont des politiques temps-réel (soft RT) '
            'pour les processus critiques à faible latence.',
      ),
      const _Step(
        title: 'Signaux (SIGTERM/SIGKILL)',
        protocol: 'kill(2)',
        icon: Icons.warning_amber,
        color: Color(0xFFEF4444),
        description: 'Communication asynchrone entre processus et noyau.',
        detail:
            'Les signaux sont des notifications asynchrones envoyées à un processus. '
            'SIGTERM (15) : demande de terminaison propre, le processus peut l\'attraper '
            'et faire un cleanup (fermer fichiers, libérer ressources).\n'
            'SIGKILL (9) : terminaison forcée par le noyau, IMPOSSIBLE à intercepter ni ignorer. '
            'SIGHUP (1) : historiquement "raccrochage terminal", utilisé pour recharger la config. '
            'SIGSEGV (11) : accès mémoire invalide → core dump. '
            'kill -l liste les 64 signaux standard + temps-réel (SIGRTMIN à SIGRTMAX).',
      ),
      const _Step(
        title: 'Pipes & IPC',
        protocol: 'pipe / socket',
        icon: Icons.swap_horiz,
        color: Color(0xFF06B6D4),
        description: 'Communication inter-processus via pipes, sockets, mémoire partagée.',
        detail:
            'Pipe anonyme (|) : buffer noyau unidirectionnel entre deux fd. '
            'ls | grep .dart crée un pipe : stdout de ls → stdin de grep. '
            'Capacité ~64KB sur Linux ; write() bloque si plein, read() bloque si vide.\n'
            'FIFO (named pipe) : pipe avec un nom dans le filesystem.\n'
            'Unix Domain Socket : full-duplex, plus rapide que TCP loopback (pas de stack IP).\n'
            'Shared Memory (shm_open / mmap) : le plus rapide, les processus partagent '
            'des pages physiques — synchronisation via sémaphores POSIX ou futex.',
      ),
      const _Step(
        title: 'Namespaces & cgroups',
        protocol: 'containers',
        icon: Icons.grid_view,
        color: Color(0xFF3B82F6),
        description: 'Les briques fondamentales des conteneurs Linux.',
        detail:
            'Les namespaces isolent les ressources système par processus :\n'
            'pid → arbre de processus isolé (PID 1 dans le conteneur)\n'
            'net → interface réseau, table de routage, sockets dédiées\n'
            'mnt → arborescence de montage indépendante\n'
            'uts → hostname isolé\n'
            'user → mapping UID/GID (rootless containers)\n'
            'cgroups v2 limitent la consommation : memory.max, cpu.max, io.max. '
            'Docker, podman et LXC combinent namespaces + cgroups + seccomp + '
            'capabilities pour isoler les conteneurs sans hyperviseur.',
      ),
    ],
  ),

  // ── 4. Réseau sous Linux ────────────────────────────────────
  _Scenario(
    name: 'Réseau sous Linux',
    subtitle: 'ip, iptables, sockets',
    icon: Icons.lan,
    color: const Color(0xFF06B6D4),
    steps: [
      const _Step(
        title: 'Interfaces réseau (ip link)',
        protocol: 'netdev',
        icon: Icons.settings_ethernet,
        color: Color(0xFF94A3B8),
        description: 'Lister et configurer les interfaces réseau.',
        detail:
            'ip link show liste toutes les interfaces : eth0, wlan0, lo (loopback 127.0.0.1/8), '
            'veth (virtual ethernet pour conteneurs), bridge, bond (agrégation).\n'
            'ip addr add 192.168.1.10/24 dev eth0 assigne une adresse. '
            'ip link set eth0 up/down active/désactive. '
            'Les interfaces virtuelles veth fonctionnent par paires : ce qui entre dans l\'une '
            'sort de l\'autre — utilisé pour connecter les namespaces réseau aux bridges.',
      ),
      const _Step(
        title: 'Table de routage (ip route)',
        protocol: 'routing',
        icon: Icons.route,
        color: Color(0xFFF59E0B),
        description: 'Décider par où envoyer chaque paquet IP.',
        detail:
            'ip route show affiche la table de routage principale. '
            'Le noyau sélectionne la route la plus spécifique (longest prefix match).\n'
            'La route par défaut (default via 192.168.1.1) est le gateway de dernier recours. '
            'ip route add 10.0.0.0/8 via 172.16.0.1 dev eth1 metric 100 ajoute une route statique.\n'
            'Linux supporte plusieurs tables de routage (ip rule) pour du policy routing : '
            'différentes tables selon l\'IP source, le mark netfilter ou l\'interface entrante.',
      ),
      _Step(
        title: 'iptables / nftables',
        protocol: 'netfilter',
        icon: Icons.shield,
        color: const Color(0xFFEF4444),
        description: 'Filtrage, NAT et manipulation des paquets dans le noyau.',
        detail:
            'Netfilter est le framework noyau de traitement des paquets avec des hooks '
            '(PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING).\n'
            'iptables (legacy) et nftables (moderne, recommandé) définissent des règles '
            'dans des tables (filter, nat, mangle, raw) et des chaînes.\n'
            'Exemple NAT : iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE '
            '(partage de connexion Internet). nftables unifie IPv4/IPv6/ARP/bridge '
            'avec une syntaxe plus lisible et de meilleures performances.',
        visual: () => const SimLayerStack(
          layers: [
            SimLayer('PREROUTING', 'DNAT, routing decision', Color(0xFFEF4444)),
            SimLayer('INPUT', 'paquets pour cet hôte', Color(0xFFF97316)),
            SimLayer('FORWARD', 'paquets routés via cet hôte', Color(0xFFF59E0B)),
            SimLayer('OUTPUT', 'paquets générés localement', Color(0xFF3B82F6)),
            SimLayer('POSTROUTING', 'SNAT, MASQUERADE', Color(0xFF8B5CF6)),
          ],
        ),
      ),
      const _Step(
        title: 'Sockets & ports',
        protocol: 'socket(2)',
        icon: Icons.cable,
        color: Color(0xFF8B5CF6),
        description: 'L\'API d\'abstraction réseau pour les applications.',
        detail:
            'socket(AF_INET, SOCK_STREAM, 0) crée un socket TCP. '
            'bind() associe une adresse/port, listen() accepte les connexions, '
            'accept() retourne un fd par client, connect() côté client.\n'
            'Ports 0-1023 : well-known (80 HTTP, 443 HTTPS, 22 SSH) — nécessitent CAP_NET_BIND_SERVICE. '
            'Ports 1024-49151 : registered. 49152-65535 : éphémères (assignés par l\'OS aux clients).\n'
            'SO_REUSEPORT permet plusieurs processus d\'écouter sur le même port '
            '(load balancing kernel-level, utilisé par Nginx).',
      ),
      const _Step(
        title: 'ss / netstat',
        protocol: 'diagnostics',
        icon: Icons.monitor,
        color: Color(0xFF10B981),
        description: 'Inspecter l\'état des connexions et des sockets.',
        detail:
            'ss (socket statistics) remplace netstat, plus rapide car interroge directement '
            'le noyau via netlink. Commandes utiles :\n'
            'ss -tlnp → sockets TCP en écoute avec PID\n'
            'ss -s → résumé statistique\n'
            'ss -tnp state established → connexions établies\n'
            'tcpdump -i eth0 port 80 -w capture.pcap capture les paquets bruts.\n'
            'Wireshark analyse les .pcap. '
            'strace -e network ./programme trace les appels système réseau d\'un processus.',
      ),
      const _Step(
        title: 'NetworkManager / systemd-networkd',
        protocol: 'netmgmt',
        icon: Icons.wifi,
        color: Color(0xFF06B6D4),
        description: 'Gestion de la configuration réseau au niveau système.',
        detail:
            'NetworkManager est le standard sur les distributions desktop (Fedora, Ubuntu, Debian). '
            'nmcli con show liste les connexions, nmcli device wifi connect SSID configure le WiFi.\n'
            'systemd-networkd est préféré sur les serveurs et dans les conteneurs : '
            'fichiers .network dans /etc/systemd/network/ définissent les interfaces statiques.\n'
            'systemd-resolved gère la résolution DNS avec cache et support DoT/DoH. '
            'resolvectl status montre les DNS actifs par interface. '
            '/etc/resolv.conf pointe généralement vers le stub resolver 127.0.0.53.',
      ),
    ],
  ),

  // ── 5. Droits & Sécurité ───────────────────────────────────
  _Scenario(
    name: 'Droits & Sécurité',
    subtitle: 'UID, sudo, MAC, audit',
    icon: Icons.security,
    color: const Color(0xFFEF4444),
    steps: [
      const _Step(
        title: 'UID/GID root vs utilisateur',
        protocol: 'credentials',
        icon: Icons.person,
        color: Color(0xFF94A3B8),
        description: 'Le modèle d\'identité UNIX basé sur les identifiants numériques.',
        detail:
            'Chaque processus possède real UID (RUID), effective UID (EUID) et saved UID (SUID). '
            'Le noyau vérifie EUID pour les contrôles d\'accès. root = UID 0, '
            'il bypasse la plupart des vérifications de permissions (sauf capabilities et MAC).\n'
            'Les capabilities Linux (cap_net_admin, cap_sys_admin, cap_dac_override…) '
            'découpent les privilèges root en unités fines : un daemon peut avoir '
            'cap_net_bind_service sans être root complet. '
            'capsh --print affiche les capabilities du shell courant.',
      ),
      const _Step(
        title: 'sudo & su',
        protocol: 'PAM / sudoers',
        icon: Icons.admin_panel_settings,
        color: Color(0xFFF59E0B),
        description: 'Élévation de privilèges contrôlée.',
        detail:
            'su - root ouvre un shell root après authentification par le mot de passe root. '
            'sudo exécute une commande avec les privilèges d\'un autre utilisateur (root par défaut) '
            'après authentification par le mot de passe de l\'utilisateur courant.\n'
            '/etc/sudoers (édité avec visudo pour vérification syntaxique) définit les règles : '
            'user ALL=(ALL:ALL) ALL, ou des droits fins : alice Web=(root) NOPASSWD: /bin/systemctl restart nginx.\n'
            'sudo journalise chaque commande. sudo -l liste les droits de l\'utilisateur courant.',
      ),
      _Step(
        title: 'chmod / chown / umask',
        protocol: 'DAC',
        icon: Icons.lock_outline,
        color: const Color(0xFF8B5CF6),
        description: 'Gestion des permissions de fichiers (Discretionary Access Control).',
        detail:
            'chmod modifie les bits de permission : chmod u+x, chmod 644, chmod -R 755 dir/.\n'
            'chown user:group file transfère la propriété. '
            'Seul root peut changer le propriétaire (évite l\'escalade de privilèges).\n'
            'umask définit les permissions retirées à la création : '
            'umask 022 → fichiers créés en 644 (666-022), répertoires en 755 (777-022). '
            'Un umask plus restrictif (027) est recommandé en production : '
            'les autres (o) n\'ont aucun droit par défaut.',
        visual: () => const SimKeyValue(
          color: Color(0xFF8B5CF6),
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
        color: Color(0xFFEF4444),
        description: 'Les bits spéciaux qui modifient le comportement des permissions.',
        detail:
            'SUID (Set-User-ID) sur un exécutable : le processus tourne avec EUID = propriétaire '
            'du fichier, pas de l\'appelant. Ex: /usr/bin/passwd est SUID root → '
            'peut écrire dans /etc/shadow. find / -perm -4000 liste les SUID binaires.\n'
            'SGID sur répertoire : les nouveaux fichiers héritent du groupe du répertoire '
            '(utile pour les répertoires collaboratifs).\n'
            'Sticky bit (/tmp) : seul le propriétaire d\'un fichier peut le supprimer '
            'même si le répertoire est writable par tous. ls -la affiche "t" en position x des autres.',
      ),
      const _Step(
        title: 'SELinux / AppArmor (MAC)',
        protocol: 'LSM',
        icon: Icons.verified_user,
        color: Color(0xFF10B981),
        description: 'Contrôle d\'accès obligatoire au-dessus des permissions UNIX.',
        detail:
            'Les Linux Security Modules (LSM) ajoutent une couche MAC (Mandatory Access Control) '
            'que même root ne peut pas contourner. Chaque accès passe par des hooks LSM.\n'
            'SELinux (Red Hat/Fedora) utilise des labels (contextes) sur fichiers et processus. '
            'Une règle type_enforcement autorise domain → type:class:permission. '
            'getenforce (Enforcing/Permissive/Disabled), audit2allow génère des règles depuis les refus.\n'
            'AppArmor (Ubuntu/Debian) utilise des profils par chemin de programme '
            '(plus simple à écrire). aa-status liste les profils actifs. '
            'Les deux bloquent les exploits même après compromission d\'un service.',
      ),
      const _Step(
        title: 'Audit & journald',
        protocol: 'auditd / journald',
        icon: Icons.receipt_long,
        color: Color(0xFFEF4444),
        description: 'Traçabilité et centralisation des événements de sécurité.',
        detail:
            'auditd collecte les événements noyau (appels système, accès fichiers, connexions réseau) '
            'via le sous-système audit. ausearch -k passwd_changes, aureport -au pour l\'analyse.\n'
            'journald (systemd-journald) collecte les logs de tous les services, '
            'du noyau (kmsg) et de systemd. journalctl -u sshd -f suit les logs SSH. '
            'journalctl --since "1 hour ago" --priority=err filtre les erreurs récentes.\n'
            'Pour la conformité, rsyslog ou syslog-ng peuvent centraliser les logs vers '
            'un serveur distant (SIEM). logrotate gère la rotation et la compression.',
      ),
    ],
  ),

  // ── 6. Scripting Bash ──────────────────────────────────────
  _Scenario(
    name: 'Scripting Bash',
    subtitle: 'Du shebang aux pièges avancés',
    icon: Icons.terminal,
    color: const Color(0xFFA855F7),
    steps: [
      const _Step(
        title: 'Shebang & interpréteur',
        protocol: '#!',
        icon: Icons.code,
        color: Color(0xFF94A3B8),
        description: 'La première ligne qui désigne l\'interpréteur du script.',
        detail:
            '#!/usr/bin/env bash est préféré à #!/bin/bash car env recherche bash dans le PATH, '
            'garantissant la portabilité (bash peut être dans /usr/local/bin sur macOS).\n'
            'Le noyau lit les deux premiers octets (#!) et exécute le programme indiqué '
            'avec le script comme argument. chmod +x script.sh puis ./script.sh suffit.\n'
            'set -euo pipefail en début de script est une bonne pratique : '
            '-e arrête sur erreur, -u traite les variables indéfinies comme erreur, '
            '-o pipefail propage les erreurs dans les pipes.',
      ),
      _Step(
        title: 'Variables & expansions',
        protocol: 'parameter expansion',
        icon: Icons.data_object,
        color: const Color(0xFFF59E0B),
        description: 'Manipuler les données avec les expansions Bash.',
        detail:
            'VAR="valeur" (pas d\'espaces autour de =). '
            '\${VAR} expansion simple, toujours entre guillemets pour éviter word splitting.\n'
            '\${VAR:-défaut} → valeur ou défaut si vide. '
            '\${#VAR} → longueur. \${VAR#prefix} → supprime prefix. '
            '\${VAR/old/new} → remplacement. \${VAR^^} → majuscules.\n'
            'Arrays : arr=(a b c), \${arr[1]}=b, \${arr[@]}=tous, \${#arr[@]}=taille. '
            'Substitution de commande : result=\$(commande) (préfère \$() à `backticks`). '
            'Arithmétique : ((count++)), \$(( 2 ** 10 ))=1024.',
        visual: () => SimCodeBlock(
          color: const Color(0xFFF59E0B),
          title: 'Bash',
          code: '#!/usr/bin/env bash\n'
              'set -euo pipefail\n'
              '\n'
              'NAME="World"\n'
              'echo "Hello, \${NAME}!"\n'
              '\n'
              '# Valeur par défaut\n'
              'PORT=\${PORT:-8080}\n'
              '\n'
              '# Longueur de chaine\n'
              'echo \${#NAME}  # 5\n'
              '\n'
              '# Substitution de commande\n'
              'DATE=\$(date +%Y-%m-%d)',
        ),
      ),
      _Step(
        title: 'Structures if / for / while',
        protocol: 'control flow',
        icon: Icons.account_tree,
        color: const Color(0xFF8B5CF6),
        description: 'Contrôler le flux d\'exécution du script.',
        detail:
            'if [[ condition ]]; then ... elif ...; else ...; fi\n'
            '[[ ]] est préféré à [ ] : supporte &&, ||, =~, pas de word splitting.\n'
            'Tests utiles : -f file (fichier), -d dir, -z str (vide), -n str (non vide), '
            '-eq/-ne/-lt/-gt pour les entiers.\n'
            'for f in *.log; do gzip "\$f"; done\n'
            'for ((i=0; i<10; i++)); do echo \$i; done\n'
            'while IFS= read -r line; do ...; done < fichier.txt '
            '(lire un fichier ligne par ligne sans perdre les espaces).',
        visual: () => SimCodeBlock(
          color: const Color(0xFF8B5CF6),
          title: 'Bash',
          code: '# if/elif/else\n'
              'if [[ -f "\$FILE" ]]; then\n'
              '  echo "exists"\n'
              'elif [[ -d "\$FILE" ]]; then\n'
              '  echo "is a dir"\n'
              'fi\n'
              '\n'
              '# for loop\n'
              'for i in \$(seq 1 5); do\n'
              '  echo "item \$i"\n'
              'done\n'
              '\n'
              '# while read\n'
              'while IFS= read -r line; do\n'
              '  echo "\$line"\n'
              'done < input.txt',
        ),
      ),
      const _Step(
        title: 'Fonctions & sous-shells',
        protocol: 'functions',
        icon: Icons.functions,
        color: Color(0xFF06B6D4),
        description: 'Structurer le code en fonctions réutilisables.',
        detail:
            'function ma_fonction() { ... } ou ma_fonction() { ... } (les deux syntaxes valides).\n'
            'Arguments : \$1, \$2, ..., \$@ (tous), \$# (nombre), \$0 (nom du script).\n'
            'return N pour le code de retour (0=succès). '
            'local var=valeur pour les variables locales (évite la pollution de scope).\n'
            'Sous-shell (cmd1 ; cmd2) : fork sans exec, hérite l\'environnement mais '
            'les modifications (cd, variables) ne remontent pas au parent. '
            'export VAR rend une variable visible dans les sous-processus (env hérité).',
      ),
      const _Step(
        title: 'Pipes & redirections',
        protocol: 'I/O redirection',
        icon: Icons.arrow_forward,
        color: Color(0xFF10B981),
        description: 'Rediriger les flux stdin, stdout, stderr.',
        detail:
            'cmd > fichier : redirige stdout (crée/écrase). >> : append.\n'
            'cmd 2> erreurs.log : redirige stderr. cmd &> tout.log : stdout + stderr.\n'
            'cmd 2>&1 : redirige stderr vers stdout (ordre important !).\n'
            'cmd < input.txt : stdin depuis fichier. '
            'Heredoc : cmd << EOF ... EOF (multi-ligne). '
            'Herestring : cmd <<< "string".\n'
            'process substitution : diff <(ls dir1) <(ls dir2) — '
            'exécute dans un sous-shell et expose le résultat comme un fd (FIFO virtuel). '
            'tee permet de bifurquer le flux : cmd | tee fichier | autre_cmd.',
      ),
      const _Step(
        title: 'Signaux & trap',
        protocol: 'trap / signal',
        icon: Icons.flag,
        color: Color(0xFFA855F7),
        description: 'Gérer les signaux et le nettoyage en sortie.',
        detail:
            'trap "commande" SIGNAL permet de réagir aux signaux dans un script.\n'
            'trap "rm -f /tmp/mon_script_\$\$; exit" INT TERM EXIT '
            'nettoie les fichiers temporaires à l\'interruption (Ctrl+C = SIGINT) '
            'ou en fin normale. \$\$ est le PID du script courant.\n'
            'trap "" INT ignore SIGINT (utile pendant une section critique non interruptible).\n'
            'trap - INT restaure le comportement par défaut. '
            'kill -SIGUSR1 \$PID envoie un signal personnalisé pour déclencher '
            'une action dans un daemon (ex: rechargement de config sans restart).',
      ),
    ],
  ),
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

  // ── Boot simulator ────────────────────────────────────────
  int _bootPhase = -1;
  bool _booting = false;

  // ── Filesystem navigator ──────────────────────────────────
  String _fsPath = '/';
  final Map<String, List<String>> _fsTree = {
    '/': ['bin/', 'etc/', 'home/', 'usr/', 'var/', 'proc/', 'tmp/'],
    '/bin/': ['bash', 'ls', 'cat', 'cp', 'mv', 'rm', 'grep', 'find'],
    '/etc/': ['passwd', 'hosts', 'fstab', 'ssh/', 'nginx/', 'systemd/'],
    '/home/': ['user/'],
    '/home/user/': ['.bashrc', '.ssh/', 'Documents/', 'Downloads/'],
    '/usr/': ['bin/', 'lib/', 'local/', 'share/'],
    '/var/': ['log/', 'run/', 'tmp/', 'cache/'],
    '/proc/': ['1/', 'cpuinfo', 'meminfo', 'net/', 'sys/'],
  };

  // ── Process manager ───────────────────────────────────────
  final List<_LinuxProcess> _processes = [
    _LinuxProcess(1, 'systemd', 'root', 0.0, 8.2, 'S'),
    _LinuxProcess(2, 'kthreadd', 'root', 0.0, 0.0, 'S'),
    _LinuxProcess(125, 'sshd', 'root', 0.1, 4.5, 'S'),
    _LinuxProcess(312, 'nginx', 'www-data', 0.3, 12.1, 'S'),
    _LinuxProcess(450, 'postgres', 'postgres', 1.2, 64.0, 'S'),
    _LinuxProcess(712, 'bash', 'user', 0.0, 2.1, 'S'),
  ];
  bool _psRunning = false;
  Timer? _psTimer;

  // ── Bash terminal ─────────────────────────────────────────
  final List<String> _bashLines = [];
  final TextEditingController _bashCtrl = TextEditingController();
  bool _bashRunning = false;
  final Map<String, String> _bashVars = {'USER': 'user', 'HOME': '/home/user', 'PATH': '/usr/bin:/bin'};

  _Scenario get _scenario => _linuxScenarios[_scenarioIndex];

  @override
  void dispose() {
    _timer?.cancel();
    _psTimer?.cancel();
    _scrollCtrl.dispose();
    _bashCtrl.dispose();
    super.dispose();
  }

  void _selectScenario(int index) {
    _timer?.cancel();
    _psTimer?.cancel();
    setState(() {
      _scenarioIndex = index;
      _currentStep = -1;
      _running = false;
      _booting = false;
      _bootPhase = -1;
      _psRunning = false;
    });
  }

  // ── Boot simulation ───────────────────────────────────────

  Future<void> _startBoot() async {
    if (_booting) return;
    setState(() { _booting = true; _bootPhase = 0; });
    for (int p = 1; p <= 6; p++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _bootPhase = p);
    }
    if (mounted) setState(() => _booting = false);
  }

  void _resetBoot() => setState(() { _bootPhase = -1; _booting = false; });

  // ── Filesystem navigation ─────────────────────────────────

  void _fsNavigate(String entry) {
    if (entry.endsWith('/')) {
      String newPath;
      if (_fsPath == '/') {
        newPath = '/$entry';
      } else {
        newPath = '$_fsPath$entry';
      }
      if (_fsTree.containsKey(newPath)) {
        setState(() => _fsPath = newPath);
      }
    }
  }

  void _fsUp() {
    if (_fsPath == '/') return;
    final parts = _fsPath.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return;
    parts.removeLast();
    setState(() => _fsPath = parts.isEmpty ? '/' : '/${parts.join('/')}/');
  }

  // ── Process monitor ───────────────────────────────────────

  void _togglePsMonitor() {
    if (_psRunning) {
      _psTimer?.cancel();
      setState(() => _psRunning = false);
    } else {
      setState(() => _psRunning = true);
      _psTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final rng = DateTime.now().millisecondsSinceEpoch;
        setState(() {
          for (int i = 0; i < _processes.length; i++) {
            final p = _processes[i];
            final newCpu = ((rng.hashCode ^ (i * 1337)) % 30) / 10.0;
            _processes[i] = _LinuxProcess(p.pid, p.name, p.user, newCpu, p.mem, p.stat);
          }
        });
      });
    }
  }

  void _killProcess(int pid) {
    setState(() => _processes.removeWhere((p) => p.pid == pid));
  }

  // ── Bash terminal ─────────────────────────────────────────

  Future<void> _runBashCommand(String cmd) async {
    final c = cmd.trim();
    if (c.isEmpty) return;
    setState(() {
      _bashLines.add('\$ $c');
      _bashCtrl.clear();
    });
    await Future.delayed(const Duration(milliseconds: 150));
    String output = '';
    if (c == 'ls' || c == 'ls /') {
      output = 'bin  boot  dev  etc  home  lib  media  mnt  opt  proc  root  run  srv  sys  tmp  usr  var';
    } else if (c.startsWith('echo ')) {
      output = c.substring(5).replaceAll('"', '').replaceAll("'", '');
    } else if (c == 'pwd') {
      output = '/home/user';
    } else if (c == 'whoami') {
      output = 'user';
    } else if (c == 'uname -r') {
      output = '6.8.0-40-generic';
    } else if (c == 'ps aux' || c == 'ps') {
      output = 'USER    PID  %CPU  %MEM  COMMAND\nroot      1   0.0   0.3  systemd\nroot    125   0.1   0.4  sshd\nuser    712   0.0   0.2  bash';
    } else if (c == 'df -h') {
      output = 'Filesystem  Size  Used  Avail Use%\n/dev/sda1    50G   18G    30G  38%\ntmpfs       1.9G     0   1.9G   0%';
    } else if (c == 'free -h') {
      output = '       total  used  free  available\nMem:    7.8G  3.2G  2.1G       4.2G\nSwap:   2.0G  0.1G  1.9G';
    } else if (c == 'uptime') {
      output = '14:32:01 up 3 days, 5:12, 1 user, load average: 0.15, 0.20, 0.18';
    } else if (c.startsWith('cat /etc/')) {
      final file = c.substring(4);
      if (file == '/etc/hosts') {
        output = '127.0.0.1  localhost\n127.0.1.1  hostname\n::1        localhost ip6-localhost';
      } else if (file == '/etc/passwd') {
        output = 'root:x:0:0:root:/root:/bin/bash\ndaemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin\nuser:x:1000:1000::/home/user:/bin/bash';
      } else {
        output = 'cat: $file: No such file or directory';
      }
    } else if (c == 'help' || c == '?') {
      output = 'Commandes disponibles : ls, pwd, whoami, echo, uname -r, ps aux, df -h, free -h, uptime, cat /etc/hosts, cat /etc/passwd';
    } else if (c == 'clear') {
      setState(() => _bashLines.clear());
      return;
    } else {
      output = 'bash: $c: command not found (essaie "help")';
    }
    if (!mounted) return;
    setState(() {
      for (final line in output.split('\n')) {
        _bashLines.add(line);
      }
    });
  }

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
          topic: 'Linux — ${_scenario.name}',
          accentColor: _scenario.color,
          systemPrompt:
              'Tu es un expert Linux/Unix (niveau administrateur système). Réponds en français, de façon concise. '
              'Contexte actuel : ${_scenario.name}. '
              'Domaines couverts : boot BIOS/UEFI/GRUB, systemd, système de fichiers (ext4/FHS/inodes), '
              'processus et signaux, réseau Linux (ip/netstat/ss), permissions chmod/chown, Bash scripting.',
          suggestedQuestions: const [
            'Comment fonctionne le boot Linux ?',
            'C\'est quoi un inode ?',
            'Différence SIGTERM vs SIGKILL ?',
            'Comment lire les permissions rwx ?',
            'Expliquer le rôle de systemd',
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
            backgroundColor: _scenario.color.withOpacity(0.9),
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

  Widget _shellBox({required Color color, required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Icon(Icons.terminal, color: color, size: 13),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _cmdBtn(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: onTap != null ? color.withOpacity(0.14) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: onTap != null ? color.withOpacity(0.45) : Colors.white12),
        ),
        child: Text(label, style: TextStyle(color: onTap != null ? color : Colors.white24, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
      ),
    );
  }

  // 0 – Boot sequence ────────────────────────────────────────
  Widget _buildBootPanel() {
    final phases = <_LP3>[
      _LP3('BIOS/UEFI', 'POST & Secure Boot check', const Color(0xFF94A3B8)),
      _LP3('GRUB2', 'Loading kernel vmlinuz-6.8.0', const Color(0xFF6366F1)),
      _LP3('Kernel', 'Décompression & init mémoire', const Color(0xFF8B5CF6)),
      _LP3('initramfs', 'Montage rootfs temporaire', const Color(0xFFF59E0B)),
      _LP3('systemd', 'PID 1 — démarrage services', const Color(0xFF06B6D4)),
      _LP3('Login', 'getty → login prompt ready', const Color(0xFF22C55E)),
    ];
    return _shellBox(
      color: const Color(0xFF22C55E),
      title: 'LINUX BOOT SEQUENCE',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _cmdBtn('Boot', const Color(0xFF22C55E), _booting ? null : _startBoot),
              const SizedBox(width: 8),
              _cmdBtn('Reset', Colors.grey, _resetBoot),
            ]),
            const SizedBox(height: 10),
            ...List.generate(phases.length, (i) {
              final done = _bootPhase > i;
              final active = _bootPhase == i;
              final c = phases[i].c;
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: done || active ? c.withOpacity(0.10) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border(left: BorderSide(color: done || active ? c : Colors.white12, width: 3)),
                ),
                child: Row(
                  children: [
                    if (active && _booting)
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: c))
                    else
                      Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? c : Colors.white24, size: 14),
                    const SizedBox(width: 8),
                    Text('[${phases[i].a}]', style: TextStyle(color: done || active ? c : Colors.white24, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(phases[i].b, style: TextStyle(color: done || active ? Colors.white60 : Colors.white24, fontSize: 10), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }),
            if (_bootPhase >= 6)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Ubuntu 24.04 LTS \\n \\l', style: const TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontFamily: 'monospace'))
                    .animate().fadeIn(),
              ),
          ],
        ),
      ),
    );
  }

  // 1 – Filesystem navigator ────────────────────────────────
  Widget _buildFsPanel() {
    final entries = _fsTree[_fsPath] ?? [];
    return _shellBox(
      color: const Color(0xFF06B6D4),
      title: 'VFS NAVIGATOR — ls $_fsPath',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('user@linux:', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, fontFamily: 'monospace')),
                const SizedBox(width: 4),
                Text(_fsPath, style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                Text('\$ ls', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontFamily: 'monospace')),
                const Spacer(),
                if (_fsPath != '/') _cmdBtn('cd ..', Colors.grey, _fsUp),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: entries.map((e) {
                final isDir = e.endsWith('/');
                final color = isDir ? const Color(0xFF06B6D4) : Colors.white70;
                return GestureDetector(
                  onTap: () => _fsNavigate(e),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDir ? const Color(0xFF06B6D4).withOpacity(0.10) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: isDir ? const Color(0xFF06B6D4).withOpacity(0.35) : Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isDir ? Icons.folder : Icons.insert_drive_file, color: color, size: 12),
                        const SizedBox(width: 4),
                        Text(e, style: TextStyle(color: color, fontSize: 11, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (entries.isEmpty)
              Text('(vide)', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  // 2 – Process manager ─────────────────────────────────────
  Widget _buildProcessPanel() {
    return _shellBox(
      color: const Color(0xFFF59E0B),
      title: 'PROCESS MANAGER — top',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _cmdBtn(_psRunning ? 'Stop' : 'top', const Color(0xFFF59E0B), _togglePsMonitor),
                const SizedBox(width: 8),
                if (_psRunning) Row(children: [
                  SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFFF59E0B))),
                  const SizedBox(width: 6),
                  const Text('Monitoring…', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
              child: Row(
                children: [
                  SizedBox(width: 40, child: Text('PID', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: 'monospace'))),
                  SizedBox(width: 80, child: Text('COMMAND', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: 'monospace'))),
                  SizedBox(width: 40, child: Text('%CPU', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: 'monospace'))),
                  SizedBox(width: 50, child: Text('%MEM', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: 'monospace'))),
                  const SizedBox(width: 30, child: Text('STAT', style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'))),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 130),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _processes.length,
                itemBuilder: (_, i) {
                  final p = _processes[i];
                  final cpuColor = p.cpu > 2 ? const Color(0xFFEF4444) : p.cpu > 0.5 ? const Color(0xFFF59E0B) : Colors.white60;
                  return Row(
                    children: [
                      SizedBox(width: 40, child: Text('${p.pid}', style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'))),
                      SizedBox(width: 80, child: Text(p.name, style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                      SizedBox(width: 40, child: Text(p.cpu.toStringAsFixed(1), style: TextStyle(color: cpuColor, fontSize: 10, fontFamily: 'monospace'))),
                      SizedBox(width: 50, child: Text('${p.mem.toStringAsFixed(1)}M', style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace'))),
                      SizedBox(width: 30, child: Text(p.stat, style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'))),
                      if (p.pid != 1 && p.pid != 2)
                        GestureDetector(
                          onTap: () => _killProcess(p.pid),
                          child: const Icon(Icons.close, color: Color(0xFFEF4444), size: 12),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3 – Network commands ────────────────────────────────────
  Widget _buildNetworkPanel() {
    final cmds = <_LP2>[
      _LP2('ip a', 'eth0: 192.168.1.10/24 brd 192.168.1.255\nlo: 127.0.0.1/8'),
      _LP2('ip r', 'default via 192.168.1.1 dev eth0\n192.168.1.0/24 dev eth0 proto kernel'),
      _LP2('ss -tulpn', 'tcp LISTEN 0.0.0.0:22 (sshd)\ntcp LISTEN 0.0.0.0:80 (nginx)\ntcp LISTEN 0.0.0.0:5432 (postgres)'),
      _LP2('netstat -rn', 'Destination  Gateway      Genmask       Iface\n0.0.0.0      192.168.1.1  0.0.0.0       eth0'),
      _LP2('iptables -L', 'Chain INPUT (policy DROP)\nACCEPT  tcp --  anywhere  tcp dpt:ssh\nACCEPT  tcp --  anywhere  tcp dpt:http'),
    ];
    return _shellBox(
      color: const Color(0xFF8B5CF6),
      title: 'LINUX NETWORK TOOLS',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cmds.map((cmd) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('\$ ${cmd.a}', style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 2),
                ...cmd.b.split('\n').map((l) => Text(l, style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'monospace'))),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // 4 – Permissions ─────────────────────────────────────────
  Widget _buildPermPanel() {
    final files = <_LP5>[
      _LP5('-rw-r--r--', 'root', 'root', '644', '/etc/passwd'),
      _LP5('-rw-------', 'root', 'root', '600', '/etc/shadow'),
      _LP5('-rwxr-xr-x', 'root', 'root', '755', '/bin/bash'),
      _LP5('-rws--x--x', 'root', 'root', '4711', '/usr/bin/sudo (SUID)'),
      _LP5('drwxrwxrwt', 'root', 'root', '1777', '/tmp (sticky)'),
      _LP5('-rw-r-----', 'www', 'www', '640', '/var/log/nginx.log'),
    ];
    return _shellBox(
      color: const Color(0xFFEF4444),
      title: 'LINUX PERMISSIONS — ls -la',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: files.map((f) {
            final isSuid = f.e.contains('SUID');
            final isSticky = f.e.contains('sticky');
            final color = isSuid ? const Color(0xFFEF4444) : isSticky ? const Color(0xFFF59E0B) : Colors.white60;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(f.a, style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontFamily: 'monospace')),
                  const SizedBox(width: 8),
                  SizedBox(width: 36, child: Text(f.b, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: 'monospace'))),
                  SizedBox(width: 36, child: Text(f.c, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: 'monospace'))),
                  SizedBox(width: 32, child: Text(f.d, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontFamily: 'monospace'))),
                  Expanded(child: Text(f.e, style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 5 – Bash terminal ───────────────────────────────────────
  Widget _buildBashPanel() {
    return _shellBox(
      color: const Color(0xFFF59E0B),
      title: 'BASH TERMINAL (essaie: ls, pwd, whoami, ps aux, help)',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 110),
              child: _bashLines.isEmpty
                  ? Text('user@linux:~\$ _', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontFamily: 'monospace'))
                  : ListView.builder(
                      shrinkWrap: true,
                      reverse: true,
                      itemCount: _bashLines.length,
                      itemBuilder: (_, i) {
                        final line = _bashLines[_bashLines.length - 1 - i];
                        final isCmd = line.startsWith('\$');
                        return Text(line, style: TextStyle(
                          color: isCmd ? const Color(0xFF22C55E) : Colors.white60,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ));
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('user@linux:~\$ ', style: const TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontFamily: 'monospace')),
                Expanded(
                  child: TextField(
                    controller: _bashCtrl,
                    style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: InputBorder.none,
                      hintText: 'commande…',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                    onSubmitted: _runBashCommand,
                  ),
                ),
                _cmdBtn('Exec', const Color(0xFFF59E0B), () => _runBashCommand(_bashCtrl.text)),
                const SizedBox(width: 6),
                _cmdBtn('Clear', Colors.grey, () => setState(() => _bashLines.clear())),
              ],
            ),
          ],
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
                color: selected ? s.color.withOpacity(0.18) : TdcColors.surface,
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
          color: s.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: s.color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: s.color.withOpacity(0.15),
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
                ? step.color.withOpacity(0.12)
                : TdcColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state == _StepState.active
                  ? step.color
                  : state == _StepState.done
                      ? step.color.withOpacity(0.35)
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
                                  color: step.color.withOpacity(0.15),
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
                color: step.color.withOpacity(0.4),
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
            ? step.color.withOpacity(0.2)
            : state == _StepState.active
                ? step.color.withOpacity(0.25)
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
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: step.color.withOpacity(0.15)),
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
                        color: Colors.white,
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
                foregroundColor: Colors.white,
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

// ─── Data classes ─────────────────────────────────────────────

class _LinuxProcess {
  final int pid;
  final String name;
  final String user;
  final double cpu;
  final double mem;
  final String stat;
  const _LinuxProcess(this.pid, this.name, this.user, this.cpu, this.mem, this.stat);
}

class _LP2 { final String a, b; const _LP2(this.a, this.b); }
class _LP3 { final String a, b; final Color c; const _LP3(this.a, this.b, this.c); }
class _LP5 { final String a, b, c, d, e; const _LP5(this.a, this.b, this.c, this.d, this.e); }

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
        backgroundColor: const Color(0xFFF59E0B),
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
          color: _saved ? const Color(0xFFF59E0B).withOpacity(0.18) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _saved ? const Color(0xFFF59E0B) : Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFF59E0B)))
            else
              Icon(_saved ? Icons.bookmark : Icons.bookmark_border, color: _saved ? const Color(0xFFF59E0B) : Colors.white38, size: 13),
            const SizedBox(width: 5),
            Text(
              _saved ? 'Retenu ✓' : 'Retenir',
              style: TextStyle(
                color: _saved ? const Color(0xFFF59E0B) : Colors.white38,
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
