// ============================================================
// Algorithms Simulator
// Explications théoriques interactives et animées :
//   • Tri & Recherche (Big-O, Bubble, Merge, Quick, Binaire, Hash)
//   • Graphes (BFS, DFS, Dijkstra, Bellman-Ford, A*)
//   • Programmation Dynamique (mémoïsation, tabulation, DP classiques)
//   • Cryptographie (XOR, AES, RSA, ECDSA, SHA-256, Diffie-Hellman)
//   • Systèmes Distribués (CAP, Paxos, Consistent Hashing, Bloom…)
//   • Automates & Compilateurs (DFA, CFG, lexer, parser, AST)
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

final _algoScenarios = [
  // ── 1. Tri & Recherche ──────────────────────────────────────
  _Scenario(
    name: 'Tri & Recherche',
    subtitle: 'Big-O · Sorting · Binary Search · Hash',
    icon: Icons.sort,
    color: Colors.blue,
    steps: [
      _Step(
        title: 'Complexité Big-O notation',
        protocol: 'Analyse asymptotique',
        icon: Icons.show_chart,
        color: const Color(0xFF2196F3),
        description: 'Mesurer l\'efficacité d\'un algorithme indépendamment du matériel.',
        detail:
            'La notation Big-O décrit la croissance du temps d\'exécution (ou de l\'espace mémoire) '
            'en fonction de la taille de l\'entrée n, en ignorant les constantes et les termes dominés. '
            'Les classes courantes sont O(1) constant, O(log n) logarithmique, O(n) linéaire, '
            'O(n log n) quasi-linéaire, O(n²) quadratique et O(2ⁿ) exponentiel. '
            'On distingue le pire cas (worst-case), le cas moyen (average-case) et le meilleur cas '
            '(best-case) — en pratique, c\'est le worst-case qui guide les décisions d\'ingénierie.',
        visual: () => const SimComplexityBar(
          entries: [
            SimComplexityEntry('O(1)', 'constant', 0.05, Color(0xFF10B981)),
            SimComplexityEntry('O(log n)', 'binary search', 0.15, Color(0xFF06B6D4)),
            SimComplexityEntry('O(n)', 'linear', 0.35, Color(0xFF3B82F6)),
            SimComplexityEntry('O(n log n)', 'merge sort', 0.55, Color(0xFFF97316)),
            SimComplexityEntry('O(n²)', 'bubble sort', 0.85, Color(0xFFEF4444)),
            SimComplexityEntry('O(2ⁿ)', 'exponential', 1.0, Colors.deepOrange),
          ],
        ),
      ),
      _Step(
        title: 'Bubble Sort O(n²)',
        protocol: 'Tri par comparaison',
        icon: Icons.bubble_chart,
        color: const Color(0xFF1976D2),
        description: 'Algorithme de tri naïf : comparer et permuter les voisins successivement.',
        detail:
            'Bubble Sort parcourt le tableau n fois et échange les éléments adjacents '
            'hors ordre. Après chaque passe, l\'élément le plus grand "remonte" à sa position finale, '
            'ce qui donne O(n²) comparaisons dans le pire cas et O(n²/2) en moyenne. '
            'Il est stable (préserve l\'ordre relatif des éléments égaux) et in-place (O(1) mémoire '
            'auxiliaire), mais ses performances médiocres le rendent inutilisable en production '
            'au-delà de quelques centaines d\'éléments.',
        visual: () => SimCodeBlock(
          color: const Color(0xFF1976D2),
          title: 'Bubble Sort',
          code: 'function bubbleSort(arr):\n'
              '  n = arr.length\n'
              '  for i in 0..n-1:\n'
              '    for j in 0..n-i-2:\n'
              '      if arr[j] > arr[j+1]:\n'
              '        swap(arr[j], arr[j+1])\n'
              '  return arr\n'
              '\n'
              '# O(n²) comparaisons, O(1) espace\n'
              '# Stable: oui, In-place: oui',
        ),
      ),
      _Step(
        title: 'Merge Sort O(n log n)',
        protocol: 'Diviser pour régner',
        icon: Icons.call_split,
        color: const Color(0xFF1565C0),
        description: 'Diviser le tableau en deux moitiés, trier récursivement, puis fusionner.',
        detail:
            'Merge Sort divise le tableau en deux sous-tableaux de taille n/2, se rappelle '
            'récursivement sur chaque moitié (profondeur log n), puis fusionne les deux moitiés '
            'triées en O(n). Le coût total est O(n log n) dans tous les cas (best, average, worst). '
            'Il est stable et particulièrement adapté au tri externe (données sur disque) car '
            'il accède aux données séquentiellement, mais requiert O(n) d\'espace auxiliaire.',
        visual: () => const SimTreeDiagram(
          color: Color(0xFF1565C0),
          root: SimTreeNode(
            '[8,3,5,1]',
            sublabel: 'diviser',
            children: [
              SimTreeNode('[8,3]', sublabel: 'gauche', children: [
                SimTreeNode('[8]', sublabel: 'feuille'),
                SimTreeNode('[3]', sublabel: 'feuille'),
              ]),
              SimTreeNode('[5,1]', sublabel: 'droite', children: [
                SimTreeNode('[5]', sublabel: 'feuille'),
                SimTreeNode('[1]', sublabel: 'feuille'),
              ]),
            ],
          ),
        ),
      ),
      const _Step(
        title: 'Quick Sort O(n log n) avg',
        protocol: 'Pivot & partition',
        icon: Icons.flash_on,
        color: Color(0xFF0D47A1),
        description: 'Choisir un pivot, partitionner, puis trier récursivement les deux partitions.',
        detail:
            'Quick Sort choisit un pivot, réorganise le tableau en deux partitions '
            '(éléments ≤ pivot à gauche, ≥ pivot à droite) en O(n), puis se rappelle sur chacune. '
            'En moyenne O(n log n) avec pivot aléatoire, mais O(n²) dans le pire cas (tableau déjà '
            'trié et pivot toujours le plus petit). In-place (O(log n) de pile de récursion), '
            'et souvent plus rapide en pratique que Merge Sort grâce à la localité du cache.',
      ),
      const _Step(
        title: 'Recherche binaire O(log n)',
        protocol: 'Binary Search',
        icon: Icons.search,
        color: Color(0xFF42A5F5),
        description: 'Chercher dans un tableau trié en divisant l\'intervalle par deux à chaque étape.',
        detail:
            'La recherche binaire compare la valeur cible à l\'élément médian du tableau trié. '
            'Si la cible est inférieure, on cherche dans la moitié gauche ; sinon dans la droite. '
            'À chaque étape, l\'espace de recherche est divisé par deux, d\'où O(log n). '
            'Pour n = 1 000 000, il faut au plus 20 comparaisons (log₂(10⁶) ≈ 20). '
            'Prérequis absolu : le tableau doit être trié. Variante : interpolation search O(log log n) '
            'si les données sont uniformément distribuées.',
      ),
      const _Step(
        title: 'Hash table O(1) avg',
        protocol: 'Hachage & chaînage',
        icon: Icons.grid_3x3,
        color: Color(0xFF64B5F6),
        description: 'Accéder, insérer et supprimer en temps constant en moyenne grâce à une fonction de hachage.',
        detail:
            'Une table de hachage calcule h(key) = hash(key) % capacity pour trouver l\'index du bucket. '
            'Les collisions sont résolues par chaînage (liste chaînée par bucket) ou adressage ouvert '
            '(sondage linéaire, quadratique ou double hachage). '
            'Le facteur de charge α = n/m (n éléments, m buckets) doit rester bas (< 0.7) pour '
            'maintenir O(1) amorti. Au-delà, la table est redimensionnée (rehashing). '
            'Pire cas O(n) si toutes les clés collisionnent — les fonctions de hachage cryptographiques '
            'ou les graines aléatoires (hash flooding protection) protègent contre les attaques.',
      ),
    ],
  ),

  // ── 2. Graphes ──────────────────────────────────────────────
  _Scenario(
    name: 'Graphes',
    subtitle: 'BFS · DFS · Dijkstra · Bellman-Ford · A*',
    icon: Icons.account_tree,
    color: Colors.green,
    steps: [
      const _Step(
        title: 'Représentation (matrice/liste adjacence)',
        protocol: 'Structures de données',
        icon: Icons.table_chart,
        color: Color(0xFF4CAF50),
        description: 'Deux façons canoniques de représenter un graphe G = (V, E) en mémoire.',
        detail:
            'La matrice d\'adjacence stocke un booléen (ou un poids) pour chaque paire (u, v) '
            'en O(V²) espace — idéale pour les graphes denses et les requêtes "est-ce que (u,v) existe ?" '
            'en O(1). La liste d\'adjacence stocke pour chaque sommet sa liste de voisins en O(V+E) '
            'espace — idéale pour les graphes creux et le parcours des voisins en O(deg(v)). '
            'En pratique, les graphes réels (réseaux sociaux, routiers, web) sont très creux '
            '(E << V²), donc les listes d\'adjacence dominent largement.',
      ),
      _Step(
        title: 'BFS (file, O(V+E))',
        protocol: 'Breadth-First Search',
        icon: Icons.waves,
        color: const Color(0xFF43A047),
        description: 'Explorer un graphe niveau par niveau à partir d\'une source.',
        detail:
            'BFS utilise une file (FIFO) : on enfile le sommet source, puis on défile un sommet, '
            'on visite tous ses voisins non encore visités, on les enfile, et on recommence. '
            'Chaque sommet est traité une fois (O(V)) et chaque arête examinée deux fois (O(E)). '
            'BFS garantit le plus court chemin en nombre d\'arêtes (non pondéré) et permet de '
            'détecter les composantes connexes. Il est aussi à la base du test de bipartisme '
            '(2-coloration) et du calcul des niveaux dans un arbre BFS.',
        visual: () => SimFlowDiagram(
          color: const Color(0xFF43A047),
          nodes: const [
            SimFlowNode('A', Icons.circle),
            SimFlowNode('B', Icons.circle),
            SimFlowNode('C', Icons.circle),
            SimFlowNode('D', Icons.circle),
          ],
        ),
      ),
      const _Step(
        title: 'DFS (pile/récursion, O(V+E))',
        protocol: 'Depth-First Search',
        icon: Icons.vertical_align_bottom,
        color: Color(0xFF388E3C),
        description: 'Explorer en profondeur d\'abord, en reculant quand on atteint un cul-de-sac.',
        detail:
            'DFS utilise une pile implicite (récursion) ou explicite. Il s\'enfonce aussi loin '
            'que possible avant de backtracker. Complexité O(V+E). '
            'Applications : tri topologique (ordre d\'exécution des tâches), détection de cycles, '
            'composantes fortement connexes (algorithme de Tarjan ou Kosaraju), résolution de labyrinthes. '
            'L\'ordre de visite (pré-ordre, post-ordre, in-ordre) encode des informations utiles : '
            'le post-ordre inversé donne le tri topologique.',
      ),
      _Step(
        title: 'Dijkstra (poids positifs)',
        protocol: 'Plus court chemin',
        icon: Icons.alt_route,
        color: const Color(0xFF2E7D32),
        description: 'Trouver le plus court chemin depuis une source dans un graphe à poids positifs.',
        detail:
            'Dijkstra maintient un tas min (priority queue) de paires (distance, sommet). '
            'On extrait le sommet de distance minimale, on relaxe ses voisins '
            '(si d[u] + w(u,v) < d[v], on met à jour d[v]) et on répète. '
            'Complexité O((V+E) log V) avec un tas binaire, O(V log V + E) avec un tas de Fibonacci. '
            'Crucial : ne fonctionne PAS avec des poids négatifs (un poids négatif pourrait améliorer '
            'indéfiniment un chemin déjà traité). Utilisé dans les GPS, OSPF, A* en IA.',
        visual: () => const SimKeyValue(
          color: Color(0xFF2E7D32),
          entries: [
            SimKVEntry('Dist A→B', '3'),
            SimKVEntry('Dist A→C', '1'),
            SimKVEntry('Dist A→D', '4 (via C)'),
            SimKVEntry('Dist A→E', '6 (via C→D)'),
          ],
        ),
      ),
      const _Step(
        title: 'Bellman-Ford (poids négatifs)',
        protocol: 'Relaxation itérative',
        icon: Icons.repeat,
        color: Color(0xFF66BB6A),
        description: 'Plus court chemin tolérant les poids négatifs, et détectant les cycles négatifs.',
        detail:
            'Bellman-Ford effectue V-1 passages sur toutes les arêtes, en relaxant à chaque fois. '
            'Après V-1 itérations, si une relaxation est encore possible, il existe un cycle de poids '
            'négatif (détecté au passage V). Complexité O(V·E) — plus lent que Dijkstra. '
            'Il est utilisé dans le protocole de routage RIP (distance-vector) et pour détecter '
            'les arbitrages dans les marchés financiers (cycle de change négatif en log-espace).',
      ),
      const _Step(
        title: 'A* (heuristique)',
        protocol: 'Recherche heuristique',
        icon: Icons.star,
        color: Color(0xFFA5D6A7),
        description: 'Dijkstra guidé par une heuristique pour accélérer la recherche de chemin.',
        detail:
            'A* évalue chaque sommet par f(n) = g(n) + h(n), où g(n) est le coût réel depuis '
            'la source et h(n) est une heuristique admissible (jamais surestimer le coût restant). '
            'Si h(n) = 0, A* est identique à Dijkstra. Si h(n) = distance euclidienne (pathfinding 2D), '
            'A* explore nettement moins de sommets. Propriété d\'optimalité : si h est admissible '
            'et consistante (h(n) ≤ w(n,n\') + h(n\')), A* trouve toujours le chemin optimal. '
            'Massivement utilisé dans les jeux vidéo, la robotique et les cartes (Google Maps).',
      ),
    ],
  ),

  // ── 3. Programmation Dynamique ──────────────────────────────
  _Scenario(
    name: 'Programmation Dynamique',
    subtitle: 'Mémoïsation · Tabulation · DP classiques',
    icon: Icons.grid_view,
    color: Colors.orange,
    steps: [
      const _Step(
        title: 'Sous-problèmes chevauchants',
        protocol: 'Principe fondamental',
        icon: Icons.layers,
        color: Color(0xFFFF9800),
        description: 'Décomposer un problème en sous-problèmes qui se répètent.',
        detail:
            'La programmation dynamique (DP) s\'applique quand un problème satisfait deux propriétés : '
            'la sous-structure optimale (la solution optimale du problème global contient '
            'les solutions optimales des sous-problèmes) et les sous-problèmes chevauchants '
            '(les mêmes sous-problèmes sont résolus plusieurs fois dans une approche naïve). '
            'Sans DP, Fibonacci naïf recalcule fib(3) un nombre exponentiel de fois ; '
            'avec DP, chaque valeur est calculée une seule fois → O(n) au lieu de O(2ⁿ).',
      ),
      const _Step(
        title: 'Mémoïsation top-down',
        protocol: 'Cache récursif',
        icon: Icons.cached,
        color: Color(0xFFF57C00),
        description: 'Approche récursive avec mise en cache des résultats déjà calculés.',
        detail:
            'La mémoïsation conserve la structure récursive naturelle du problème en ajoutant '
            'un dictionnaire de cache : avant de calculer un sous-problème, on vérifie si le '
            'résultat est déjà en cache. Si oui, retour immédiat ; sinon, calcul et stockage. '
            'Avantages : code proche de la définition mathématique, ne calcule que les sous-problèmes '
            'réellement nécessaires (lazy evaluation). Inconvénient : overhead de la récursion '
            '(pile d\'appels, allocation) et risque de stack overflow sur de grandes entrées.',
      ),
      const _Step(
        title: 'Tabulation bottom-up',
        protocol: 'Table itérative',
        icon: Icons.table_rows,
        color: Color(0xFFE65100),
        description: 'Remplir itérativement un tableau en partant des cas de base.',
        detail:
            'La tabulation construit la table DP de bas en haut, en garantissant que '
            'quand on calcule dp[i], tous les sous-problèmes dont il dépend sont déjà remplis. '
            'Avantages : pas de récursion (pas de stack overflow), meilleure localité du cache CPU, '
            'souvent plus rapide en pratique. Inconvénient : on calcule tous les sous-problèmes '
            'même ceux inutiles. L\'optimisation d\'espace consiste à ne garder que les lignes/colonnes '
            'nécessaires (ex: Fibonacci en O(1) au lieu de O(n) en gardant seulement les 2 dernières valeurs).',
      ),
      _Step(
        title: 'Fibonacci DP',
        protocol: 'Exemple canonique',
        icon: Icons.calculate,
        color: const Color(0xFFFF6D00),
        description: 'Calculer F(n) = F(n-1) + F(n-2) efficacement avec DP.',
        detail:
            'Fibonacci naïf : T(n) = T(n-1) + T(n-2) + O(1) → O(2ⁿ) appels. '
            'Fibonacci DP bottom-up : dp[0]=0, dp[1]=1, puis dp[i] = dp[i-1] + dp[i-2] → O(n) temps, O(n) espace. '
            'Optimisation espace : garder uniquement (a, b) → O(1) espace. '
            'Encore plus rapide : exponentiation matricielle de la matrice [[1,1],[1,0]] → O(log n). '
            'Fibonacci illustre tous les niveaux de DP et montre comment l\'analyse de complexité '
            'peut transformer un problème exponentiel en problème polynomial.',
        visual: () => SimCodeBlock(
          color: const Color(0xFFFF6D00),
          title: 'Fibonacci — memo vs naive',
          code: '# Naive O(2^n)\n'
              'def fib_naive(n):\n'
              '  if n <= 1: return n\n'
              '  return fib_naive(n-1) + fib_naive(n-2)\n'
              '\n'
              '# Memo O(n)\n'
              'cache = {}\n'
              'def fib_memo(n):\n'
              '  if n in cache: return cache[n]\n'
              '  if n <= 1: return n\n'
              '  cache[n] = fib_memo(n-1) + fib_memo(n-2)\n'
              '  return cache[n]',
        ),
      ),
      const _Step(
        title: 'Sac à dos 0/1',
        protocol: '0/1 Knapsack',
        icon: Icons.shopping_bag,
        color: Color(0xFFFFA726),
        description: 'Maximiser la valeur dans un sac de capacité W avec n objets (chacun pris 0 ou 1 fois).',
        detail:
            'État : dp[i][w] = valeur max avec les i premiers objets et une capacité restante w. '
            'Transition : dp[i][w] = max(dp[i-1][w], dp[i-1][w-wi] + vi) si wi ≤ w. '
            'Complexité : O(n·W) temps et espace (pseudo-polynomiale — NP-difficile en général). '
            'Optimisation espace : tableau 1D en parcourant w de W vers 0. '
            'Variante sac à dos fractionnaire (Greedy, O(n log n)), sac à dos illimité '
            '(unbounded knapsack, parcours croissant de w). '
            'Applications : sélection de projets, découpe de matériaux, cryptographie (schéma de Merkle-Hellman).',
      ),
      const _Step(
        title: 'Longest Common Subsequence',
        protocol: 'LCS · Alignement',
        icon: Icons.compare_arrows,
        color: Color(0xFFFFCC02),
        description: 'Trouver la plus longue sous-séquence commune à deux chaînes.',
        detail:
            'LCS(X, Y) avec |X|=m, |Y|=n. État : dp[i][j] = longueur de LCS(X[1..i], Y[1..j]). '
            'Transition : si X[i]=Y[j] alors dp[i][j] = dp[i-1][j-1] + 1, '
            'sinon dp[i][j] = max(dp[i-1][j], dp[i][j-1]). '
            'O(m·n) temps et espace, optimisable en O(min(m,n)) espace. '
            'Applications fondamentales : diff (git diff, Unix diff), alignement de séquences ADN '
            '(bioinformatique), détection de plagiat, et Distance de Levenshtein (edit distance) '
            'qui ajoute l\'opération d\'insertion et de substitution.',
      ),
    ],
  ),

  // ── 4. Cryptographie ────────────────────────────────────────
  _Scenario(
    name: 'Cryptographie',
    subtitle: 'XOR · AES · RSA · ECDSA · SHA-256 · DH',
    icon: Icons.lock,
    color: Colors.purple,
    steps: [
      const _Step(
        title: 'XOR & one-time pad',
        protocol: 'Chiffrement parfait',
        icon: Icons.enhanced_encryption,
        color: Color(0xFF9C27B0),
        description: 'L\'opération XOR bit-à-bit est la brique élémentaire de la cryptographie symétrique.',
        detail:
            'XOR (⊕) : 0⊕0=0, 0⊕1=1, 1⊕1=0. Propriété : C = M ⊕ K → M = C ⊕ K (auto-inverse). '
            'Le one-time pad (Vernam, 1917) : clé aléatoire aussi longue que le message, utilisée une seule fois. '
            'Il est prouvé théoriquement incassable (Shannon, 1949) car chaque ciphertext correspond '
            'à tous les messages possibles avec une probabilité égale. '
            'Limite pratique : distribution sécurisée d\'une clé aussi longue que le message — '
            'c\'est pourquoi la cryptographie moderne préfère les chiffrements pseudo-aléatoires.',
      ),
      const _Step(
        title: 'Chiffrement symétrique AES',
        protocol: 'AES-256-GCM',
        icon: Icons.vpn_key,
        color: Color(0xFF8E24AA),
        description: 'Standard mondial de chiffrement symétrique — même clé pour chiffrer et déchiffrer.',
        detail:
            'AES (Advanced Encryption Standard) opère sur des blocs de 128 bits avec des clés '
            'de 128, 192 ou 256 bits. Il effectue 10/12/14 rondes de 4 opérations : '
            'SubBytes (substitution S-Box), ShiftRows (rotation de lignes), MixColumns (combinaison linéaire), '
            'AddRoundKey (XOR avec la sous-clé dérivée). '
            'AES-GCM ajoute l\'authentification (AEAD — Authenticated Encryption with Associated Data), '
            'garantissant intégrité et confidentialité simultanément. '
            'Vitesse : ~1 Gbit/s sur CPU moderne grâce aux instructions AES-NI.',
      ),
      _Step(
        title: 'RSA (clés publique/privée)',
        protocol: 'Cryptographie asymétrique',
        icon: Icons.key,
        color: const Color(0xFF7B1FA2),
        description: 'Chiffrer avec la clé publique, déchiffrer avec la clé privée — basé sur la factorisation.',
        detail:
            'RSA repose sur la difficulté de factoriser n = p·q (deux grands premiers). '
            'Génération : choisir p, q premiers, n = p·q, φ(n) = (p-1)(q-1), '
            'choisir e copremier avec φ(n) (souvent 65537), calculer d = e⁻¹ mod φ(n). '
            'Clé publique : (n, e) ; clé privée : (n, d). '
            'Chiffrement : C = Mᵉ mod n. Déchiffrement : M = Cᵈ mod n. '
            'RSA 2048 bits est standard ; RSA 4096 pour haute sécurité. '
            'En pratique, RSA n\'est pas utilisé directement sur les données (lent) mais pour '
            'échanger une clé symétrique (hybrid encryption).',
        visual: () => const SimKeyValue(
          color: Color(0xFF7B1FA2),
          entries: [
            SimKVEntry('p x q = n', 'clé publique modulus'),
            SimKVEntry('e', 'exposant public (65537)'),
            SimKVEntry('d', 'clé privée: d×e ≡ 1 (mod φ(n))'),
            SimKVEntry('Chiffrer', 'c = mᵉ mod n'),
            SimKVEntry('Déchiffrer', 'm = cᵈ mod n'),
          ],
        ),
      ),
      const _Step(
        title: 'Courbes elliptiques ECDSA',
        protocol: 'ECC · Signatures',
        icon: Icons.timeline,
        color: Color(0xFFBA68C8),
        description: 'Cryptographie sur courbes elliptiques — sécurité maximale pour des clés courtes.',
        detail:
            'Une courbe elliptique est définie par y² = x³ + ax + b (mod p). '
            'L\'opération de base est l\'addition de points P + Q = R sur la courbe. '
            'La multiplication scalaire k·P (k additions) est facile à calculer, mais '
            'retrouver k depuis k·P est le problème du logarithme discret sur courbe elliptique — '
            'computationnellement infaisable. '
            'ECDSA avec secp256k1 (Bitcoin) ou P-256 (TLS) offre la sécurité de RSA-3072 '
            'avec une clé de seulement 256 bits → signatures plus compactes et calculs plus rapides. '
            'Ed25519 (EdDSA) est encore plus rapide et résistant aux timing attacks.',
      ),
      const _Step(
        title: 'SHA-256 & Merkle trees',
        protocol: 'Fonctions de hachage',
        icon: Icons.fingerprint,
        color: Color(0xFFCE93D8),
        description: 'Fonction de hachage cryptographique one-way — empreinte unique et déterministe.',
        detail:
            'SHA-256 produit un hash de 256 bits depuis un message de taille quelconque. '
            'Propriétés : déterminisme, résistance à la préimage (impossible de retrouver M depuis H(M)), '
            'résistance aux collisions (impossible de trouver M ≠ M\' avec H(M) = H(M\')), '
            'effet avalanche (1 bit changé → ~50% des bits du hash changent). '
            'Un Merkle tree hash récursivement les feuilles : H(parent) = H(H(left) || H(right)). '
            'La racine (Merkle root) résume tout le jeu de données — un seul hash de 256 bits '
            'authentifie n\'importe quelle transaction Bitcoin ou bloc Git en O(log n) grâce '
            'aux preuves d\'inclusion (Merkle proofs).',
      ),
      _Step(
        title: 'Protocole Diffie-Hellman',
        protocol: 'Échange de clés',
        icon: Icons.sync_alt,
        color: const Color(0xFFE1BEE7),
        description: 'Établir un secret partagé sur un canal public sans jamais l\'envoyer.',
        detail:
            'DH classique (1976) : Alice et Bob partagent p (grand premier) et g (générateur). '
            'Alice choisit a secret, envoie A = gᵃ mod p. Bob choisit b secret, envoie B = gᵇ mod p. '
            'Secret partagé : Alice calcule Bᵃ = gᵃᵇ mod p, Bob calcule Aᵇ = gᵃᵇ mod p. '
            'Un espion voit g, p, A, B mais ne peut pas retrouver a ou b (problème du logarithme discret). '
            'ECDH (Diffie-Hellman sur courbes elliptiques) remplace gᵃ par a·P sur la courbe, '
            'offrant la même sécurité avec des clés 10× plus courtes. '
            'TLS 1.3 utilise exclusivement ECDHE (Ephemeral) pour la propriété de Perfect Forward Secrecy.',
        visual: () => SimFlowDiagram(
          color: const Color(0xFFBA68C8),
          nodes: const [
            SimFlowNode('Alice', Icons.person),
            SimFlowNode('g^a mod p', Icons.key),
            SimFlowNode('Bob', Icons.person),
            SimFlowNode('g^b mod p', Icons.key),
            SimFlowNode('Alice', Icons.person),
            SimFlowNode('shared: g^ab mod p', Icons.lock),
          ],
        ),
      ),
    ],
  ),

  // ── 5. Systèmes Distribués ───────────────────────────────────
  _Scenario(
    name: 'Systèmes Distribués',
    subtitle: 'CAP · Paxos · Hashing · Bloom · MapReduce',
    icon: Icons.hub,
    color: Colors.cyan,
    steps: [
      const _Step(
        title: 'Théorème CAP',
        protocol: 'Consistency/Availability/Partition',
        icon: Icons.device_hub,
        color: Color(0xFF00BCD4),
        description: 'Un système distribué ne peut garantir simultanément que deux des trois propriétés CAP.',
        detail:
            'Le théorème CAP (Brewer, 2000, prouvé par Gilbert & Lynch, 2002) stipule : '
            'Consistency (tous les nœuds voient la même donnée), '
            'Availability (toute requête reçoit une réponse), '
            'Partition tolerance (le système fonctionne malgré la perte de messages réseau). '
            'En pratique, les partitions réseau arrivent toujours dans les systèmes réels, '
            'donc le vrai choix est CP (PostgreSQL, HBase) vs AP (Cassandra, DynamoDB, CouchDB). '
            'Le modèle PACELC raffine CAP en considérant aussi la latence (Latency vs Consistency '
            'en l\'absence de partition).',
      ),
      const _Step(
        title: 'Consensus Paxos/Raft',
        protocol: 'Algorithmes de consensus',
        icon: Icons.how_to_vote,
        color: Color(0xFF0097A7),
        description: 'Faire s\'accorder un groupe de nœuds sur une valeur malgré les pannes.',
        detail:
            'Paxos (Lamport, 1989) fonctionne en deux phases : Prepare/Promise puis Accept/Accepted. '
            'Un proposer envoie Prepare(n) ; les acceptors promettent de ne plus accepter '
            'de valeur avec numéro < n. Ensuite le proposer envoie Accept(n, v) ; '
            'si une majorité accepte, la valeur v est choisie. '
            'Raft (2013) est conçu pour être plus compréhensible : leader election explicite, '
            'log replication strict, et term numbers. Un leader est élu par vote majoritaire, '
            'puis répercute toutes les entrées de log vers les followers. '
            'Utilisé dans etcd (Kubernetes), CockroachDB, Consul.',
      ),
      const _Step(
        title: 'Consistent hashing',
        protocol: 'Distribution de charge',
        icon: Icons.donut_large,
        color: Color(0xFF00838F),
        description: 'Distribuer les données sur des nœuds avec un minimum de remapping lors des changements.',
        detail:
            'Le consistent hashing place nœuds et clés sur un anneau (ring) de 0 à 2³²-1. '
            'Chaque clé est assignée au premier nœud dans le sens horaire (successor). '
            'Ajout/suppression d\'un nœud : seulement K/n clés sont remappées (K clés, n nœuds), '
            'contre K·(1/n_old - 1/n_new) avec un hachage modulaire classique. '
            'Les vnodes (virtual nodes) améliorent l\'équilibre de charge en donnant à chaque '
            'nœud physique plusieurs positions sur l\'anneau. '
            'Utilisé dans Amazon DynamoDB, Apache Cassandra, Memcached (ketama), Chord DHT.',
      ),
      const _Step(
        title: 'Bloom filters',
        protocol: 'Probabilistic membership',
        icon: Icons.filter_alt,
        color: Color(0xFF006064),
        description: 'Tester l\'appartenance d\'un élément à un ensemble avec zéro faux négatif et peu de faux positifs.',
        detail:
            'Un Bloom filter est un tableau de m bits initialisé à 0, et k fonctions de hachage. '
            'Insertion : mettre à 1 les k positions h₁(x), h₂(x), ..., hₖ(x). '
            'Requête : si tous les k bits sont à 1 → probablement présent (faux positif possible) ; '
            'si au moins un est 0 → absent avec certitude. '
            'Taux de faux positifs ≈ (1 - e^(-kn/m))^k, minimisé quand k = (m/n)·ln(2). '
            'Avantage : O(k) temps constant, O(m) espace sans stocker les éléments, '
            'idéal pour éviter des accès disque inutiles. '
            'Utilisé dans Google Bigtable, Cassandra (réduire les lookups de SSTable), '
            'Chrome (liste noire d\'URL malveillantes).',
      ),
      const _Step(
        title: 'MapReduce',
        protocol: 'Traitement distribué',
        icon: Icons.transform,
        color: Color(0xFF4DD0E1),
        description: 'Paralléliser le traitement de grandes quantités de données sur un cluster.',
        detail:
            'MapReduce (Google, 2004) décompose le traitement en deux phases : '
            'Map : chaque worker lit une partition de données et émet des paires (key, value). '
            'Shuffle & Sort : les paires sont regroupées par clé et triées. '
            'Reduce : chaque reducer agrège toutes les valeurs d\'une même clé. '
            'Le framework gère automatiquement la tolérance aux pannes (re-exécution des tasks échouées), '
            'la localité des données (envoyer le calcul vers les données plutôt que l\'inverse), '
            'et l\'équilibrage de charge. '
            'Apache Spark remplace largement Hadoop MapReduce en gardant les données en mémoire '
            '(RDD/DataFrame) pour des pipelines 100× plus rapides.',
      ),
      const _Step(
        title: 'Gossip protocol',
        protocol: 'Épidémique · Propagation',
        icon: Icons.cell_tower,
        color: Color(0xFF80DEEA),
        description: 'Propager des informations dans un cluster sans coordinateur central.',
        detail:
            'Un gossip protocol fonctionne comme une épidémie : à chaque round, chaque nœud '
            'choisit aléatoirement k voisins et leur envoie ses informations (état, messages). '
            'Convergence : après O(log n) rounds, tous les nœuds ont l\'information. '
            'Tolérance aux pannes naturelle : aucun point de défaillance unique, '
            'la redondance garantit la propagation même si des nœuds tombent. '
            'Applications : détection de pannes (failure detection — chaque nœud maintient '
            'une liste de voisins vivants), synchronisation d\'état (Amazon S3 metadata, '
            'Cassandra ring membership via SWIM protocol), compteurs distribués (CRDT). '
            'L\'entropie anti-entropy compare les Merkle trees de deux nœuds pour identifier '
            'les divergences de données à synchroniser.',
      ),
    ],
  ),

  // ── 6. Automates & Compilateurs ─────────────────────────────
  _Scenario(
    name: 'Automates & Compilateurs',
    subtitle: 'DFA · Regex · CFG · Lexer · Parser · AST',
    icon: Icons.code,
    color: Colors.red,
    steps: [
      _Step(
        title: 'Automate fini déterministe (DFA)',
        protocol: 'Théorie des automates',
        icon: Icons.settings_input_component,
        color: const Color(0xFFF44336),
        description: 'Machine à états reconnaissant des langages réguliers.',
        detail:
            'Un DFA (Deterministic Finite Automaton) est un quintuplet (Q, Σ, δ, q₀, F) : '
            'Q = ensemble fini d\'états, Σ = alphabet, δ : Q×Σ → Q = fonction de transition, '
            'q₀ = état initial, F ⊆ Q = états acceptants. '
            'Pour chaque (état, symbole), il existe exactement une transition (déterministe). '
            'Le DFA accepte un mot w si δ*(q₀, w) ∈ F. '
            'Un NFA (Non-déterministe) a plusieurs transitions possibles par (état, symbole) — '
            'il reconnaît les mêmes langages qu\'un DFA (construction de sous-ensembles), '
            'mais peut être exponentiellement plus compact. '
            'Les langages reconnus par les DFA/NFA sont exactement les langages réguliers.',
        visual: () => SimFlowDiagram(
          color: const Color(0xFFF44336),
          nodes: const [
            SimFlowNode('q0', Icons.circle),
            SimFlowNode('(a)', Icons.label),
            SimFlowNode('q1', Icons.circle),
            SimFlowNode('(b)', Icons.label),
            SimFlowNode('q2', Icons.circle),
            SimFlowNode('accept', Icons.check_circle),
          ],
        ),
      ),
      const _Step(
        title: 'Expressions régulières',
        protocol: 'Regex & langages réguliers',
        icon: Icons.text_fields,
        color: Color(0xFFE53935),
        description: 'Notation compacte pour décrire des patterns dans des chaînes de caractères.',
        detail:
            'Une expression régulière est construite récursivement : '
            'ε (mot vide), a (symbole), R|S (union), RS (concaténation), R* (étoile de Kleene). '
            'Théorème de Kleene : les langages décrits par les regex = langages réguliers = DFA/NFA. '
            'En pratique, les moteurs de regex modernes (PCRE) ajoutent des extensions '
            '(lookahead, backreferences) qui sortent du cadre des langages réguliers '
            '(les backreferences peuvent rendre le matching NP-complet). '
            'Implémentation efficace : conversion regex → NFA (Thompson) → DFA (subset construction) '
            '→ minimisation de DFA → simulation en O(|w|) (moteur Thompson/RE2).',
      ),
      const _Step(
        title: 'Grammaire CFG & BNF',
        protocol: 'Langages hors-contexte',
        icon: Icons.account_tree,
        color: Color(0xFFD32F2F),
        description: 'Décrire la syntaxe d\'un langage de programmation avec des règles de production.',
        detail:
            'Une grammaire hors-contexte (CFG) est un quadruplet (V, Σ, R, S) : '
            'V = non-terminaux, Σ = terminaux, R = règles de production A → α, S = axiome. '
            'BNF (Backus-Naur Form) est la notation standard : <expr> ::= <expr> "+" <term> | <term>. '
            'La hiérarchie de Chomsky : régulier ⊂ hors-contexte ⊂ contexte-sensible ⊂ récursivement énumérable. '
            'Toutes les langages de programmation courants sont définis par des CFG. '
            'Ambiguïté : une grammaire est ambiguë si un mot a plusieurs arbres de dérivation — '
            'problème indécidable en général, mais résolu en pratique par la priorité des opérateurs.',
      ),
      const _Step(
        title: 'Analyse lexicale (tokenizer)',
        protocol: 'Lexer · Scanner',
        icon: Icons.format_list_bulleted,
        color: Color(0xFFB71C1C),
        description: 'Transformer un flux de caractères en séquence de tokens (unités lexicales).',
        detail:
            'Le lexer (ou scanner) est la première phase du compilateur. '
            'Il lit le code source caractère par caractère et regroupe les caractères '
            'en tokens : mots-clés (if, while), identifiants, littéraux (42, "hello"), '
            'opérateurs (+, ==), délimiteurs ({, ;). '
            'Chaque pattern de token est défini par une regex, compilée en un DFA. '
            'Les DFAs de tous les tokens sont fusionnés en un seul grand DFA (ou NFA simulé). '
            'Les espaces, commentaires et sauts de ligne sont généralement ignorés (whitespace skipping). '
            'Outils : Flex (C), JFlex (Java), ANTLR (multilangage).',
      ),
      const _Step(
        title: 'Parsing LL/LR',
        protocol: 'Analyse syntaxique',
        icon: Icons.account_balance_wallet,
        color: Color(0xFFEF5350),
        description: 'Construire l\'arbre syntaxique (parse tree) à partir du flux de tokens.',
        detail:
            'Le parser vérifie que la séquence de tokens respecte la grammaire et construit '
            'un arbre de dérivation (concrete syntax tree). '
            'LL(k) (Left-to-right, Leftmost derivation, k tokens lookahead) : parseur descendant récursif. '
            'Chaque non-terminal est une fonction qui choisit la règle à appliquer en regardant '
            'les k prochains tokens. Simple à écrire à la main (parseurs récursifs-descendants). '
            'LR(k) (Left-to-right, Rightmost derivation) : parseur ascendant par table d\'action. '
            'Plus puissant qu\'LL — reconnaît plus de grammaires. '
            'LALR(1) (sous-classe de LR) est utilisé par yacc/Bison. '
            'GLR (Generalized LR) gère les grammaires ambiguës (langages naturels, C++).',
      ),
      const _Step(
        title: 'AST & génération de code',
        protocol: 'AST · IR · CodeGen',
        icon: Icons.construction,
        color: Color(0xFFEF9A9A),
        description: 'Transformer l\'arbre syntaxique en représentation intermédiaire puis en code machine.',
        detail:
            'L\'AST (Abstract Syntax Tree) simplifie le parse tree en supprimant les détails '
            'syntaxiques non sémantiques (parenthèses, points-virgules) — '
            'chaque nœud représente une construction sémantique (BinaryOp, FunctionCall, IfStatement). '
            'Le compilateur effectue ensuite plusieurs passes sur l\'AST : '
            'analyse sémantique (résolution des types, vérification des portées), '
            'transformations et optimisations (constant folding, dead code elimination, inlining), '
            'génération de code intermédiaire (SSA form, LLVM IR, bytecode JVM). '
            'La génération de code final traduit l\'IR en instructions machine (x86-64, ARM64) '
            'en allouant les registres (register allocation) et en sélectionnant les instructions.',
      ),
    ],
  ),
];

// ─── Widget principal ────────────────────────────────────────

enum _StepState { future, active, done }

class AlgorithmsSimulator extends StatefulWidget {
  const AlgorithmsSimulator({super.key});

  @override
  State<AlgorithmsSimulator> createState() => _AlgorithmsSimulatorState();
}

class _AlgorithmsSimulatorState extends State<AlgorithmsSimulator> {
  int _scenarioIndex = 0;
  int _currentStep = -1;
  bool _running = false;
  Timer? _timer;
  final ScrollController _scrollCtrl = ScrollController();

  // ── Sorting visualizer ────────────────────────────────────
  List<int> _sortArr = [64, 34, 25, 12, 22, 11, 90, 45];
  int _sortI = -1;
  int _sortJ = -1;
  bool _sorting = false;

  // ── Graph BFS/DFS ─────────────────────────────────────────
  final Map<String, List<String>> _graph = {
    'A': ['B', 'C'],
    'B': ['A', 'D', 'E'],
    'C': ['A', 'F'],
    'D': ['B'],
    'E': ['B', 'F'],
    'F': ['C', 'E'],
  };
  List<String> _visited = [];
  List<String> _queue = [];
  bool _graphRunning = false;
  String _graphMode = 'BFS';

  // ── DP Fibonacci ──────────────────────────────────────────
  List<int?> _dpTable = List.filled(10, null);
  int _dpStep = -1;
  bool _dpRunning = false;

  // ── Crypto simulator ──────────────────────────────────────
  final TextEditingController _cryptoCtrl = TextEditingController(text: 'hello');
  String _cryptoResult = '';
  String _cryptoMode = 'XOR';

  // ── Distributed ──────────────────────────────────────────
  int _raftLeader = -1;
  List<int> _raftVotes = [0, 0, 0, 0, 0];
  bool _raftElecting = false;

  _Scenario get _scenario => _algoScenarios[_scenarioIndex];

  @override
  void dispose() {
    _timer?.cancel();
    _scrollCtrl.dispose();
    _cryptoCtrl.dispose();
    super.dispose();
  }

  void _selectScenario(int index) {
    _timer?.cancel();
    setState(() {
      _scenarioIndex = index;
      _currentStep = -1;
      _running = false;
      _sorting = false;
      _sortI = -1; _sortJ = -1;
      _sortArr = [64, 34, 25, 12, 22, 11, 90, 45];
      _visited = [];
      _queue = [];
      _graphRunning = false;
      _dpTable = List.filled(10, null);
      _dpStep = -1;
      _dpRunning = false;
      _cryptoResult = '';
      _raftLeader = -1;
      _raftVotes = [0, 0, 0, 0, 0];
      _raftElecting = false;
    });
  }

  // ── Bubble sort ───────────────────────────────────────────

  Future<void> _startSort() async {
    if (_sorting) return;
    setState(() { _sorting = true; _sortArr = [64, 34, 25, 12, 22, 11, 90, 45]; });
    final arr = List<int>.from(_sortArr);
    for (int i = 0; i < arr.length - 1; i++) {
      for (int j = 0; j < arr.length - i - 1; j++) {
        if (!mounted) return;
        setState(() { _sortI = i; _sortJ = j; });
        await Future.delayed(const Duration(milliseconds: 350));
        if (arr[j] > arr[j + 1]) {
          final tmp = arr[j]; arr[j] = arr[j + 1]; arr[j + 1] = tmp;
          setState(() => _sortArr = List.from(arr));
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    }
    if (mounted) setState(() { _sorting = false; _sortI = -1; _sortJ = -1; });
  }

  void _resetSort() => setState(() {
    _sortArr = [64, 34, 25, 12, 22, 11, 90, 45];
    _sorting = false; _sortI = -1; _sortJ = -1;
  });

  // ── BFS/DFS ───────────────────────────────────────────────

  Future<void> _startGraph() async {
    if (_graphRunning) return;
    setState(() { _graphRunning = true; _visited = []; _queue = []; });
    if (_graphMode == 'BFS') {
      final q = ['A'];
      final visited = <String>{};
      while (q.isNotEmpty) {
        if (!mounted) return;
        final node = q.removeAt(0);
        if (visited.contains(node)) continue;
        visited.add(node);
        setState(() { _visited = List.from(visited); _queue = List.from(q); });
        await Future.delayed(const Duration(milliseconds: 700));
        for (final neighbor in (_graph[node] ?? [])) {
          if (!visited.contains(neighbor)) q.add(neighbor);
        }
      }
    } else {
      // DFS iterative
      final stack = ['A'];
      final visited = <String>{};
      while (stack.isNotEmpty) {
        if (!mounted) return;
        final node = stack.removeLast();
        if (visited.contains(node)) continue;
        visited.add(node);
        setState(() { _visited = List.from(visited); _queue = List.from(stack); });
        await Future.delayed(const Duration(milliseconds: 700));
        for (final neighbor in (_graph[node] ?? []).reversed) {
          if (!visited.contains(neighbor)) stack.add(neighbor);
        }
      }
    }
    if (mounted) setState(() => _graphRunning = false);
  }

  void _resetGraph() => setState(() { _visited = []; _queue = []; _graphRunning = false; });

  // ── DP Fibonacci ──────────────────────────────────────────

  Future<void> _startDp() async {
    if (_dpRunning) return;
    setState(() { _dpRunning = true; _dpTable = List.filled(10, null); _dpStep = 0; });
    final table = List<int?>.filled(10, null);
    table[0] = 0; table[1] = 1;
    setState(() { _dpTable = List.from(table); _dpStep = 1; });
    await Future.delayed(const Duration(milliseconds: 500));
    for (int i = 2; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      table[i] = table[i - 1]! + table[i - 2]!;
      setState(() { _dpTable = List.from(table); _dpStep = i; });
    }
    if (mounted) setState(() => _dpRunning = false);
  }

  void _resetDp() => setState(() { _dpTable = List.filled(10, null); _dpStep = -1; _dpRunning = false; });

  // ── Crypto ────────────────────────────────────────────────

  void _runCrypto() {
    final input = _cryptoCtrl.text;
    String result;
    if (_cryptoMode == 'XOR') {
      final key = 0x42;
      final bytes = input.codeUnits.map((b) => (b ^ key).toRadixString(16).padLeft(2, '0')).join(' ');
      result = 'XOR(0x42): $bytes';
    } else if (_cryptoMode == 'ROT13') {
      result = 'ROT13: ${input.splitMapJoin('', onNonMatch: (c) {
        if (c.isEmpty) return '';
        final code = c.codeUnitAt(0);
        if (code >= 65 && code <= 90) return String.fromCharCode(((code - 65 + 13) % 26) + 65);
        if (code >= 97 && code <= 122) return String.fromCharCode(((code - 97 + 13) % 26) + 97);
        return c;
      })}';
    } else {
      // Base64-like
      final bytes = input.codeUnits;
      final b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
      final sb = StringBuffer();
      for (int i = 0; i < bytes.length; i += 3) {
        final b0 = bytes[i];
        final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
        final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
        sb.write(b64chars[(b0 >> 2) & 63]);
        sb.write(b64chars[((b0 << 4) | (b1 >> 4)) & 63]);
        sb.write(i + 1 < bytes.length ? b64chars[((b1 << 2) | (b2 >> 6)) & 63] : '=');
        sb.write(i + 2 < bytes.length ? b64chars[b2 & 63] : '=');
      }
      result = 'Base64: $sb';
    }
    setState(() => _cryptoResult = result);
  }

  // ── Raft election ─────────────────────────────────────────

  Future<void> _startRaft() async {
    if (_raftElecting) return;
    setState(() { _raftElecting = true; _raftLeader = -1; _raftVotes = [0, 0, 0, 0, 0]; });
    final candidate = 0;
    for (int node = 1; node < 5; node++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        final v = List<int>.from(_raftVotes);
        v[candidate]++;
        _raftVotes = v;
      });
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() { _raftLeader = candidate; _raftElecting = false; });
  }

  void _resetRaft() => setState(() { _raftLeader = -1; _raftVotes = [0, 0, 0, 0, 0]; _raftElecting = false; });

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
          topic: 'Algorithmes — ${_scenario.name}',
          accentColor: _scenario.color,
          systemPrompt:
              'Tu es un expert en algorithmique et structures de données. Réponds en français, de façon pédagogique. '
              'Contexte actuel : ${_scenario.name}. '
              'Domaines couverts : complexité Big-O, algorithmes de tri, graphes (BFS/DFS/Dijkstra), '
              'programmation dynamique, cryptographie algorithmique, systèmes distribués, automates.',
          suggestedQuestions: const [
            'Expliquer la complexité O(n log n)',
            'Différence BFS vs DFS ?',
            'C\'est quoi la mémoïsation ?',
            'Pourquoi Quick Sort est-il rapide ?',
            'Qu\'est-ce qu\'un graphe orienté ?',
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
                  'Contenu local. Exemples illustratifs (pas d\'exécution réelle).',
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
            heroTag: 'algo_ai_fab',
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
      case 0: return _buildSortPanel();
      case 1: return _buildGraphPanel();
      case 2: return _buildDpPanel();
      case 3: return _buildCryptoPanel();
      case 4: return _buildRaftPanel();
      case 5: return _buildCompilerPanel();
      default: return const SizedBox.shrink();
    }
  }

  Widget _algoShell({required Color color, required String title, required Widget child}) {
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
                  Icon(Icons.play_circle_filled, color: color, size: 13),
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

  Widget _aBtn(String label, Color color, VoidCallback? onTap) {
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

  // 0 – Bubble sort visualizer ──────────────────────────────
  Widget _buildSortPanel() {
    final maxVal = _sortArr.reduce((a, b) => a > b ? a : b);
    return _algoShell(
      color: Colors.blue,
      title: 'BUBBLE SORT VISUALIZER',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _aBtn(_sorting ? 'Tri en cours…' : 'Lancer tri', Colors.blue, _sorting ? null : _startSort),
              const SizedBox(width: 8),
              _aBtn('Reset', Colors.grey, _sorting ? null : _resetSort),
              if (_sorting) ...[
                const SizedBox(width: 8),
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
              ],
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_sortArr.length, (i) {
                  final h = (_sortArr[i] / maxVal * 70).clamp(8.0, 70.0);
                  final isComparing = i == _sortJ || i == _sortJ + 1;
                  final color = isComparing ? const Color(0xFFF59E0B) : Colors.blue;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${_sortArr[i]}', style: TextStyle(color: color, fontSize: 9, fontFamily: 'monospace')),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: h,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (_sortI >= 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Passe ${ _sortI + 1 } — comparaison index $_sortJ vs ${_sortJ + 1}',
                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
              ),
          ],
        ),
      ),
    );
  }

  // 1 – Graph BFS/DFS ────────────────────────────────────────
  Widget _buildGraphPanel() {
    return _algoShell(
      color: const Color(0xFF8B5CF6),
      title: 'GRAPH TRAVERSAL — BFS / DFS',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _aBtn('BFS', const Color(0xFF06B6D4), _graphRunning ? null : () { setState(() => _graphMode = 'BFS'); _resetGraph(); }),
              const SizedBox(width: 6),
              _aBtn('DFS', const Color(0xFF8B5CF6), _graphRunning ? null : () { setState(() => _graphMode = 'DFS'); _resetGraph(); }),
              const SizedBox(width: 10),
              _aBtn('Go', const Color(0xFF10B981), _graphRunning ? null : _startGraph),
              const SizedBox(width: 6),
              _aBtn('Reset', Colors.grey, _resetGraph),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(_graphMode, style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _graph.keys.map((node) {
                final isVisited = _visited.contains(node);
                final isInQueue = _queue.contains(node);
                final color = isVisited ? const Color(0xFF10B981) : isInQueue ? const Color(0xFFF59E0B) : Colors.white38;
                return Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.15),
                    border: Border.all(color: color, width: isVisited ? 2 : 1),
                  ),
                  child: Center(child: Text(node, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace'))),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            if (_visited.isNotEmpty)
              Text(
                'Ordre visite : ${_visited.join(' → ')}',
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontFamily: 'monospace'),
              ),
            if (_queue.isNotEmpty)
              Text(
                '${_graphMode == 'BFS' ? 'File' : 'Pile'} : [${_queue.join(', ')}]',
                style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontFamily: 'monospace'),
              ),
          ],
        ),
      ),
    );
  }

  // 2 – DP Fibonacci table ───────────────────────────────────
  Widget _buildDpPanel() {
    return _algoShell(
      color: const Color(0xFF10B981),
      title: 'PROGRAMMATION DYNAMIQUE — Fibonacci',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _aBtn('Calculer', const Color(0xFF10B981), _dpRunning ? null : _startDp),
              const SizedBox(width: 8),
              _aBtn('Reset', Colors.grey, _resetDp),
              if (_dpRunning) ...[
                const SizedBox(width: 8),
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981))),
              ],
            ]),
            const SizedBox(height: 10),
            Text('fib(n) = fib(n-1) + fib(n-2),  fib(0)=0, fib(1)=1',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Row(
              children: List.generate(10, (i) {
                final val = _dpTable[i];
                final isActive = i == _dpStep;
                final color = val != null ? const Color(0xFF10B981) : Colors.white24;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF10B981).withOpacity(0.2) : val != null ? const Color(0xFF10B981).withOpacity(0.08) : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isActive ? const Color(0xFF10B981) : color.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text('n=$i', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8, fontFamily: 'monospace')),
                        Text(val != null ? '$val' : '?', style: TextStyle(color: color, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }),
            ),
            if (_dpStep == 9)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Toutes les valeurs en cache — O(n) temps, O(n) espace',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontFamily: 'monospace')),
              ),
          ],
        ),
      ),
    );
  }

  // 3 – Crypto ──────────────────────────────────────────────
  Widget _buildCryptoPanel() {
    return _algoShell(
      color: const Color(0xFFEF4444),
      title: 'CRYPTO ENCODER',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _aBtn('XOR', const Color(0xFFF59E0B), () => setState(() { _cryptoMode = 'XOR'; _cryptoResult = ''; })),
              const SizedBox(width: 6),
              _aBtn('ROT13', const Color(0xFF8B5CF6), () => setState(() { _cryptoMode = 'ROT13'; _cryptoResult = ''; })),
              const SizedBox(width: 6),
              _aBtn('Base64', const Color(0xFF06B6D4), () => setState(() { _cryptoMode = 'Base64'; _cryptoResult = ''; })),
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cryptoCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'Texte à encoder…',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                    ),
                    onSubmitted: (_) => _runCrypto(),
                  ),
                ),
                const SizedBox(width: 8),
                _aBtn('Encode', const Color(0xFFEF4444), _runCrypto),
              ],
            ),
            if (_cryptoResult.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: SelectableText(_cryptoResult, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontFamily: 'monospace')),
              ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }

  // 4 – Raft election ───────────────────────────────────────
  Widget _buildRaftPanel() {
    return _algoShell(
      color: const Color(0xFF06B6D4),
      title: 'RAFT CONSENSUS — LEADER ELECTION',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _aBtn('Élection', const Color(0xFF06B6D4), _raftElecting ? null : _startRaft),
              const SizedBox(width: 8),
              _aBtn('Reset', Colors.grey, _resetRaft),
              if (_raftLeader >= 0) ...[
                const SizedBox(width: 8),
                Icon(Icons.how_to_vote, color: const Color(0xFF10B981), size: 14),
                const SizedBox(width: 4),
                Text('Node 0 est LEADER', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              ],
            ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final isLeader = _raftLeader == i;
                final isCandidate = i == 0 && _raftElecting;
                final votes = _raftVotes[i];
                final color = isLeader ? const Color(0xFF10B981) : isCandidate ? const Color(0xFFF59E0B) : Colors.white38;
                return Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.15),
                        border: Border.all(color: color, width: isLeader ? 2.5 : 1.5),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isLeader ? Icons.star : Icons.computer, color: color, size: 14),
                            if (votes > 0) Text('$votes', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('N$i', style: TextStyle(color: color, fontSize: 9, fontFamily: 'monospace')),
                    Text(isLeader ? 'LEADER' : isCandidate ? 'CAND.' : 'FOLLOWER',
                        style: TextStyle(color: color, fontSize: 7, fontFamily: 'monospace')),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // 5 – Compiler pipeline ───────────────────────────────────
  Widget _buildCompilerPanel() {
    final stages = <_AP4>[
      _AP4('Lexer', 'int x = 5 + 3;', 'TOKENS: INT ID EQ NUM PLUS NUM SEMI', const Color(0xFF6366F1)),
      _AP4('Parser', 'Tokens → AST', 'Assign(x, BinOp(+, 5, 3))', const Color(0xFF8B5CF6)),
      _AP4('Semantic', 'Analyse types', 'x: int, expr: int ✓', const Color(0xFF06B6D4)),
      _AP4('Optimizer', 'Constant folding', 'Assign(x, 8)  ← 5+3 = 8', const Color(0xFF10B981)),
      _AP4('Codegen', 'IR → Assembly', 'mov eax, 8 / mov [x], eax', const Color(0xFFF59E0B)),
    ];
    return _algoShell(
      color: const Color(0xFF6366F1),
      title: 'COMPILATEUR — PIPELINE',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: List<Widget>.generate(stages.length, (si) {
            final s = stages[si];
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: s.d.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border(left: BorderSide(color: s.d, width: 3)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 64, child: Text(s.a, style: TextStyle(color: s.d, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
                  const Icon(Icons.arrow_forward, size: 10, color: Colors.white24),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.b, style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'monospace')),
                        Text(s.c, style: const TextStyle(color: Colors.white38, fontSize: 9, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: si * 100)).slideX(begin: 0.05, end: 0);
          }),
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
        itemCount: _algoScenarios.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final s = _algoScenarios[i];
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
                    style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12),
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
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                _buildStepDetail(step)
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
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: step.color,
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

  Widget _buildStepDetail(_Step step) {
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
            child: _AlgoRetainButton(
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
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_running ? 'Simulation en cours…' : 'Lancer la simulation'),
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

// ─── Helper data classes ─────────────────────────────────────

class _AP4 {
  final String a, b, c;
  final Color d;
  const _AP4(this.a, this.b, this.c, this.d);
}

// ─── Bouton "Retenir dans la Cheat Sheet" ────────────────────

class _AlgoRetainButton extends StatefulWidget {
  final String title, detail, category;
  const _AlgoRetainButton({required this.title, required this.detail, required this.category});
  @override State<_AlgoRetainButton> createState() => _AlgoRetainButtonState();
}

class _AlgoRetainButtonState extends State<_AlgoRetainButton> {
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
