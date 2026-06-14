// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/lab/services/crypto_engine.dart';
import 'package:tutodecode/features/lab/widgets/lab_widgets.dart';
import 'package:tutodecode/features/lab/widgets/simulator_ai_assistant.dart';

class CryptographySimulator extends StatefulWidget {
  const CryptographySimulator({super.key});

  @override
  State<CryptographySimulator> createState() => _CryptographySimulatorState();
}

class _CryptographySimulatorState extends State<CryptographySimulator>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _plainTextController = TextEditingController();
  final TextEditingController _cipherTextController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _hashInputController = TextEditingController();
  final TextEditingController _signInputController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();

  bool _isEncrypting = false;
  bool _isDecrypting = false;
  bool _isHashing = false;
  bool _isSigning = false;
  bool _isVerifying = false;

  String _hashResult = '';
  String _signatureResult = '';
  bool? _verificationResult;

  String _selectedCipher = 'AES-GCM';
  String _selectedHash = 'SHA-256';
  String _selectedSignature = 'Ed25519';

  AesGcmResult? _lastEncryptResult;
  Ed25519KeyPairData? _signKeyPair;
  String _lastSignedMessage = '';

  // Pédagogie : étapes visibles
  final List<String> _encryptSteps = [];
  final List<String> _hashSteps = [];
  final List<String> _signSteps = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeKeys();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _plainTextController.dispose();
    _cipherTextController.dispose();
    _keyController.dispose();
    _hashInputController.dispose();
    _signInputController.dispose();
    _privateKeyController.dispose();
    _publicKeyController.dispose();
    super.dispose();
  }

  void _initializeKeys() {
    _keyController.text = 'MonMotDePasse2025!';
    CryptoEngine.generateEd25519KeyPair().then((kp) {
      if (!mounted) return;
      setState(() {
        _signKeyPair = kp;
        _privateKeyController.text = kp.privateKey;
        _publicKeyController.text = kp.publicKey;
      });
    });
  }

  // --- Info helpers ---

  bool get _isRealCrypto => _selectedCipher == 'AES-GCM' || _selectedCipher == 'ChaCha20';

  String get _securityLevel {
    switch (_selectedCipher) {
      case 'AES-GCM': return '256 bits';
      case 'ChaCha20': return '256 bits';
      case 'Caesar': return 'Aucune';
      case 'Vigenere': return 'Faible';
      case 'XOR': return 'Aucune';
      default: return '-';
    }
  }

  String get _cipherFamily {
    switch (_selectedCipher) {
      case 'AES-GCM': return 'Symétrique';
      case 'ChaCha20': return 'Symétrique';
      case 'Caesar': return 'Substitution';
      case 'Vigenere': return 'Substitution';
      case 'XOR': return 'Flux';
      default: return '-';
    }
  }

  double get _keyEntropy {
    final key = _keyController.text;
    if (key.isEmpty) return 0;
    final charSet = <int>{};
    for (final c in key.codeUnits) {
      charSet.add(c);
    }
    if (charSet.isEmpty) return 0;
    final freq = <int, int>{};
    for (final c in key.codeUnits) {
      freq[c] = (freq[c] ?? 0) + 1;
    }
    double entropy = 0;
    for (final count in freq.values) {
      final p = count / key.length;
      if (p > 0) entropy -= p * (log(p) / log(2));
    }
    return entropy * key.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Container(
          color: TdcColors.surfaceAlt.withValues(alpha: 0.3),
          child: TabBar(
            controller: _tabController,
            indicatorColor: TdcColors.crypto,
            labelColor: TdcColors.crypto,
            unselectedLabelColor: TdcColors.textMuted,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.lock, size: 16), text: 'Chiffrement'),
              Tab(icon: Icon(Icons.fingerprint, size: 16), text: 'Hashage'),
              Tab(icon: Icon(Icons.draw, size: 16), text: 'Signature'),
              Tab(icon: Icon(Icons.school, size: 16), text: 'IA'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEncryptionTab(),
              _buildHashTab(),
              _buildSignatureTab(),
              const SimulatorAIAssistant(
                topic: 'Cryptographie',
                accentColor: TdcColors.crypto,
                systemPrompt:
                    'Tu es un expert en cryptographie. Réponds en français, de façon pédagogique. '
                    'Couvre : AES-GCM, ChaCha20, Ed25519, X25519, PBKDF2, César, Vigenère, '
                    'fonctions de hachage, signatures, PKI, TLS.',
                suggestedQuestions: [
                  'Pourquoi AES-GCM et pas AES-CBC ?',
                  'Comment fonctionne Diffie-Hellman ?',
                  'Qu\'est-ce qu\'un nonce ?',
                  'Pourquoi MD5 est-il cassé ?',
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return LabGlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.lock, color: TdcColors.crypto, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'CRYPTOGRAPHIE',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _buildBadge(
                _isRealCrypto ? 'RÉEL' : 'ÉDUCATIF',
                _isRealCrypto ? TdcColors.system : TdcColors.crypto,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMetric('Algorithme', _selectedCipher, Icons.settings_suggest, TdcColors.crypto),
                const SizedBox(width: 12),
                _buildMetric('Sécurité', _securityLevel, Icons.shield,
                    _isRealCrypto ? TdcColors.system : TdcColors.security),
                const SizedBox(width: 12),
                _buildMetric('Type', _cipherFamily, Icons.category, TdcColors.textSecondary),
                const SizedBox(width: 12),
                _buildMetric(
                  'Entropie clé',
                  '${_keyEntropy.toStringAsFixed(1)} bits',
                  Icons.analytics,
                  _keyEntropy > 40 ? TdcColors.system : (_keyEntropy > 20 ? TdcColors.crypto : TdcColors.security),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetric(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 130,
      child: LabMetricCard(title: title, value: value, icon: icon, color: color),
    );
  }

  // ── Chiffrement Tab ──────────────────────────────────────

  Widget _buildEncryptionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildExplainer(
          _cipherExplanation,
          color: TdcColors.crypto,
        ),
        const SizedBox(height: 12),

        // Algorithme
        _buildSection('Algorithme', Icons.settings_suggest, [
          DropdownButton<String>(
            value: _selectedCipher,
            isExpanded: true,
            dropdownColor: TdcColors.surface,
            items: const [
              DropdownMenuItem(value: 'AES-GCM', child: Text('AES-256-GCM — chiffrement authentifié moderne')),
              DropdownMenuItem(value: 'ChaCha20', child: Text('ChaCha20-Poly1305 — alternative mobile/IoT')),
              DropdownMenuItem(value: 'Caesar', child: Text('César — substitution mono-alphabétique')),
              DropdownMenuItem(value: 'Vigenere', child: Text('Vigenère — substitution poly-alphabétique')),
              DropdownMenuItem(value: 'XOR', child: Text('XOR — opération bit à bit (démonstration)')),
            ],
            onChanged: (v) => setState(() {
              _selectedCipher = v!;
              _encryptSteps.clear();
              _cipherTextController.clear();
              _lastEncryptResult = null;
            }),
          ),
        ]),
        const SizedBox(height: 12),

        // Texte clair
        _buildSection('Texte clair', Icons.text_fields, [
          TextField(
            controller: _plainTextController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Entrez votre message ici...',
              hintStyle: TextStyle(color: TdcColors.textMuted),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Clé
        _buildSection('Clé / Passphrase', Icons.vpn_key, [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keyController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: _isRealCrypto
                        ? 'Passphrase (dérivée via PBKDF2 en clé 256 bits)'
                        : 'Clé de chiffrement',
                    hintStyle: const TextStyle(color: TdcColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _generateKey,
                icon: const Icon(Icons.casino, color: TdcColors.crypto),
                tooltip: 'Générer une clé aléatoire',
              ),
            ],
          ),
          if (_isRealCrypto)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'La passphrase est transformée en clé AES-256 via PBKDF2 (100 000 itérations + sel).',
                style: TextStyle(color: TdcColors.textMuted, fontSize: 11),
              ),
            ),
        ]),
        const SizedBox(height: 16),

        // Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isEncrypting ? null : _encryptText,
                icon: _isEncrypting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.lock),
                label: Text(_isEncrypting ? 'Chiffrement...' : 'Chiffrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TdcColors.crypto,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isDecrypting ? null : _decryptText,
                icon: _isDecrypting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.lock_open),
                label: Text(_isDecrypting ? 'Déchiffrement...' : 'Déchiffrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TdcColors.network,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Étapes pédagogiques
        if (_encryptSteps.isNotEmpty) ...[
          _buildStepsPanel('Étapes du processus', _encryptSteps, TdcColors.crypto),
          const SizedBox(height: 12),
        ],

        // Résultat
        _buildSection('Résultat chiffré', Icons.enhanced_encryption, [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TdcColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TdcColors.border),
            ),
            child: SelectableText(
              _cipherTextController.text.isEmpty
                  ? 'Le résultat apparaîtra ici après chiffrement...'
                  : _cipherTextController.text,
              style: TextStyle(
                color: _cipherTextController.text.isEmpty ? TdcColors.textMuted : TdcColors.system,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
          if (_lastEncryptResult != null) ...[
            const SizedBox(height: 8),
            _buildCryptoDetail('Nonce (IV)', _lastEncryptResult!.nonce),
            const SizedBox(height: 4),
            _buildCryptoDetail('MAC (Tag)', _lastEncryptResult!.mac),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (_cipherTextController.text.isNotEmpty)
                TextButton.icon(
                  onPressed: _copyCipherText,
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copier'),
                ),
            ],
          ),
        ]),
      ],
    );
  }

  Widget _buildCryptoDetail(String label, String value) {
    return Row(
      children: [
        Text('$label : ', style: const TextStyle(color: TdcColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: TdcColors.textSecondary, fontSize: 11, fontFamily: 'monospace'),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String get _cipherExplanation {
    switch (_selectedCipher) {
      case 'AES-GCM':
        return '🔐 AES-GCM (Galois/Counter Mode) est le standard actuel. '
            'Il chiffre ET authentifie les données en une seule opération. '
            'Utilisé dans TLS 1.3, Wi-Fi WPA3, et la plupart des VPN modernes. '
            'Chaque chiffrement génère un nonce unique (jamais réutilisé) et un tag MAC qui détecte toute altération.';
      case 'ChaCha20':
        return '🔐 ChaCha20-Poly1305 est l\'alternative à AES, conçue par Daniel Bernstein. '
            'Plus rapide que AES sur les processeurs sans accélération matérielle (mobiles, IoT). '
            'Utilisé par Google (QUIC/HTTP3), WireGuard, et Signal. '
            'Poly1305 fournit l\'authentification (comme le GCM pour AES).';
      case 'Caesar':
        return '📚 Le chiffre de César décale chaque lettre d\'un nombre fixe. '
            'Inventé par Jules César pour ses correspondances militaires. '
            'Vulnérable : seulement 25 clés possibles → cassable par force brute en quelques secondes. '
            'La clé ici = longueur de votre passphrase modulo 26.';
      case 'Vigenere':
        return '📚 Le chiffre de Vigenère utilise un mot-clé pour varier le décalage à chaque lettre. '
            'Considéré "incassable" pendant 300 ans, cassé en 1863 par Friedrich Kasiski. '
            'Vulnérable à l\'analyse de fréquence si le texte est assez long par rapport à la clé.';
      case 'XOR':
        return '📚 XOR (OU exclusif) est l\'opération de base de la plupart des chiffrements. '
            'Seul, il est trivial à casser (analyse de fréquence, known-plaintext). '
            'AES, ChaCha20, et presque tous les algorithmes modernes utilisent XOR comme brique de base, '
            'mais avec des rounds, des substitutions et des permutations en plus.';
      default:
        return '';
    }
  }

  // ── Hashage Tab ──────────────────────────────────────────

  Widget _buildHashTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildExplainer(
          _hashExplanation,
          color: TdcColors.crypto,
        ),
        const SizedBox(height: 12),

        _buildSection('Algorithme de hashage', Icons.fingerprint, [
          DropdownButton<String>(
            value: _selectedHash,
            isExpanded: true,
            dropdownColor: TdcColors.surface,
            items: const [
              DropdownMenuItem(value: 'SHA-256', child: Text('SHA-256 — standard actuel (Bitcoin, TLS)')),
              DropdownMenuItem(value: 'SHA-512', child: Text('SHA-512 — version 512 bits')),
              DropdownMenuItem(value: 'SHA-1', child: Text('SHA-1 ⚠️ OBSOLÈTE — collisions trouvées en 2017')),
              DropdownMenuItem(value: 'MD5', child: Text('MD5 ⚠️ CASSÉ — ne jamais utiliser pour la sécurité')),
              DropdownMenuItem(value: 'PBKDF2', child: Text('PBKDF2-SHA256 — dérivation de mot de passe')),
            ],
            onChanged: (v) => setState(() {
              _selectedHash = v!;
              _hashSteps.clear();
              _hashResult = '';
            }),
          ),
        ]),
        const SizedBox(height: 12),

        _buildSection('Données à hasher', Icons.input, [
          TextField(
            controller: _hashInputController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Entrez du texte, un mot de passe, n\'importe quoi...',
              hintStyle: TextStyle(color: TdcColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isHashing ? null : _hashData,
              icon: _isHashing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.fingerprint),
              label: Text(_isHashing ? 'Calcul en cours...' : 'Calculer le hash'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TdcColors.crypto,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ]),

        if (_hashSteps.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildStepsPanel('Étapes du hashage', _hashSteps, TdcColors.crypto),
        ],

        if (_hashResult.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSection('Résultat', Icons.check_circle, [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TdcColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TdcColors.border),
              ),
              child: SelectableText(
                _hashResult,
                style: const TextStyle(color: TdcColors.system, fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip('${_hashResult.length} caractères'),
                const SizedBox(width: 8),
                _buildInfoChip('${_hashResult.length * 4} bits'),
                const SizedBox(width: 8),
                _buildInfoChip(_selectedHash),
                const Spacer(),
                TextButton.icon(
                  onPressed: _copyHash,
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copier'),
                ),
              ],
            ),
          ]),
        ],

        const SizedBox(height: 12),
        _buildHashDemo(),
      ],
    );
  }

  Widget _buildHashDemo() {
    return _buildSection('Propriétés du hashage', Icons.science, [
      const Text(
        'Modifiez le texte ci-dessous — observez comment le moindre changement produit un hash totalement différent (effet avalanche) :',
        style: TextStyle(color: TdcColors.textSecondary, fontSize: 12),
      ),
      const SizedBox(height: 8),
      _buildHashCompare('Bonjour', 'Bonjour!'),
      const SizedBox(height: 4),
      _buildHashCompare('password', 'Password'),
      const SizedBox(height: 4),
      _buildHashCompare('abc', 'abd'),
    ]);
  }

  Widget _buildHashCompare(String a, String b) {
    final hashA = CryptoEngine.hashSha256(a);
    final hashB = CryptoEngine.hashSha256(b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('"$a"', style: const TextStyle(color: TdcColors.crypto, fontSize: 11, fontFamily: 'monospace'))),
            const SizedBox(width: 4),
            const Text('→', style: TextStyle(color: TdcColors.textMuted)),
            const SizedBox(width: 4),
            Expanded(flex: 3, child: Text('${hashA.substring(0, 20)}...', style: const TextStyle(color: TdcColors.textSecondary, fontSize: 10, fontFamily: 'monospace'))),
          ],
        ),
        Row(
          children: [
            Expanded(child: Text('"$b"', style: const TextStyle(color: TdcColors.network, fontSize: 11, fontFamily: 'monospace'))),
            const SizedBox(width: 4),
            const Text('→', style: TextStyle(color: TdcColors.textMuted)),
            const SizedBox(width: 4),
            Expanded(flex: 3, child: Text('${hashB.substring(0, 20)}...', style: const TextStyle(color: TdcColors.textSecondary, fontSize: 10, fontFamily: 'monospace'))),
          ],
        ),
        const Divider(height: 8),
      ],
    );
  }

  String get _hashExplanation {
    switch (_selectedHash) {
      case 'SHA-256':
        return '🔐 SHA-256 produit une empreinte unique de 256 bits (64 caractères hex). '
            'Utilisé par Bitcoin, TLS, Git, et la signature de code. '
            'Impossible de retrouver le message original à partir du hash (fonction à sens unique). '
            'Le moindre changement dans l\'entrée produit un hash totalement différent (effet avalanche).';
      case 'SHA-512':
        return '🔐 SHA-512 est la version 512 bits de SHA-2. '
            'Plus lent que SHA-256 sur les processeurs 32 bits, mais plus rapide sur 64 bits. '
            'Utilisé pour les signatures de haut niveau de sécurité et les certificats racine.';
      case 'SHA-1':
        return '⚠️ SHA-1 est OBSOLÈTE depuis 2017. Google et le CWI ont démontré une collision réelle (SHAttered). '
            'Deux fichiers PDF différents produisaient le même hash SHA-1. '
            'Les navigateurs rejettent les certificats SHA-1 depuis 2017. Ne l\'utilisez plus.';
      case 'MD5':
        return '⛔ MD5 est CASSÉ depuis 2004. Des collisions peuvent être générées en quelques secondes sur un laptop. '
            'Flame (malware d\'état) a exploité une collision MD5 pour usurper un certificat Microsoft. '
            'Seul usage acceptable : checksums non-sécuritaires (vérifier un téléchargement corrompu, pas malveillant).';
      case 'PBKDF2':
        return '🔐 PBKDF2 n\'est pas un simple hash — c\'est une fonction de dérivation de clé. '
            'Elle applique SHA-256 en boucle 100 000 fois avec un sel unique. '
            'Objectif : rendre le brute-force de mots de passe extrêmement lent. '
            'Alternative moderne : Argon2 (résistant aux GPU/ASIC).';
      default:
        return '';
    }
  }

  // ── Signature Tab ────────────────────────────────────────

  Widget _buildSignatureTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildExplainer(
          _selectedSignature == 'Ed25519'
              ? '🔐 Ed25519 utilise la courbe elliptique Curve25519 (conçue par Daniel Bernstein). '
                'Signatures compactes (64 octets), clés courtes (32 octets), et vérification très rapide. '
                'Utilisé par SSH, Signal, WireGuard, et la blockchain Solana. '
                'La clé privée signe, la clé publique vérifie — personne d\'autre ne peut forger votre signature.'
              : '🔐 HMAC-SHA256 est un code d\'authentification basé sur le hashage. '
                'Contrairement à Ed25519, la même clé secrète sert à signer ET vérifier. '
                'Utilisé dans JWT, les API (AWS Signature V4), et les cookies signés.',
          color: TdcColors.crypto,
        ),
        const SizedBox(height: 12),

        _buildSection('Algorithme de signature', Icons.draw, [
          DropdownButton<String>(
            value: _selectedSignature,
            isExpanded: true,
            dropdownColor: TdcColors.surface,
            items: const [
              DropdownMenuItem(value: 'Ed25519', child: Text('Ed25519 — signature asymétrique (clé privée/publique)')),
              DropdownMenuItem(value: 'HMAC', child: Text('HMAC-SHA256 — authentification symétrique (clé partagée)')),
            ],
            onChanged: (v) => setState(() {
              _selectedSignature = v!;
              _signSteps.clear();
              _signatureResult = '';
              _verificationResult = null;
            }),
          ),
        ]),
        const SizedBox(height: 12),

        if (_selectedSignature == 'Ed25519') ...[
          _buildSection('Paire de clés Ed25519', Icons.vpn_key, [
            const Text(
              'Clé privée (secrète — ne jamais partager) :',
              style: TextStyle(color: TdcColors.security, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _buildKeyDisplay(_privateKeyController.text),
            const SizedBox(height: 12),
            const Text(
              'Clé publique (partageable librement) :',
              style: TextStyle(color: TdcColors.system, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _buildKeyDisplay(_publicKeyController.text),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final kp = await CryptoEngine.generateEd25519KeyPair();
                if (!mounted) return;
                setState(() {
                  _signKeyPair = kp;
                  _privateKeyController.text = kp.privateKey;
                  _publicKeyController.text = kp.publicKey;
                  _signatureResult = '';
                  _verificationResult = null;
                });
              },
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Regénérer la paire de clés'),
            ),
          ]),
          const SizedBox(height: 12),
        ],

        _buildSection('Message à signer', Icons.edit, [
          TextField(
            controller: _signInputController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Tapez un message, un contrat, n\'importe quoi...',
              hintStyle: TextStyle(color: TdcColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSigning ? null : _signMessage,
                  icon: _isSigning
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.draw),
                  label: Text(_isSigning ? 'Signature...' : 'Signer le message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TdcColors.crypto,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isVerifying || _signatureResult.isEmpty) ? null : _verifySignature,
                  icon: _isVerifying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.verified),
                  label: Text(_isVerifying ? 'Vérification...' : 'Vérifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TdcColors.network,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ]),

        if (_signSteps.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildStepsPanel('Étapes', _signSteps, TdcColors.crypto),
        ],

        if (_signatureResult.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSection('Signature', Icons.fingerprint, [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TdcColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TdcColors.border),
              ),
              child: SelectableText(
                _signatureResult,
                style: const TextStyle(color: TdcColors.system, fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_signatureResult.length} caractères base64 (${(base64.decode(_signatureResult).length)} octets)',
              style: const TextStyle(color: TdcColors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 8),
            TextButton.icon(onPressed: _copySignature, icon: const Icon(Icons.copy, size: 14), label: const Text('Copier')),
          ]),
        ],

        if (_verificationResult != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (_verificationResult! ? TdcColors.system : TdcColors.security).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_verificationResult! ? TdcColors.system : TdcColors.security).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _verificationResult! ? Icons.check_circle : Icons.cancel,
                  color: _verificationResult! ? TdcColors.system : TdcColors.security,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _verificationResult! ? 'Signature VALIDE ✓' : 'Signature INVALIDE ✗',
                        style: TextStyle(
                          color: _verificationResult! ? TdcColors.system : TdcColors.security,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _verificationResult!
                            ? 'Le message n\'a pas été altéré et provient bien du détenteur de la clé privée.'
                            : 'Le message a été modifié, ou la signature ne correspond pas à la clé publique.',
                        style: TextStyle(
                          color: (_verificationResult! ? TdcColors.system : TdcColors.security).withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildKeyDisplay(String key) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: TdcColors.border),
      ),
      child: SelectableText(
        key.isEmpty ? '...' : key,
        style: const TextStyle(color: TdcColors.textSecondary, fontSize: 10, fontFamily: 'monospace'),
      ),
    );
  }

  // ── Shared UI components ─────────────────────────────────

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: TdcColors.crypto, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: TdcColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildExplainer(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 12, height: 1.5),
      ),
    );
  }

  Widget _buildStepsPanel(String title, List<String> steps, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: color, size: 16),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('${e.key + 1}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TdcColors.border),
      ),
      child: Text(text, style: const TextStyle(color: TdcColors.textMuted, fontSize: 10)),
    );
  }

  // ── Crypto logic ─────────────────────────────────────────

  Future<void> _encryptText() async {
    if (_plainTextController.text.isEmpty || _keyController.text.isEmpty) {
      _showError('Remplissez le texte et la clé.');
      return;
    }
    setState(() {
      _isEncrypting = true;
      _encryptSteps.clear();
    });

    try {
      String result;
      switch (_selectedCipher) {
        case 'AES-GCM':
          _addEncryptStep('Dérivation de la clé via PBKDF2 (100 000 itérations SHA-256 + sel)');
          _addEncryptStep('Génération d\'un nonce aléatoire de 96 bits (unique par opération)');
          _addEncryptStep('Chiffrement AES-256 en mode Galois/Counter Mode');
          _addEncryptStep('Calcul du tag d\'authentification (MAC) sur le ciphertext');
          final r = await CryptoEngine.aesGcmEncrypt(_plainTextController.text, _keyController.text);
          _lastEncryptResult = r;
          result = r.ciphertext;
          _addEncryptStep('✓ Terminé — ${result.length} caractères base64 + nonce + MAC');
          break;
        case 'ChaCha20':
          _addEncryptStep('Dérivation de la clé via PBKDF2 (100 000 itérations)');
          _addEncryptStep('Génération d\'un nonce aléatoire');
          _addEncryptStep('Chiffrement par flux ChaCha20 (20 rounds de quarter-rounds)');
          _addEncryptStep('Authentification via Poly1305');
          final r = await CryptoEngine.chacha20Encrypt(_plainTextController.text, _keyController.text);
          _lastEncryptResult = r;
          result = r.ciphertext;
          _addEncryptStep('✓ Terminé — ${result.length} caractères base64');
          break;
        case 'Caesar':
          final shift = _keyController.text.length % 26;
          _addEncryptStep('Calcul du décalage : longueur("${_keyController.text}") mod 26 = $shift');
          _addEncryptStep('Décalage de chaque lettre de $shift positions dans l\'alphabet');
          _addEncryptStep('Exemple : A → ${String.fromCharCode(65 + shift)}, Z → ${String.fromCharCode(65 + (26 - shift) % 26)}');
          result = CryptoEngine.caesarEncrypt(_plainTextController.text, shift);
          _lastEncryptResult = null;
          _addEncryptStep('✓ Résultat : "$result"');
          break;
        case 'Vigenere':
          _addEncryptStep('Clé : "${_keyController.text}" (répétée sur toute la longueur du texte)');
          _addEncryptStep('Pour chaque lettre : (lettre + clé[i]) mod 26');
          result = CryptoEngine.vigenereEncrypt(_plainTextController.text, _keyController.text);
          _lastEncryptResult = null;
          _addEncryptStep('✓ Résultat : "$result"');
          break;
        case 'XOR':
          _addEncryptStep('Conversion du texte en octets UTF-8');
          _addEncryptStep('XOR de chaque octet avec la clé (cyclique)');
          _addEncryptStep('Encodage du résultat en base64');
          result = CryptoEngine.xorEncrypt(_plainTextController.text, _keyController.text);
          _lastEncryptResult = null;
          _addEncryptStep('✓ Résultat : "$result"');
          break;
        default:
          result = _plainTextController.text;
          _lastEncryptResult = null;
      }
      setState(() => _cipherTextController.text = result);
    } catch (e) {
      _showError('Erreur : $e');
    } finally {
      setState(() => _isEncrypting = false);
    }
  }

  void _addEncryptStep(String step) {
    setState(() => _encryptSteps.add(step));
  }

  Future<void> _decryptText() async {
    if (_cipherTextController.text.isEmpty || _keyController.text.isEmpty) {
      _showError('Remplissez le texte chiffré et la clé.');
      return;
    }
    setState(() {
      _isDecrypting = true;
      _encryptSteps.clear();
    });

    try {
      String result;
      switch (_selectedCipher) {
        case 'AES-GCM':
          if (_lastEncryptResult == null) {
            _showError('Chiffrez d\'abord un texte pour conserver le nonce et le MAC.');
            return;
          }
          _addEncryptStep('Dérivation de la même clé via PBKDF2');
          _addEncryptStep('Vérification du tag MAC (intégrité et authenticité)');
          _addEncryptStep('Déchiffrement AES-256-GCM avec le nonce original');
          result = await CryptoEngine.aesGcmDecrypt(
            AesGcmResult(ciphertext: _cipherTextController.text, nonce: _lastEncryptResult!.nonce, mac: _lastEncryptResult!.mac),
            _keyController.text,
          );
          _addEncryptStep('✓ Message restauré avec succès');
          break;
        case 'ChaCha20':
          if (_lastEncryptResult == null) {
            _showError('Chiffrez d\'abord un texte.');
            return;
          }
          _addEncryptStep('Dérivation de la clé + vérification Poly1305');
          _addEncryptStep('Déchiffrement ChaCha20');
          result = await CryptoEngine.chacha20Decrypt(
            AesGcmResult(ciphertext: _cipherTextController.text, nonce: _lastEncryptResult!.nonce, mac: _lastEncryptResult!.mac),
            _keyController.text,
          );
          _addEncryptStep('✓ Message restauré');
          break;
        case 'Caesar':
          final shift = _keyController.text.length % 26;
          _addEncryptStep('Décalage inverse de $shift positions');
          result = CryptoEngine.caesarDecrypt(_cipherTextController.text, shift);
          _addEncryptStep('✓ Résultat : "$result"');
          break;
        case 'Vigenere':
          _addEncryptStep('Soustraction de la clé (inverse de l\'addition)');
          result = CryptoEngine.vigenereDecrypt(_cipherTextController.text, _keyController.text);
          _addEncryptStep('✓ Résultat : "$result"');
          break;
        case 'XOR':
          _addEncryptStep('XOR avec la même clé (XOR est son propre inverse)');
          result = CryptoEngine.xorDecrypt(_cipherTextController.text, _keyController.text);
          _addEncryptStep('✓ Résultat : "$result"');
          break;
        default:
          result = _cipherTextController.text;
      }
      setState(() => _plainTextController.text = result);
    } catch (e) {
      _showError('Erreur de déchiffrement. Mauvaise clé ?');
    } finally {
      setState(() => _isDecrypting = false);
    }
  }

  Future<void> _hashData() async {
    if (_hashInputController.text.isEmpty) {
      _showError('Entrez des données à hasher.');
      return;
    }
    setState(() {
      _isHashing = true;
      _hashSteps.clear();
    });

    try {
      String hash;
      final input = _hashInputController.text;
      final inputBytes = utf8.encode(input);

      _hashSteps.add('Entrée : ${inputBytes.length} octets (${input.length} caractères)');

      switch (_selectedHash) {
        case 'SHA-256':
          _hashSteps.add('Padding du message à un multiple de 512 bits');
          _hashSteps.add('64 rounds de compression avec constantes dérivées des nombres premiers');
          hash = CryptoEngine.hashSha256(input);
          _hashSteps.add('✓ Empreinte de 256 bits (32 octets)');
          break;
        case 'SHA-512':
          _hashSteps.add('Padding à un multiple de 1024 bits');
          _hashSteps.add('80 rounds de compression');
          hash = CryptoEngine.hashSha512(input);
          _hashSteps.add('✓ Empreinte de 512 bits (64 octets)');
          break;
        case 'SHA-1':
          _hashSteps.add('⚠️ Algorithme obsolète — collisions démontrées (SHAttered, 2017)');
          hash = CryptoEngine.hashSha1(input);
          _hashSteps.add('Empreinte de 160 bits — NE PAS utiliser en production');
          break;
        case 'MD5':
          _hashSteps.add('⛔ Algorithme cassé — collisions triviales depuis 2004');
          hash = CryptoEngine.hashMd5(input);
          _hashSteps.add('Empreinte de 128 bits — à bannir pour la sécurité');
          break;
        case 'PBKDF2':
          _hashSteps.add('Sel fixe "t2decode" (en production, utilisez un sel aléatoire par utilisateur)');
          _hashSteps.add('100 000 itérations de HMAC-SHA256');
          _hashSteps.add('Chaque itération ralentit volontairement le brute-force');
          hash = await CryptoEngine.hashPbkdf2(input);
          _hashSteps.add('✓ Clé dérivée de 256 bits en base64');
          break;
        default:
          hash = CryptoEngine.hashSha256(input);
      }
      setState(() {
        _hashResult = hash;
        _isHashing = false;
      });
    } catch (e) {
      _showError('Erreur : $e');
      setState(() => _isHashing = false);
    }
  }

  Future<void> _signMessage() async {
    if (_signInputController.text.isEmpty) {
      _showError('Entrez un message à signer.');
      return;
    }
    setState(() {
      _isSigning = true;
      _signSteps.clear();
      _verificationResult = null;
    });

    try {
      String signature;
      _lastSignedMessage = _signInputController.text;

      if (_selectedSignature == 'Ed25519') {
        _signKeyPair ??= await CryptoEngine.generateEd25519KeyPair();
        _signSteps.add('Hash du message (SHA-512 interne à Ed25519)');
        _signSteps.add('Multiplication scalaire sur Curve25519 avec la clé privée');
        _signSteps.add('Génération de la signature (r, s) — 64 octets');
        signature = await CryptoEngine.ed25519Sign(_lastSignedMessage, _signKeyPair!.privateKey);
        _signSteps.add('✓ Signature créée — vérifiable par quiconque possède la clé publique');
        _privateKeyController.text = _signKeyPair!.privateKey;
        _publicKeyController.text = _signKeyPair!.publicKey;
      } else {
        _signSteps.add('Combinaison de la clé secrète avec le message');
        _signSteps.add('Double passe de SHA-256 (inner hash + outer hash)');
        signature = CryptoEngine.hmacSha256(_lastSignedMessage, _keyController.text);
        _signSteps.add('✓ MAC créé — vérifiable uniquement par qui connaît la clé secrète');
      }
      setState(() {
        _signatureResult = signature;
        _isSigning = false;
      });
    } catch (e) {
      _showError('Erreur : $e');
      setState(() => _isSigning = false);
    }
  }

  Future<void> _verifySignature() async {
    if (_signatureResult.isEmpty || _lastSignedMessage.isEmpty) return;
    setState(() => _isVerifying = true);

    try {
      bool valid;
      if (_selectedSignature == 'Ed25519' && _signKeyPair != null) {
        valid = await CryptoEngine.ed25519Verify(
          _lastSignedMessage, _signatureResult, _signKeyPair!.publicKey,
        );
      } else {
        final expected = CryptoEngine.hmacSha256(_lastSignedMessage, _keyController.text);
        valid = expected == _signatureResult;
      }
      setState(() {
        _verificationResult = valid;
        _isVerifying = false;
      });
    } catch (e) {
      setState(() {
        _verificationResult = false;
        _isVerifying = false;
      });
    }
  }

  void _generateKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    setState(() => _keyController.text = base64.encode(keyBytes));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  void _copyCipherText() {
    Clipboard.setData(ClipboardData(text: _cipherTextController.text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copié'), behavior: SnackBarBehavior.floating));
  }

  void _copyHash() {
    Clipboard.setData(ClipboardData(text: _hashResult));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copié'), behavior: SnackBarBehavior.floating));
  }

  void _copySignature() {
    Clipboard.setData(ClipboardData(text: _signatureResult));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copié'), behavior: SnackBarBehavior.floating));
  }
}
