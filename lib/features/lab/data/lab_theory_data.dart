// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// Données théoriques pour les Simulateurs
// ============================================================

const Map<String, String> labTheoryData = {
  'network': '''
# Les Fondamentaux du Réseau

Le réseau informatique permet la communication entre différents systèmes. Pour comprendre ce fonctionnement, on s'appuie principalement sur deux modèles théoriques : le modèle **OSI** et le modèle **TCP/IP**.

## Le Modèle OSI (Open Systems Interconnection)

Ce modèle théorique divise la communication réseau en 7 couches distinctes. Chaque couche a un rôle précis et communique uniquement avec les couches adjacentes.

1. **Couche Physique (L1)** : Transmission des bits bruts sur un canal de communication (câble cuivre, fibre optique, ondes radio). *Exemple : Ethernet, Wi-Fi 802.11.*
2. **Couche Liaison de Données (L2)** : Transfert de trames entre deux nœuds adjacents. Elle gère la détection d'erreurs (FCS) et l'adressage physique (Adresses MAC). *Exemple : Switch, VLAN, ARP.*
3. **Couche Réseau (L3)** : Routage des paquets à travers le réseau global. Elle utilise l'adressage logique. *Exemple : IP (IPv4, IPv6), ICMP (Ping), Routeurs.*
4. **Couche Transport (L4)** : Gestion des connexions de bout en bout et de la fiabilité. *Exemple : TCP (fiable, orienté connexion), UDP (rapide, sans connexion), Ports (ex: 80, 443).*
5. **Couche Session (L5)** : Établissement, maintien et terminaison des sessions de communication.
6. **Couche Présentation (L6)** : Formatage, chiffrement et compression des données (ex: TLS/SSL, JPEG).
7. **Couche Application (L7)** : Interface avec l'utilisateur final. *Exemple : HTTP, FTP, DNS, SMTP.*

## TCP vs UDP

**TCP (Transmission Control Protocol)** :
- Fiable : garantit la livraison des paquets dans l'ordre.
- Connecté : utilise un handshake à 3 voies (SYN, SYN-ACK, ACK) avant l'envoi.
- Contrôle de congestion : adapte son débit.
- *Utilisation : Web (HTTP), Email, Transfert de fichiers.*

**UDP (User Datagram Protocol)** :
- Non fiable : aucune garantie de livraison ("Fire and forget").
- Sans connexion : aucun overhead d'établissement.
- Rapide et léger.
- *Utilisation : Streaming vidéo, Jeux vidéo en temps réel, DNS.*

## Commandes Essentielles (Simulateur)

- **Ping (ICMP)** : Vérifie la connectivité de couche 3. Utile pour détecter si un hôte est en vie et mesurer la latence (Round-Trip Time).
- **Traceroute** : Identifie tous les routeurs (hops) entre vous et la destination en incrémentant le TTL (Time To Live).
- **Scan de Ports** : Découvre les services actifs sur une machine en testant l'ouverture des ports TCP/UDP.
- **Sniffing (Wireshark/Tcpdump)** : Capture les paquets transitant sur une interface pour une analyse approfondie (débogage, sécurité).
''',

  'linux': '''
# Le Cœur de Linux et l'Administration Système

GNU/Linux est un système d'exploitation de type Unix qui forme la base de l'infrastructure moderne (serveurs, cloud, conteneurs, smartphones Android).

## Architecture du Système

1. **Le Kernel (Noyau)** : Le cœur du système. Il interagit directement avec le matériel, gère la mémoire, les processus, les systèmes de fichiers et les permissions.
2. **Le Shell** : L'interface en ligne de commande (CLI) permettant à l'utilisateur de communiquer avec le kernel (ex: Bash, Zsh).
3. **Le User Space** : Les applications, démons (services en arrière-plan) et bibliothèques utilisés par les programmes.

## Gestion des Processus

Un **processus** est une instance d'un programme en exécution.
- Chaque processus possède un identifiant unique : le **PID** (Process ID).
- Le premier processus lancé par le kernel est `init` ou `systemd` (PID 1), qui devient le parent de tous les autres.
- Les états : *Running* (en cours), *Sleeping* (en attente), *Stopped* (suspendu), *Zombie* (terminé mais parent non notifié).

### Commandes clés
- `top` / `htop` : Surveillance en temps réel des processus et de l'usage CPU/RAM.
- `kill <PID>` : Envoie un signal (généralement SIGTERM ou SIGKILL) pour arrêter un processus.
- `ps aux` : Liste complète des processus actifs.

## Le Système de Fichiers (Filesystem)

Linux suit le standard FHS (Filesystem Hierarchy Standard). Tout part de la racine `/`.
- `/bin` & `/sbin` : Binaire essentiels (commandes).
- `/etc` : Fichiers de configuration globale.
- `/var` : Données variables (logs, bases de données).
- `/home` : Dossiers personnels des utilisateurs.
- `/dev` : Périphériques matériels (Everything is a file).

## Les Permissions (Chmod/Chown)

La sécurité Linux repose sur le paradigme Utilisateur, Groupe, Autres (UGO) et Lecture, Écriture, Exécution (RWX).
- **R (Read)** = 4
- **W (Write)** = 2
- **X (Execute)** = 1
- *Exemple : `chmod 755 fichier` donne RWX (7) au propriétaire, et RX (5) au groupe et aux autres.*
''',

  'algorithms': '''
# Algorithmique Avancée & Complexité

L'algorithmique est l'art de concevoir des séquences d'instructions efficaces pour résoudre un problème donné.

## Notation Big-O (Complexité Asymptotique)

La notation Big-O permet d'évaluer les performances d'un algorithme (en temps ou en mémoire) lorsque la taille des données d'entrée (n) tend vers l'infini, indépendamment de la puissance de l'ordinateur.

- **O(1)** - *Temps Constant* : L'accès à un élément de tableau ou de table de hachage.
- **O(log n)** - *Logarithmique* : Recherche dichotomique (binaire). Extrêmement efficace même pour des milliards d'éléments.
- **O(n)** - *Linéaire* : Parcours complet d'une liste.
- **O(n log n)** - *Quasi-linéaire* : Les meilleurs algorithmes de tri généralistes (Merge Sort, Quick Sort, Heap Sort).
- **O(n²)** - *Quadratique* : Tris naïfs (Bubble Sort, Insertion Sort). À éviter pour les grandes données.
- **O(2ⁿ)** - *Exponentiel* : Calcul brut de combinaisons (Fibonacci récursif sans mémoïsation).

## Structures de Données Essentielles

1. **Tableaux (Arrays)** : Accès O(1), mais insertion/suppression O(n) au milieu.
2. **Listes Chaînées** : Insertion O(1) si le pointeur est connu, accès O(n).
3. **Tables de Hachage (Hash Maps)** : Insertion, recherche et suppression en O(1) en moyenne. Structure reine pour les performances brutes.
4. **Arbres (Trees / BST / AVL / Red-Black)** : Recherche en O(log n). Utile pour maintenir des données triées.
5. **Graphes** : Représentation de réseaux (sociaux, routiers). Parcourus via BFS (largeur) ou DFS (profondeur).

## Programmation Dynamique (DP)

Technique d'optimisation (généralement appliquée aux problèmes récursifs) qui consiste à :
1. Diviser un problème complexe en sous-problèmes plus simples.
2. Stocker (Mémoïsation) le résultat de ces sous-problèmes pour ne pas les recalculer.
*Résultat : Une complexité exponentielle O(2ⁿ) peut souvent être réduite à une complexité linéaire O(n).*
''',

  'system': '''
# Architecture Système et Hardware

Comprendre le fonctionnement d'un ordinateur au plus bas niveau est crucial pour écrire du code performant.

## CPU (Central Processing Unit)

Le processeur exécute les instructions machine (assembleur). 
- **L'ALU (Arithmetic Logic Unit)** effectue les calculs mathématiques et logiques.
- **Les Registres** sont des espaces de mémoire extrêmement rapides intégrés au CPU.
- **Le Pipeline** permet d'exécuter plusieurs instructions simultanément en les découpant en étapes (Fetch, Decode, Execute, Write-back).

## La Hiérarchie Mémoire

L'accès à la mémoire est le principal goulot d'étranglement de l'informatique moderne (Von Neumann bottleneck). La hiérarchie est conçue du plus rapide/petit au plus lent/grand :
1. **Registres CPU** : 1 cycle d'horloge.
2. **Cache L1 / L2 / L3** : Mémoire SRAM ultra-rapide (quelques nanosecondes). Évite au CPU d'attendre la RAM.
3. **RAM (Random Access Memory)** : Mémoire principale, volatile. Accès en ~100 nanosecondes.
4. **Stockage (SSD NVMe, HDD)** : Non-volatile. Accès en microsecondes (SSD) ou millisecondes (HDD).

## Gestion de la Mémoire (OS)

Le système d'exploitation gère la mémoire physique de manière sécurisée via la **Mémoire Virtuelle**.
- Chaque processus a l'illusion de posséder toute la RAM.
- Le CPU (via la MMU - Memory Management Unit) traduit les adresses virtuelles en adresses physiques (Paging).
- Si la RAM est pleine, l'OS déplace des pages inactives sur le disque dur (**Swap**), ce qui ralentit considérablement le système.
''',

  'cloud': '''
# Cloud Computing & DevOps

Le Cloud computing consiste à déporter la puissance de calcul, le stockage et l'infrastructure réseau vers des data centers externes (AWS, GCP, Azure), accessibles via Internet.

## Modèles de Services

- **IaaS (Infrastructure as a Service)** : Fourniture de machines virtuelles nues, de stockage brut et de réseaux (ex: AWS EC2). Vous gérez l'OS et l'application.
- **PaaS (Platform as a Service)** : L'infrastructure et l'environnement d'exécution sont gérés. Vous ne déployez que votre code (ex: Heroku, AWS Elastic Beanstalk).
- **SaaS (Software as a Service)** : Le logiciel complet est fourni prêt à l'emploi (ex: Gmail, Salesforce).
- **FaaS (Function as a Service / Serverless)** : Vous écrivez juste des fonctions qui s'exécutent en réponse à des événements (ex: AWS Lambda). Pas de serveurs à provisionner, facturation à la milliseconde.

## DevOps, CI/CD et Conteneurisation

Le DevOps est une philosophie visant à unifier le développement (Dev) et l'administration système (Ops).
- **CI/CD (Continuous Integration / Continuous Deployment)** : Automatisation des tests et du déploiement à chaque commit (ex: GitHub Actions, GitLab CI).
- **Conteneurs (Docker)** : Encapsulation d'une application et de toutes ses dépendances dans un paquet léger, portable et isolé. Contrairement aux machines virtuelles, les conteneurs partagent le même noyau Linux, ce qui les rend ultra-rapides.
- **Orchestration (Kubernetes)** : Gestion automatisée de centaines ou milliers de conteneurs (déploiement, scalabilité, tolérance aux pannes).
''',

  'crypto': '''
# Cryptographie et Sécurité des Données

La cryptographie garantit la confidentialité, l'intégrité, l'authenticité et la non-répudiation des communications.

## Cryptographie Symétrique

Une **clé unique** est utilisée pour chiffrer et déchiffrer les données.
- **Avantage** : Extrêmement rapide (accéléré matériellement par les CPU modernes via AES-NI).
- **Inconvénient** : Problème de distribution de la clé (comment envoyer la clé secrète à l'autre partie de manière sécurisée ?).
- **Standard actuel** : AES (Advanced Encryption Standard), utilisé en 128 ou 256 bits (ex: AES-GCM).

## Cryptographie Asymétrique (Clé Publique)

Utilisation d'une **paire de clés** :
1. Une **clé publique** (distribuée à tout le monde) pour chiffrer.
2. Une **clé privée** (secrète) pour déchiffrer.
- **Avantage** : Résout le problème de la distribution de clés.
- **Inconvénient** : Mathématiquement complexe et très lent (souvent 1000x plus lent que le symétrique).
- **Standards** : RSA (basé sur la factorisation de grands nombres premiers), ECC (Courbes Elliptiques, très utilisé aujourd'hui pour sa sécurité élevée avec de petites clés, ex: Bitcoin, TLS).

*En pratique, on utilise des systèmes hybrides (ex: TLS/HTTPS) : On utilise l'asymétrique (lent) pour s'authentifier et échanger une clé symétrique temporaire (rapide), qui servira à chiffrer le reste de la session.*

## Fonctions de Hachage

Le hachage (Hashing) transforme une donnée de taille arbitraire en une empreinte de taille fixe.
- C'est un processus **à sens unique** (One-way) : on ne peut pas déchiffrer un hash.
- **Propriété d'avalanche** : Changer 1 bit de l'entrée modifie complètement le hash.
- **Utilisations** : Stockage de mots de passe (avec ajout de sel/salt), vérification de l'intégrité de fichiers, signatures numériques, Blockchains.
- **Standards** : SHA-256, SHA-3, Argon2 (pour les mots de passe).
''',

  'security': '''
# Cybersécurité : Attaques et Défenses

La sécurité informatique est un jeu du chat et de la souris consistant à identifier et exploiter des vulnérabilités, puis à les corriger.

## Catégories d'Attaques Web Courantes (OWASP)

1. **Injection SQL (SQLi)** : Insertion de requêtes SQL malveillantes via des champs d'entrée non sécurisés pour manipuler ou exfiltrer la base de données. *Défense : Requêtes préparées (Prepared Statements).*
2. **XSS (Cross-Site Scripting)** : Injection de scripts (souvent JavaScript) dans les pages web vues par d'autres utilisateurs pour voler des cookies de session. *Défense : Échappement des entrées, CSP (Content Security Policy).*
3. **CSRF (Cross-Site Request Forgery)** : Forcer le navigateur d'un utilisateur authentifié à exécuter des actions non désirées sur un site de confiance. *Défense : Jetons anti-CSRF.*
4. **DDoS (Distributed Denial of Service)** : Submerger un serveur de requêtes depuis une multitude de machines compromises (botnet) pour le rendre indisponible. *Défense : WAF, Cloudflare, rate limiting.*

## Cryptanalyse et Bruteforce

- **Attaque par Dictionnaire** : Tester tous les mots d'une liste prédéfinie.
- **Bruteforce** : Tester toutes les combinaisons possibles. Seule l'augmentation de l'entropie (longueur du mot de passe) peut la contrer.
- **Rainbow Tables** : Utiliser des tables précalculées de hachages pour retrouver un mot de passe instantanément. *Défense : Ajout d'un sel (Salt) unique à chaque mot de passe avant de le hacher.*
''',

  'internet': '''
# L'Architecture de l'Internet

L'Internet est un "réseau de réseaux" maillé et décentralisé. Il repose sur un ensemble de protocoles standards (TCP/IP) régis par l'IETF.

## L'Adressage et le Routage

1. **Adresses IP (IPv4 et IPv6)** : L'identifiant logique de chaque appareil connecté. IPv4 est saturé (environ 4 milliards d'adresses), d'où la transition vers IPv6.
2. **BGP (Border Gateway Protocol)** : Le protocole de routage d'Internet. Il permet aux différents Systèmes Autonomes (AS) (fournisseurs d'accès, opérateurs de transit) d'échanger leurs routes et de déterminer le meilleur chemin mondial pour un paquet.

## DNS (Domain Name System)

Le DNS est l'annuaire d'Internet. Il traduit les noms de domaine compréhensibles (www.tutodecode.org) en adresses IP requises pour la communication machine.
C'est un système hiérarchique et distribué :
- Serveurs Root (.)
- Serveurs TLD (.com, .org)
- Serveurs Autoritaires (ceux qui possèdent l'enregistrement final).

## HTTP et le Web

Le Web n'est qu'un des nombreux services d'Internet, reposant sur le protocole HTTP.
- HTTP est un protocole *Stateless* (sans état) : chaque requête est indépendante. Pour maintenir une session (ex: rester connecté), on utilise des **Cookies** ou des **Tokens** (ex: JWT).
- **HTTPS** ajoute la couche TLS pour chiffrer la connexion de bout en bout, empêchant l'écoute clandestine (Man-in-the-Middle) et garantissant l'identité du serveur via des certificats X.509.
''',
};
