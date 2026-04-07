// ============================================================
// How Internet Works Simulator
// Explications théoriques interactives et animées :
//   • Ce qui se passe quand on fait un ping
//   • Ce qui se passe quand on recherche sur internet
//   • DNS, TCP, TLS, HTTP, routing, ARP, etc.
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/lab/widgets/sim_step_card.dart';
import 'package:tutodecode/features/lab/widgets/lab_widgets.dart';
import 'package:tutodecode/features/lab/widgets/simulator_ai_assistant.dart';
import 'package:tutodecode/features/courses/data/cheat_sheet_repository.dart';

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

final _scenarios = [
  _Scenario(
    name: 'Ping',
    subtitle: 'ICMP Echo Request/Reply',
    icon: Icons.radar,
    color: const Color(0xFF06B6D4),
    steps: [
      const _Step(
        title: 'Commande ping lancée',
        protocol: 'OS',
        icon: Icons.terminal,
        color: Color(0xFF94A3B8),
        description: 'Tu tapes `ping 8.8.8.8` dans le terminal.',
        detail:
            'Le système d\'exploitation reçoit ta commande et prépare un paquet ICMP '
            'de type 8 (Echo Request). Il assigne un identifiant de processus et un numéro de séquence '
            'incrémental à chaque paquet envoyé.',
      ),
      _Step(
        title: 'Résolution ARP (si LAN)',
        protocol: 'ARP',
        icon: Icons.device_hub,
        color: const Color(0xFFF59E0B),
        description: 'Qui est la passerelle par défaut sur le réseau local ?',
        detail:
            'Avant d\'envoyer quoi que ce soit hors du LAN, la carte réseau doit connaître '
            'l\'adresse MAC de la passerelle (routeur). Elle diffuse un ARP Request : '
            '"Qui a l\'IP 192.168.1.1 ?" — le routeur répond avec son adresse MAC. '
            'Ce résultat est mis en cache dans la table ARP.',
        visual: () => SimFlowDiagram(
          color: const Color(0xFFF59E0B),
          nodes: const [
            SimFlowNode('PC', Icons.computer),
            SimFlowNode('ARP Bcast', Icons.broadcast_on_personal),
            SimFlowNode('Switch', Icons.device_hub),
            SimFlowNode('Router', Icons.router),
            SimFlowNode('ARP Reply', Icons.reply),
            SimFlowNode('PC', Icons.computer),
          ],
        ),
      ),
      _Step(
        title: 'Construction du paquet IP',
        protocol: 'IP',
        icon: Icons.layers,
        color: const Color(0xFF8B5CF6),
        description: 'Le paquet ICMP est encapsulé dans un datagramme IPv4.',
        detail:
            'L\'en-tête IP contient : IP source (ton PC), IP dest (8.8.8.8), TTL=64 '
            '(Time To Live — décrémenté à chaque routeur, dropped si = 0), protocole=1 (ICMP), '
            'et un checksum. Le tout est encapsulé dans une trame Ethernet avec les MAC source/dest.',
        visual: () => const SimPacketDiagram(
          baseColor: Color(0xFF8B5CF6),
          fields: [
            SimPacketField('ETH HDR', '14 bytes', 2),
            SimPacketField('IP HDR', '20 bytes', 3),
            SimPacketField('ICMP HDR', '8 bytes', 2),
            SimPacketField('DATA', 'payload', 1),
          ],
        ),
      ),
      _Step(
        title: 'Traversée des routeurs',
        protocol: 'IP Routing',
        icon: Icons.route,
        color: const Color(0xFF06B6D4),
        description: 'Le paquet saute de routeur en routeur jusqu\'à destination.',
        detail:
            'Chaque routeur consulte sa table de routage, décrémente le TTL, recalcule le checksum '
            'et redirige le paquet vers le prochain saut (next hop). Si le TTL atteint 0, le routeur '
            'envoie un ICMP "Time Exceeded" à ton IP — c\'est ce que exploite traceroute.',
        visual: () => SimFlowDiagram(
          color: const Color(0xFF06B6D4),
          nodes: const [
            SimFlowNode('PC', Icons.computer),
            SimFlowNode('R1', Icons.router),
            SimFlowNode('R2', Icons.router),
            SimFlowNode('R3', Icons.router),
            SimFlowNode('8.8.8.8', Icons.dns),
          ],
        ),
      ),
      const _Step(
        title: 'Réception par la cible',
        protocol: 'ICMP',
        icon: Icons.check_circle,
        color: Color(0xFF10B981),
        description: '8.8.8.8 (Google DNS) reçoit l\'Echo Request.',
        detail:
            'Le serveur cible reçoit le paquet ICMP type 8. Il génère un ICMP type 0 '
            '(Echo Reply) en inversant source/destination, et le renvoie par le chemin de retour '
            '(qui peut être différent à cause du routage asymétrique).',
      ),
      const _Step(
        title: 'Mesure du RTT',
        protocol: 'Résultat',
        icon: Icons.timer,
        color: Color(0xFFF59E0B),
        description: 'Round Trip Time affiché : `64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=12.4ms`',
        detail:
            'Ton OS mesure le temps entre l\'envoi et la réception. Le TTL dans la réponse '
            '(ici 118) indique le nombre de sauts restants — donc la cible était à '
            '128 - 118 = 10 sauts de toi environ (64 ou 128 ou 255 sont les TTL initiaux courants). '
            'Une perte de paquet = timeout après ~2 secondes.',
      ),
    ],
  ),
  _Scenario(
    name: 'Recherche Web',
    subtitle: 'DNS → TCP → TLS → HTTP',
    icon: Icons.search,
    color: const Color(0xFF6366F1),
    steps: [
      const _Step(
        title: 'Tu tapes l\'URL',
        protocol: 'Browser',
        icon: Icons.keyboard,
        color: Color(0xFF94A3B8),
        description: 'Tu écris `https://google.com` et appuies sur Entrée.',
        detail:
            'Le navigateur décompose l\'URL : protocole=https, hôte=google.com, chemin=/. '
            'Il vérifie d\'abord son cache DNS local, puis le cache du système d\'exploitation '
            '(/etc/hosts ou cache Windows), avant de faire une vraie requête DNS.',
      ),
      _Step(
        title: 'Résolution DNS',
        protocol: 'DNS (UDP 53)',
        icon: Icons.dns,
        color: const Color(0xFFF59E0B),
        description: 'Qui est google.com ? → 142.250.179.46',
        detail:
            'Résolution récursive en 4 étapes :\n'
            '1. Résolveur local → Serveur DNS récursif de ton FAI (ou 8.8.8.8)\n'
            '2. Récursif → Serveur Racine (.) → "va voir .com"\n'
            '3. Récursif → Serveur TLD .com → "va voir ns1.google.com"\n'
            '4. Récursif → Serveur Autoritaire Google → "142.250.179.46"\n'
            'Le résultat est mis en cache selon le TTL du record A (ex: 300s). '
            'DNS utilise UDP port 53 (TCP si réponse > 512 octets ou DNSSEC).',
        visual: () => const SimTreeDiagram(
          color: Color(0xFFF59E0B),
          root: SimTreeNode(
            'Root DNS',
            sublabel: '13 clusters',
            children: [
              SimTreeNode('.com TLD', sublabel: 'VeriSign', children: [
                SimTreeNode('google.com NS', sublabel: 'ns1.google.com'),
              ]),
              SimTreeNode('.org TLD', sublabel: 'PIR'),
              SimTreeNode('.fr TLD', sublabel: 'AFNIC'),
            ],
          ),
        ),
      ),
      _Step(
        title: 'Connexion TCP (3-Way Handshake)',
        protocol: 'TCP (port 443)',
        icon: Icons.handshake,
        color: const Color(0xFF8B5CF6),
        description: 'Établissement de la connexion fiable.',
        detail:
            '1. SYN → ton PC envoie SYN (seq=x) au serveur\n'
            '2. SYN-ACK ← le serveur répond SYN (seq=y) + ACK (x+1)\n'
            '3. ACK → ton PC confirme ACK (y+1)\n'
            'La connexion est établie. TCP garantit l\'ordre et la livraison des données '
            'grâce aux numéros de séquence et aux accusés de réception. '
            'Le port destination est 443 (HTTPS). Le port source est éphémère (ex: 54321).',
        visual: () => SimFlowDiagram(
          color: const Color(0xFF8B5CF6),
          nodes: const [
            SimFlowNode('Client', Icons.computer),
            SimFlowNode('SYN', Icons.arrow_forward),
            SimFlowNode('Server', Icons.dns),
            SimFlowNode('SYN-ACK', Icons.reply),
            SimFlowNode('Client', Icons.computer),
            SimFlowNode('ACK', Icons.check),
            SimFlowNode('Connected', Icons.check_circle),
          ],
        ),
      ),
      _Step(
        title: 'Négociation TLS (HTTPS)',
        protocol: 'TLS 1.3',
        icon: Icons.lock,
        color: const Color(0xFF10B981),
        description: 'Chiffrement de la connexion.',
        detail:
            '1. ClientHello → ton navigateur envoie les suites de chiffrement supportées + SNI (Server Name Indication)\n'
            '2. ServerHello ← le serveur choisit la suite (ex: TLS_AES_256_GCM_SHA384) + certificat X.509\n'
            '3. Ton navigateur vérifie le certificat contre les CA de confiance\n'
            '4. Échange de clés ECDHE → dérivation des clés de session\n'
            '5. Finished ↔ les deux parties confirment le handshake\n'
            'Avec TLS 1.3, tout ça tient en 1 aller-retour (1-RTT), ou 0-RTT si session reprise.',
        visual: () => const SimKeyValue(
          color: Color(0xFF10B981),
          entries: [
            SimKVEntry('Client Hello', 'cipher suites + random'),
            SimKVEntry('Server Hello', 'chosen cipher + cert'),
            SimKVEntry('Key Exchange', 'ECDH ephemeral'),
            SimKVEntry('Finished', 'encrypted + authenticated'),
          ],
        ),
      ),
      const _Step(
        title: 'Requête HTTP/2',
        protocol: 'HTTP/2',
        icon: Icons.send,
        color: Color(0xFF6366F1),
        description: 'GET / HTTP/2 → google.com',
        detail:
            'Le navigateur envoie une requête HTTP/2 (binaire, multiplexée) :\n'
            'HEADERS frame : :method=GET, :path=/, :authority=google.com, '
            'user-agent=Chrome/..., accept-encoding=gzip,br\n'
            'HTTP/2 permet plusieurs requêtes en parallèle sur la même connexion TCP '
            '(streams), contrairement à HTTP/1.1 qui était séquentiel.',
      ),
      const _Step(
        title: 'Réponse + Rendu',
        protocol: 'HTTP 200 OK',
        icon: Icons.web,
        color: Color(0xFF06B6D4),
        description: 'Le serveur envoie le HTML, le navigateur construit la page.',
        detail:
            'Le serveur renvoie :\n'
            '- Status 200 OK + en-têtes (content-type, cache-control, HSTS…)\n'
            '- Corps HTML (souvent compressé en gzip ou Brotli)\n'
            'Le navigateur parse le HTML → construit le DOM → charge les CSS/JS/images '
            '(nouvelles requêtes DNS+TCP+TLS pour chaque domaine tiers) → '
            'calcule le layout → peint les pixels à l\'écran.\n'
            'C\'est le Critical Rendering Path.',
      ),
    ],
  ),
  _Scenario(
    name: 'SSH',
    subtitle: 'Connexion sécurisée à distance',
    icon: Icons.terminal,
    color: const Color(0xFF10B981),
    steps: [
      const _Step(
        title: 'Connexion TCP port 22',
        protocol: 'TCP',
        icon: Icons.cable,
        color: Color(0xFF8B5CF6),
        description: '3-Way Handshake vers le port 22 du serveur.',
        detail:
            'SSH utilise TCP pour garantir la fiabilité. Le client initie une connexion '
            'sur le port 22 (configurable). Avant même l\'authentification, '
            'les deux parties s\'échangent leur version SSH (ex: SSH-2.0-OpenSSH_8.9).',
      ),
      _Step(
        title: 'Échange de clés (KEX)',
        protocol: 'SSH-2 / ECDH',
        icon: Icons.swap_horiz,
        color: const Color(0xFFF59E0B),
        description: 'Négociation des algorithmes et échange Diffie-Hellman.',
        detail:
            'Les deux parties négocient : algorithme de KEX (curve25519-sha256), '
            'chiffrement (chacha20-poly1305 ou aes256-gcm), MAC, compression.\n'
            'L\'échange ECDH génère un secret partagé sans jamais le transmettre '
            '(propriété Forward Secrecy). Les clés de session sont dérivées de ce secret.',
        visual: () => SimFlowDiagram(
          color: const Color(0xFFF59E0B),
          nodes: const [
            SimFlowNode('Client', Icons.computer),
            SimFlowNode('ECDH pubkey', Icons.key),
            SimFlowNode('Server', Icons.dns),
            SimFlowNode('ECDH pubkey', Icons.key),
            SimFlowNode('shared K', Icons.lock),
            SimFlowNode('Both', Icons.people),
          ],
        ),
      ),
      const _Step(
        title: 'Vérification de l\'hôte',
        protocol: 'Host Key',
        icon: Icons.verified,
        color: Color(0xFF06B6D4),
        description: 'Est-ce bien le bon serveur ? (TOFU / known_hosts)',
        detail:
            'Le serveur prouve son identité avec sa clé privée (ed25519, RSA…). '
            'Le client vérifie dans ~/.ssh/known_hosts.\n'
            'Premier contact → Trust On First Use (TOFU) : le fingerprint est stocké.\n'
            'Si la clé change → AVERTISSEMENT (possible Man-in-the-Middle !).',
      ),
      const _Step(
        title: 'Authentification utilisateur',
        protocol: 'SSH Auth',
        icon: Icons.key,
        color: Color(0xFF10B981),
        description: 'Par clé publique (recommandé) ou mot de passe.',
        detail:
            'Méthode clé publique :\n'
            '1. Le client annonce sa clé publique\n'
            '2. Le serveur vérifie qu\'elle est dans ~/.ssh/authorized_keys\n'
            '3. Le serveur envoie un challenge chiffré avec la clé publique\n'
            '4. Le client le déchiffre avec sa clé privée → prouve qu\'il la possède\n'
            'Aucun mot de passe ne transite. Résistant au phishing.',
      ),
      const _Step(
        title: 'Canal chiffré ouvert',
        protocol: 'SSH Channel',
        icon: Icons.lock_open,
        color: Color(0xFF6366F1),
        description: 'Shell interactif chiffré bout en bout.',
        detail:
            'SSH ouvre un ou plusieurs canaux multiplexés dans la même connexion :\n'
            '- shell interactif\n'
            '- transfert de fichiers (SFTP / SCP)\n'
            '- port forwarding (tunnels TCP)\n'
            '- agent forwarding\n'
            'Chaque frappe de touche est chiffrée immédiatement (mode interactif).',
      ),
    ],
  ),
  _Scenario(
    name: 'TCP/IP',
    subtitle: 'Le modèle en couches expliqué',
    icon: Icons.layers,
    color: const Color(0xFFF59E0B),
    steps: [
      const _Step(
        title: 'Couche Application (L7)',
        protocol: 'HTTP / DNS / SMTP…',
        icon: Icons.apps,
        color: Color(0xFF6366F1),
        description: 'Ce que voient les applications.',
        detail:
            'La couche application définit le format des données échangées.\n'
            'Exemples : HTTP (web), DNS (noms de domaine), SMTP (email), '
            'FTP (fichiers), MQTT (IoT), gRPC (microservices).\n'
            'Elle ne se préoccupe pas de comment les données arrivent à destination.',
      ),
      const _Step(
        title: 'Couche Transport (L4)',
        protocol: 'TCP / UDP',
        icon: Icons.compare_arrows,
        color: Color(0xFF8B5CF6),
        description: 'Communication entre processus (ports).',
        detail:
            'TCP : connexion fiable, ordonnée, avec retransmission. '
            'Idéal pour HTTP, SSH, FTP.\n'
            'UDP : sans connexion, sans garantie, rapide. '
            'Idéal pour DNS, vidéo streaming, jeux en ligne, QUIC.\n'
            'Les ports (0–65535) permettent de multiplexer plusieurs services sur un seul hôte. '
            'Ports bien connus : 80 (HTTP), 443 (HTTPS), 22 (SSH), 53 (DNS).',
      ),
      _Step(
        title: 'Couche Internet (L3)',
        protocol: 'IP / ICMP / ARP',
        icon: Icons.public,
        color: const Color(0xFF06B6D4),
        description: 'Adressage et routage entre réseaux.',
        detail:
            'IPv4 : adresses 32 bits (ex: 192.168.1.1). Environ 4,3 milliards d\'adresses '
            '(épuisées → NAT + IPv6).\n'
            'IPv6 : adresses 128 bits (ex: 2001:db8::1). Espace quasi infini.\n'
            'IP est "best effort" : pas de garantie de livraison ni d\'ordre. '
            'C\'est TCP au-dessus qui compense.\n'
            'ICMP : messages de contrôle (ping, TTL exceeded, port unreachable).\n'
            'ARP : résolution IP → MAC sur le LAN.',
        visual: () => const SimLayerStack(
          layers: [
            SimLayer('L7 Application', 'HTTP, DNS, SMTP, FTP…', Color(0xFF6366F1)),
            SimLayer('L4 Transport', 'TCP, UDP — ports + reliability', Color(0xFF10B981)),
            SimLayer('L3 Network', 'IP, ICMP — routing + addressing', Color(0xFFF97316)),
            SimLayer('L2 Link', 'Ethernet, WiFi — MAC + frames', Color(0xFF8B5CF6)),
            SimLayer('L1 Physical', 'Bits → electrical/optical/radio', Color(0xFFEF4444)),
          ],
        ),
      ),
      const _Step(
        title: 'Couche Liaison (L2)',
        protocol: 'Ethernet / WiFi',
        icon: Icons.device_hub,
        color: Color(0xFFF59E0B),
        description: 'Communication sur le réseau local.',
        detail:
            'Ethernet (câble) et WiFi (802.11) opèrent à ce niveau.\n'
            'Adresses MAC : 48 bits, uniques par interface (ex: AA:BB:CC:DD:EE:FF).\n'
            'Les trames Ethernet encapsulent les paquets IP et sont transmises '
            'uniquement sur le segment local. Un switch L2 fait le routage par MAC.\n'
            'MTU standard : 1500 octets (au-delà → fragmentation IP).',
      ),
      const _Step(
        title: 'Couche Physique (L1)',
        protocol: 'Bits / Signaux',
        icon: Icons.settings_ethernet,
        color: Color(0xFF10B981),
        description: 'Les bits sur le fil (ou l\'air).',
        detail:
            'Conversion des bits en signaux électriques (Ethernet), optiques (fibre), '
            'ou radio (WiFi, 4G, 5G).\n'
            'Débits : Fast Ethernet 100 Mbps, Gigabit 1 Gbps, 10G, 100G (datacenter).\n'
            'Fibre monomode : jusqu\'à des centaines de km sans répéteur.\n'
            'WiFi 6 (802.11ax) : jusqu\'à 9,6 Gbps théoriques en OFDMA.',
      ),
      const _Step(
        title: 'Encapsulation',
        protocol: 'Data wrapping',
        icon: Icons.wrap_text,
        color: Color(0xFFF59E0B),
        description: 'Chaque couche ajoute son en-tête.',
        detail:
            'À l\'émission, les données descendent la pile :\n'
            'App → [données HTTP]\n'
            'Transport → [TCP header | données HTTP]\n'
            'Internet → [IP header | TCP header | données HTTP]\n'
            'Liaison → [Eth header | IP header | TCP header | données HTTP | Eth trailer]\n\n'
            'À la réception, chaque couche lit et retire son en-tête (désencapsulation), '
            'puis passe le reste à la couche supérieure.',
      ),
    ],
  ),
  _Scenario(
    name: 'DNS',
    subtitle: 'Annuaire d\'Internet',
    icon: Icons.dns,
    color: const Color(0xFFF59E0B),
    steps: [
      const _Step(
        title: 'Cache local d\'abord',
        protocol: 'OS Cache',
        icon: Icons.storage,
        color: Color(0xFF94A3B8),
        description: 'Le plus rapide : la réponse est peut-être déjà connue.',
        detail:
            'L\'OS vérifie dans l\'ordre :\n'
            '1. /etc/hosts (ou C:\\Windows\\System32\\drivers\\etc\\hosts) — priorité absolue\n'
            '2. Cache DNS de l\'OS (ipconfig /displaydns sur Windows, systemd-resolve --statistics sur Linux)\n'
            '3. Cache du navigateur\n'
            'Si trouvé et TTL non expiré → réponse immédiate, aucune requête réseau.',
      ),
      _Step(
        title: 'Résolveur récursif',
        protocol: 'DNS Récursif',
        icon: Icons.repeat,
        color: const Color(0xFF6366F1),
        description: 'Ton DNS configuré (FAI, 8.8.8.8, 1.1.1.1…)',
        detail:
            'Le résolveur récursif fait le travail à ta place. Il interroge la hiérarchie DNS '
            'et te renvoie la réponse finale.\n'
            '8.8.8.8 = Google Public DNS\n'
            '1.1.1.1 = Cloudflare (privacy-first)\n'
            '9.9.9.9 = Quad9 (sécurité + filtrage malware)\n'
            'Ils mettent les réponses en cache → très rapides pour les domaines populaires.',
        visual: () => const SimTreeDiagram(
          color: Color(0xFF6366F1),
          root: SimTreeNode(
            'Résolveur Récursif',
            sublabel: '8.8.8.8 / 1.1.1.1',
            children: [
              SimTreeNode('Root Servers', sublabel: 'a-m.root-servers.net'),
              SimTreeNode('TLD .com', sublabel: 'VeriSign NS'),
              SimTreeNode('Autoritaire', sublabel: 'ns1.google.com'),
            ],
          ),
        ),
      ),
      const _Step(
        title: 'Serveurs Racine (.)',
        protocol: 'Root Servers',
        icon: Icons.account_tree,
        color: Color(0xFFF59E0B),
        description: '13 clusters de serveurs racine dans le monde.',
        detail:
            'Il y a 13 adresses IP de serveurs racine (a.root-servers.net à m.root-servers.net), '
            'mais des centaines de machines physiques via Anycast.\n'
            'Ils ne connaissent pas les domaines, mais savent qui gère chaque TLD.\n'
            'Exemple : "google.com" → "je ne sais pas, mais .com est géré par VeriSign".',
      ),
      const _Step(
        title: 'Serveurs TLD',
        protocol: 'TLD Servers',
        icon: Icons.language,
        color: Color(0xFF8B5CF6),
        description: '.com, .fr, .io, .org… chacun a ses serveurs.',
        detail:
            '.com et .net → VeriSign\n'
            '.fr → AFNIC\n'
            '.io → Internet Computer Bureau\n'
            'Les serveurs TLD connaissent les serveurs autoritaires de chaque domaine enregistré.\n'
            'Exemple : "google.com" → "les serveurs autoritaires sont ns1.google.com, ns2.google.com".',
      ),
      const _Step(
        title: 'Serveur Autoritaire',
        protocol: 'Authoritative NS',
        icon: Icons.verified,
        color: Color(0xFF10B981),
        description: 'La réponse définitive vient de là.',
        detail:
            'Le serveur autoritaire est géré par le propriétaire du domaine (ou son hébergeur DNS).\n'
            'Il contient les vrais records DNS :\n'
            'A → IPv4 (142.250.179.46)\n'
            'AAAA → IPv6\n'
            'MX → serveurs mail\n'
            'CNAME → alias\n'
            'TXT → SPF, DKIM, vérifications diverses\n'
            'NS → délégation de sous-domaine',
      ),
      const _Step(
        title: 'DNSSEC & DoH',
        protocol: 'Sécurité DNS',
        icon: Icons.security,
        color: Color(0xFF06B6D4),
        description: 'Protéger les réponses DNS contre la falsification.',
        detail:
            'DNSSEC : signatures cryptographiques sur les records DNS → impossible de falsifier '
            'une réponse sans la clé privée du domaine.\n\n'
            'DoH (DNS over HTTPS) : encapsule les requêtes DNS dans HTTPS → '
            'chiffré, indiscernable du trafic web normal, résistant à la censure.\n\n'
            'DoT (DNS over TLS) : chiffrement TLS sur port 853.\n\n'
            'DNS classique (UDP 53) est en clair → ton FAI voit tous tes domaines visités.',
      ),
    ],
  ),
  _Scenario(
    name: 'Firewall & NAT',
    subtitle: 'Filtrage et traduction d\'adresses',
    icon: Icons.shield,
    color: const Color(0xFFEF4444),
    steps: [
      const _Step(
        title: 'Le problème IPv4',
        protocol: 'Pénurie d\'adresses',
        icon: Icons.warning,
        color: Color(0xFFF59E0B),
        description: 'Il n\'y a que 4,3 milliards d\'adresses IPv4 pour 15 milliards d\'appareils.',
        detail:
            'IPv4 (32 bits) → 2³² = ~4,3 milliards d\'adresses. Épuisées depuis 2011.\n'
            'Solution : adresses privées (RFC 1918) + NAT.\n'
            'Plages privées :\n'
            '  10.0.0.0/8 (16M hôtes)\n'
            '  172.16.0.0/12 (1M hôtes)\n'
            '  192.168.0.0/16 (65K hôtes)\n'
            'Ces adresses ne sont pas routables sur Internet → invisibles depuis l\'extérieur.',
      ),
      _Step(
        title: 'NAT (Network Address Translation)',
        protocol: 'NAT / PAT',
        icon: Icons.swap_horiz,
        color: const Color(0xFF06B6D4),
        description: 'Ton routeur traduit tes adresses privées en une seule IP publique.',
        detail:
            'Quand tu accèdes à google.com depuis 192.168.1.50:54321 :\n'
            '1. Le routeur remplace 192.168.1.50:54321 → IP_publique:58900\n'
            '2. Il note la correspondance dans sa table NAT\n'
            '3. La réponse arrive sur IP_publique:58900\n'
            '4. Le routeur la retransmet à 192.168.1.50:54321\n'
            'C\'est du PAT (Port Address Translation) : plusieurs hôtes partagent une IP publique '
            'grâce aux ports différents.',
        visual: () => const SimKeyValue(
          color: Color(0xFF06B6D4),
          entries: [
            SimKVEntry('192.168.1.10:4523', '→ 93.184.216.34:80'),
            SimKVEntry('192.168.1.11:8821', '→ 93.184.216.34:443'),
            SimKVEntry('Masquerade', 'source IP réécrite'),
          ],
        ),
      ),
      const _Step(
        title: 'Firewall stateful',
        protocol: 'iptables / nftables',
        icon: Icons.fireplace,
        color: Color(0xFFEF4444),
        description: 'Filtrage des paquets entrants et sortants.',
        detail:
            'Un firewall stateful suit l\'état des connexions :\n'
            '- NEW : premier paquet d\'une connexion\n'
            '- ESTABLISHED : connexion établie (les deux sens)\n'
            '- RELATED : connexion liée (ex: FTP data)\n'
            '- INVALID : paquet incohérent → DROP\n\n'
            'Règle typique : accepter tout le trafic ESTABLISHED/RELATED sortant, '
            'mais bloquer les connexions entrantes non sollicitées.\n'
            'iptables (Linux), pf (BSD/macOS), Windows Defender Firewall.',
      ),
      const _Step(
        title: 'Port Forwarding',
        protocol: 'DNAT',
        icon: Icons.open_in_new,
        color: Color(0xFF8B5CF6),
        description: 'Exposer un service interne à Internet.',
        detail:
            'Pour rendre accessible un serveur web interne (192.168.1.100:80) depuis Internet :\n'
            'Le routeur fait du DNAT (Destination NAT) :\n'
            'IP_publique:80 → 192.168.1.100:80\n\n'
            'Risque : expose directement le service. '
            'Toujours sécuriser avec un reverse proxy (nginx) + TLS + authentification.',
      ),
      const _Step(
        title: 'DMZ',
        protocol: 'Architecture réseau',
        icon: Icons.layers,
        color: Color(0xFF10B981),
        description: 'Zone démilitarisée pour les serveurs publics.',
        detail:
            'Une DMZ est un segment réseau entre Internet et le LAN interne.\n'
            'Les serveurs accessibles depuis Internet (web, mail, DNS) sont en DMZ.\n'
            'Deux firewalls :\n'
            '  FW1 : Internet → DMZ (filtre le trafic entrant)\n'
            '  FW2 : DMZ → LAN (protège le réseau interne)\n'
            'Même si un serveur en DMZ est compromis, l\'attaquant ne peut pas '
            'directement atteindre le LAN interne.',
      ),
    ],
  ),
];

// ─── Widget principal ────────────────────────────────────────

enum _StepState { future, active, done }

class HowInternetWorksSimulator extends StatefulWidget {
  const HowInternetWorksSimulator({super.key});

  @override
  State<HowInternetWorksSimulator> createState() =>
      _HowInternetWorksSimulatorState();
}

class _HowInternetWorksSimulatorState
    extends State<HowInternetWorksSimulator> {
  int _scenarioIndex = 0;
  int _currentStep = -1;
  bool _running = false;
  Timer? _timer;
  final ScrollController _scrollCtrl = ScrollController();

  // ── État simulation interactive par scénario ──────────────

  // Ping simulator
  final List<_PingLine> _pingLines = [];
  bool _pinging = false;
  int _pingSeq = 0;

  // TCP handshake
  int _tcpPhase = -1; // -1=idle, 0=SYN, 1=SYN-ACK, 2=ACK, 3=done
  bool _tcpRunning = false;

  // DNS lookup
  final List<_DnsStep> _dnsSteps = [];
  bool _dnsRunning = false;
  String _dnsQuery = 'google.com';
  final TextEditingController _dnsCtrl = TextEditingController(text: 'google.com');

  // SSH auth
  int _sshPhase = -1;
  bool _sshRunning = false;

  // Firewall rules
  final List<_FwRule> _fwRules = [
    _FwRule('ACCEPT', 'ESTABLISHED,RELATED', 'all', Colors.green),
    _FwRule('ACCEPT', 'NEW', 'tcp dport 22', Colors.blue),
    _FwRule('ACCEPT', 'NEW', 'tcp dport 443', Colors.blue),
    _FwRule('DROP', 'all', 'tcp dport 23 (Telnet)', Colors.red),
    _FwRule('DROP', 'INVALID', 'all', Colors.red),
  ];
  bool _fwBlocked = false;
  String _fwTestPort = '80';
  final TextEditingController _fwPortCtrl = TextEditingController(text: '80');

  _Scenario get _scenario => _scenarios[_scenarioIndex];

  @override
  void dispose() {
    _timer?.cancel();
    _scrollCtrl.dispose();
    _dnsCtrl.dispose();
    _fwPortCtrl.dispose();
    super.dispose();
  }

  void _selectScenario(int index) {
    _timer?.cancel();
    setState(() {
      _scenarioIndex = index;
      _currentStep = -1;
      _running = false;
      _pinging = false;
      _pingLines.clear();
      _pingSeq = 0;
      _tcpPhase = -1;
      _tcpRunning = false;
      _dnsSteps.clear();
      _dnsRunning = false;
      _sshPhase = -1;
      _sshRunning = false;
      _fwBlocked = false;
    });
  }

  // ── Simulation Ping ───────────────────────────────────────

  Future<void> _startPing() async {
    if (_pinging) return;
    setState(() {
      _pinging = true;
      _pingLines.clear();
      _pingSeq = 0;
    });
    final rng = Random();
    setState(() => _pingLines.add(_PingLine('PING 8.8.8.8 56(84) bytes of data.', Colors.white70, false)));
    await Future.delayed(const Duration(milliseconds: 300));
    for (int i = 0; i < 4; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 900));
      final rtt = (8 + rng.nextDouble() * 20).toStringAsFixed(1);
      final ttl = 115 + rng.nextInt(10);
      setState(() {
        _pingSeq++;
        _pingLines.add(_PingLine(
          '64 bytes from 8.8.8.8: icmp_seq=$_pingSeq ttl=$ttl time=$rtt ms',
          const Color(0xFF10B981),
          true,
        ));
      });
    }
    if (!mounted) return;
    setState(() => _pinging = false);
  }

  void _resetPing() => setState(() { _pingLines.clear(); _pinging = false; _pingSeq = 0; });

  // ── Simulation TCP Handshake ──────────────────────────────

  Future<void> _startTcp() async {
    if (_tcpRunning) return;
    setState(() { _tcpPhase = -1; _tcpRunning = true; });
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _tcpPhase = 0); // SYN
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => _tcpPhase = 1); // SYN-ACK
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => _tcpPhase = 2); // ACK
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() { _tcpPhase = 3; _tcpRunning = false; }); // done
  }

  void _resetTcp() => setState(() { _tcpPhase = -1; _tcpRunning = false; });

  // ── Simulation DNS Lookup ─────────────────────────────────

  Future<void> _startDns() async {
    if (_dnsRunning) return;
    final query = _dnsCtrl.text.trim().isEmpty ? 'google.com' : _dnsCtrl.text.trim();
    setState(() { _dnsRunning = true; _dnsSteps.clear(); _dnsQuery = query; });
    final rng = Random();

    final steps = [
      _DnsStep('Cache local', 'Vérification /etc/hosts et cache OS…', Colors.grey, false),
      _DnsStep('Résolveur 8.8.8.8', 'Query A $query → résolveur récursif', const Color(0xFF6366F1), false),
      _DnsStep('Root Server', 'Demande délégation .${query.split('.').last}', const Color(0xFFF59E0B), false),
      _DnsStep('TLD .${query.split('.').last}', 'NS records → serveur autoritaire', const Color(0xFF8B5CF6), false),
      _DnsStep('Autoritaire NS', 'Réponse finale : A record', const Color(0xFF10B981), true,
          ip: '${rng.nextInt(220) + 34}.${rng.nextInt(250) + 1}.${rng.nextInt(250) + 1}.${rng.nextInt(200) + 1}'),
    ];

    for (final s in steps) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _dnsSteps.add(s));
    }
    if (mounted) setState(() => _dnsRunning = false);
  }

  void _resetDns() => setState(() { _dnsSteps.clear(); _dnsRunning = false; });

  // ── Simulation SSH Auth ───────────────────────────────────

  Future<void> _startSsh() async {
    if (_sshRunning) return;
    setState(() { _sshRunning = true; _sshPhase = 0; });
    for (int p = 1; p <= 5; p++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _sshPhase = p);
    }
    if (mounted) setState(() => _sshRunning = false);
  }

  void _resetSsh() => setState(() { _sshPhase = -1; _sshRunning = false; });

  // ── Simulation Firewall ───────────────────────────────────

  void _testFirewall() {
    final port = int.tryParse(_fwPortCtrl.text.trim()) ?? 80;
    final blocked = [23, 25, 139, 445, 3389].contains(port);
    setState(() => _fwBlocked = blocked);
  }

  // ── Simulation principale (steps) ────────────────────────

  Future<void> _startSimulation() async {
    if (_running) return;
    setState(() { _running = true; _currentStep = -1; });
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
    setState(() { _currentStep = -1; _running = false; });
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
          topic: 'Internet — ${_scenario.name}',
          accentColor: _scenario.color,
          systemPrompt:
              'Tu es un expert en protocoles réseau et fonctionnement d\'Internet. Réponds en français. '
              'Contexte actuel : ${_scenario.name}. '
              'Domaines couverts : ICMP/ping, DNS, TCP/IP, TLS/HTTPS, HTTP/2, SSH, routage IP, '
              'pare-feu, NAT, ARP, modèle OSI, handshake TCP, résolution de noms.',
          suggestedQuestions: const [
            'Comment fonctionne le DNS ?',
            'Expliquer le 3-way handshake TCP',
            'C\'est quoi le TTL dans un ping ?',
            'Différence HTTP vs HTTPS ?',
            'Qu\'est-ce que le NAT ?',
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
                  'Scénarios explicatifs locaux. Exemples réseau synthétiques.',
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
            heroTag: 'internet_ai_fab',
            onPressed: _openAIPanel,
            backgroundColor: _scenario.color.withOpacity(0.9),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('IA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ── Panel interactif par scénario ─────────────────────────

  Widget _buildInteractivePanel() {
    switch (_scenarioIndex) {
      case 0: return _buildPingPanel();
      case 1: return _buildTcpPanel();
      case 2: return _buildSshPanel();
      case 3: return _buildLayersPanel();
      case 4: return _buildDnsPanel();
      case 5: return _buildFirewallPanel();
      default: return const SizedBox.shrink();
    }
  }

  Widget _panelShell({required Color color, required String title, required Widget child}) {
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Icon(Icons.terminal, color: color, size: 14),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const Spacer(),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  // 0 – Ping ────────────────────────────────────────────────
  Widget _buildPingPanel() {
    return _panelShell(
      color: const Color(0xFF06B6D4),
      title: 'PING SIMULATOR',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('target: ', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontFamily: 'monospace')),
                const Text('8.8.8.8 (Google DNS)', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontFamily: 'monospace')),
                const Spacer(),
                _simButton('Ping', const Color(0xFF06B6D4), _pinging ? null : _startPing),
                const SizedBox(width: 8),
                _simButton('Reset', Colors.grey, _resetPing),
              ],
            ),
            if (_pingLines.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _pingLines.length,
                  itemBuilder: (_, i) => _pingLines[i].success
                      ? Text(_pingLines[i].text,
                          style: TextStyle(color: _pingLines[i].color, fontSize: 11, fontFamily: 'monospace'))
                          .animate().fadeIn(duration: 300.ms)
                      : Text(_pingLines[i].text,
                          style: TextStyle(color: _pingLines[i].color, fontSize: 11, fontFamily: 'monospace')),
                ),
              ),
            ],
            if (_pinging)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFF06B6D4))),
                    const SizedBox(width: 8),
                    Text('Envoi paquet ICMP #${_pingSeq + 1}…', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 1 – TCP Handshake ───────────────────────────────────────
  Widget _buildTcpPanel() {
    final phases = [
      _TcpPhaseInfo('SYN', 'Client → Server', 'seq=1000', const Color(0xFF6366F1)),
      _TcpPhaseInfo('SYN-ACK', 'Server → Client', 'seq=5000 ack=1001', const Color(0xFF8B5CF6)),
      _TcpPhaseInfo('ACK', 'Client → Server', 'ack=5001', const Color(0xFF10B981)),
      _TcpPhaseInfo('ESTABLISHED', 'Connexion ouverte', 'Données peuvent transiter', const Color(0xFF10B981)),
    ];
    return _panelShell(
      color: const Color(0xFF6366F1),
      title: 'TCP 3-WAY HANDSHAKE',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _simButton('Simuler', const Color(0xFF6366F1), _tcpRunning ? null : _startTcp),
                const SizedBox(width: 8),
                _simButton('Reset', Colors.grey, _resetTcp),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _tcpNode('CLIENT\n192.168.1.10', Icons.computer, const Color(0xFF06B6D4), _tcpPhase >= 0),
                Expanded(
                  child: Column(
                    children: List.generate(phases.length, (i) {
                      final active = _tcpPhase >= i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? phases[i].color.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active ? phases[i].color.withOpacity(0.6) : Colors.white12,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (active) Icon(Icons.arrow_forward, color: phases[i].color, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${phases[i].name} — ${phases[i].flags}',
                                style: TextStyle(
                                  color: active ? phases[i].color : Colors.white24,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                _tcpNode('SERVER\n8.8.8.8:443', Icons.dns, const Color(0xFF6366F1), _tcpPhase >= 1),
              ],
            ),
            if (_tcpPhase == 3)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 6),
                    Text('Connexion TCP établie — prête pour TLS', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
              ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _tcpNode(String label, IconData icon, Color color, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? color : Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: active ? color : Colors.white24, size: 20),
          Text(label, style: TextStyle(color: active ? Colors.white70 : Colors.white24, fontSize: 9, fontFamily: 'monospace'), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // 2 – SSH ─────────────────────────────────────────────────
  Widget _buildSshPanel() {
    final phases = <_HiP3>[
      _HiP3('TCP:22 SYN', 'Ouverture connexion', const Color(0xFF8B5CF6)),
      _HiP3('KEX Init', 'Négociation curve25519', const Color(0xFFF59E0B)),
      _HiP3('Host Key', 'Vérif ed25519 fingerprint', const Color(0xFF06B6D4)),
      _HiP3('Auth', 'Clé publique acceptée', const Color(0xFF10B981)),
      _HiP3('Shell', 'Canal chiffré ouvert ✓', const Color(0xFF22C55E)),
    ];
    return _panelShell(
      color: const Color(0xFF10B981),
      title: 'SSH CONNECTION FLOW',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('user@192.168.1.10 → ', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontFamily: 'monospace')),
                const Text('root@server.example.com', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontFamily: 'monospace')),
                const Spacer(),
                _simButton('Connect', const Color(0xFF10B981), _sshRunning ? null : _startSsh),
                const SizedBox(width: 8),
                _simButton('Reset', Colors.grey, _resetSsh),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(phases.length, (i) {
              final active = _sshPhase > i;
              final current = _sshPhase == i + 1 && _sshRunning;
              final color = phases[i].c;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: active || current ? color.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: active || current ? color.withOpacity(0.5) : Colors.white12),
                ),
                child: Row(
                  children: [
                    if (current)
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                    else
                      Icon(active ? Icons.check_circle : Icons.radio_button_unchecked, color: active ? color : Colors.white24, size: 14),
                    const SizedBox(width: 8),
                    Text('[${i + 1}] ${phases[i].a}', style: TextStyle(color: active || current ? color : Colors.white24, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Expanded(child: Text('— ${phases[i].b}', style: TextStyle(color: active ? Colors.white54 : Colors.white24, fontSize: 10), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // 3 – TCP/IP Layers ───────────────────────────────────────
  Widget _buildLayersPanel() {
    final layers = [
      _HiP4('L7 App', 'HTTP/2 GET /', 'data: Hello World', const Color(0xFF6366F1)),
      _HiP4('L4 Transport', 'TCP header', 'sport=54321 dport=443 seq=1000', const Color(0xFF8B5CF6)),
      _HiP4('L3 Network', 'IP header', 'src=192.168.1.10 dst=142.250.179.46 ttl=64', const Color(0xFFF97316)),
      _HiP4('L2 Link', 'Ethernet frame', 'src=AA:BB:CC:DD dst=FF:EE:CC:BB type=0x0800', const Color(0xFFF59E0B)),
      _HiP4('L1 Physical', 'Signal', '01001000 01100101 01101100 … (bits)', const Color(0xFFEF4444)),
    ];
    return _panelShell(
      color: const Color(0xFFF59E0B),
      title: 'ENCAPSULATION VIEWER',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: List.generate(layers.length, (i) {
            final l = layers[i];
            return Container(
              margin: EdgeInsets.only(bottom: 4, left: i * 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: l.d.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border(left: BorderSide(color: l.d, width: 3)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 70, child: Text(l.a, style: TextStyle(color: l.d, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.b, style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
                        Text(l.c, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 9, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 100)).slideX(begin: 0.05, end: 0);
          }),
        ),
      ),
    );
  }

  // 4 – DNS ─────────────────────────────────────────────────
  Widget _buildDnsPanel() {
    return _panelShell(
      color: const Color(0xFFF59E0B),
      title: 'DNS RESOLVER',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dnsCtrl,
                    style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'Domaine à résoudre…',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                      prefixText: '> nslookup ',
                      prefixStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontFamily: 'monospace'),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _simButton('Resolve', const Color(0xFFF59E0B), _dnsRunning ? null : _startDns),
                const SizedBox(width: 8),
                _simButton('Clear', Colors.grey, _resetDns),
              ],
            ),
            if (_dnsSteps.isNotEmpty) ...[
              const SizedBox(height: 10),
              ..._dnsSteps.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: s.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: s.color.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(s.isAnswer ? Icons.check_circle : Icons.arrow_right, color: s.color, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.label, style: TextStyle(color: s.color, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        Text(s.detail, style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace')),
                        if (s.ip != null) Text('→ ${s.ip}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                      ],
                    )),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms)),
            ],
          ],
        ),
      ),
    );
  }

  // 5 – Firewall ────────────────────────────────────────────
  Widget _buildFirewallPanel() {
    return _panelShell(
      color: const Color(0xFFEF4444),
      title: 'FIREWALL RULES (iptables -L)',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._fwRules.map((r) {
              final accept = r.action == 'ACCEPT';
              final color = accept ? const Color(0xFF10B981) : const Color(0xFFEF4444);
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(6),
                  border: Border(left: BorderSide(color: color, width: 3)),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 56, child: Text(r.action, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
                    Expanded(child: Text('${r.state} — ${r.target}', style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fwPortCtrl,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontFamily: 'monospace'),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Port à tester…',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                      prefixText: 'tcp dport=',
                      prefixStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontFamily: 'monospace'),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _simButton('Tester', const Color(0xFFEF4444), _testFirewall),
              ],
            ),
            if (_fwPortCtrl.text.isNotEmpty && _fwBlocked != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(_fwBlocked),
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (_fwBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(_fwBlocked ? Icons.block : Icons.check_circle,
                          color: _fwBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _fwBlocked
                            ? 'Port ${_fwPortCtrl.text} → DROP (bloqué par règle)'
                            : 'Port ${_fwPortCtrl.text} → ACCEPT (autorisé)',
                        style: TextStyle(
                          color: _fwBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _simButton(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: onTap != null ? color.withOpacity(0.15) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: onTap != null ? color.withOpacity(0.5) : Colors.white12),
        ),
        child: Text(label, style: TextStyle(color: onTap != null ? color : Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ),
    );
  }

  // ── Scénario picker ───────────────────────────────────────

  Widget _buildScenarioPicker() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _scenarios.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final s = _scenarios[i];
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
                  Icon(s.icon, color: selected ? s.color : TdcColors.textMuted, size: 16),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: TextStyle(color: selected ? s.color : TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(s.subtitle, style: const TextStyle(color: TdcColors.textMuted, fontSize: 9)),
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
              decoration: BoxDecoration(color: s.color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(s.icon, color: s.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: TextStyle(color: s.color, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(s.subtitle, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (_currentStep >= 0)
              Text(
                done ? '✓ Terminé' : '${_currentStep + 1}/${s.steps.length}',
                style: TextStyle(color: done ? TdcColors.success : s.color, fontWeight: FontWeight.bold, fontSize: 12),
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
        opacity: state == _StepState.future ? 0.3 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: state == _StepState.active ? step.color.withOpacity(0.12) : TdcColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state == _StepState.active ? step.color : state == _StepState.done ? step.color.withOpacity(0.35) : TdcColors.border,
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
                              Expanded(child: Text(step.title, style: TextStyle(color: state != _StepState.future ? TdcColors.textPrimary : TdcColors.textMuted, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: step.color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text(step.protocol, style: TextStyle(color: step.color, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(step.description, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (state != _StepState.future)
                _buildStepDetail(step, state).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepNumber(int index, _Step step, _StepState state) {
    if (state == _StepState.active && _running) {
      return SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2, color: step.color));
    }
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state == _StepState.done ? step.color.withOpacity(0.2) : state == _StepState.active ? step.color.withOpacity(0.25) : TdcColors.surfaceAlt,
        border: Border.all(color: state == _StepState.future ? TdcColors.border : step.color),
      ),
      child: state == _StepState.done
          ? Icon(Icons.check, color: step.color, size: 16)
          : Center(child: Text('${index + 1}', style: TextStyle(color: state == _StepState.future ? TdcColors.textMuted : step.color, fontWeight: FontWeight.bold, fontSize: 13))),
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
          Text(step.detail, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12, height: 1.5)),
          if (step.visual != null) ...[const SizedBox(height: 12), step.visual!()],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _RetainButton(
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _running ? null : _startSimulation,
              icon: _running
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow),
              label: Text(_running ? 'Simulation en cours…' : 'Dérouler les étapes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _scenario.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (_currentStep >= 0) ...[
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TdcColors.textSecondary,
                side: const BorderSide(color: TdcColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

// ─── Data classes ────────────────────────────────────────────

class _PingLine {
  final String text;
  final Color color;
  final bool success;
  const _PingLine(this.text, this.color, this.success);
}

class _DnsStep {
  final String label;
  final String detail;
  final Color color;
  final bool isAnswer;
  final String? ip;
  const _DnsStep(this.label, this.detail, this.color, this.isAnswer, {this.ip});
}

class _TcpPhaseInfo {
  final String name;
  final String direction;
  final String flags;
  final Color color;
  const _TcpPhaseInfo(this.name, this.direction, this.flags, this.color);
}

class _FwRule {
  final String action;
  final String state;
  final String target;
  final Color color;
  const _FwRule(this.action, this.state, this.target, this.color);
}

class _HiP3 {
  final String a, b;
  final Color c;
  const _HiP3(this.a, this.b, this.c);
}

class _HiP4 {
  final String a, b, c;
  final Color d;
  const _HiP4(this.a, this.b, this.c, this.d);
}

// ─── Bouton "Retenir dans la Cheat Sheet" ────────────────────

class _RetainButton extends StatefulWidget {
  final String title, detail, category;
  const _RetainButton({required this.title, required this.detail, required this.category});
  @override State<_RetainButton> createState() => _RetainButtonState();
}

class _RetainButtonState extends State<_RetainButton> {
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
