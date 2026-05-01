// ============================================================
// Cryptography Simulator - Simulation cryptographie ultra-professionnelle
// ============================================================
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
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
  
  // Controllers
  final TextEditingController _plainTextController = TextEditingController();
  final TextEditingController _cipherTextController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _hashInputController = TextEditingController();
  final TextEditingController _signInputController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();
  
  // États
  bool _isEncrypting = false;
  bool _isDecrypting = false;
  bool _isHashing = false;
  bool _isSigning = false;
  bool _isVerifying = false;
  
  // Résultats
  String _hashResult = '';
  String _signatureResult = '';
  bool _verificationResult = false;
  
  // Algorithmes sélectionnés
  String _selectedCipher = 'AES';
  String _selectedHash = 'SHA-256';
  String _selectedSignature = 'RSA';

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
    // Générer des clés de démonstration
    _keyController.text = 'MySecretKey123!';
    _privateKeyController.text = '-----BEGIN PRIVATE KEY-----\nMIIEpAIBAAKCAQEA...\n-----END PRIVATE KEY-----';
    _publicKeyController.text = '-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhki...\n-----END PUBLIC KEY-----';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        LabGlassContainer(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.lock, color: TdcColors.crypto, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'CRYPTOGRAPHIE & CRYPTO-ANALYSE',
                    style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: TdcColors.crypto.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TdcColors.crypto.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: TdcColors.crypto,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'MODE DÉMO',
                          style: TextStyle(
                            color: TdcColors.crypto,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const LabNotice(
                title: 'Simulation pédagogique',
                message:
                    'Chiffrement et signatures simulés (démo, non sécurisés). '
                    'Aucun usage production.',
                icon: Icons.info_outline,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LabMetricCard(
                      title: 'Algorithme',
                      value: _selectedCipher,
                      icon: Icons.settings_suggest,
                      color: TdcColors.crypto,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabMetricCard(
                      title: 'Sécurité',
                      value: 'DÉMO',
                      icon: Icons.verified_user,
                      color: TdcColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabMetricCard(
                      title: 'Entropie',
                      value: 'N/A',
                      icon: Icons.analytics,
                      color: TdcColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabMetricCard(
                      title: 'Status',
                      value: 'SIMULÉ',
                      icon: Icons.lock_outline,
                      color: TdcColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Tabs
        Container(
          color: TdcColors.surfaceAlt.withOpacity(0.3),
          child: TabBar(
            controller: _tabController,
            indicatorColor: TdcColors.crypto,
            labelColor: TdcColors.crypto,
            unselectedLabelColor: TdcColors.textMuted,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Chiffrement'),
              Tab(text: 'Hashage'),
              Tab(text: 'Signature'),
              Tab(text: '🤖 IA'),
            ],
          ),
        ),
        
        // Content
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
                    'Tu es un expert en cryptographie et sécurité des données. Réponds en français, de façon pédagogique. '
                    'Domaines couverts : chiffrement symétrique/asymétrique (AES, RSA, ECC), fonctions de hachage '
                    '(SHA-256, MD5), signatures numériques, certificats SSL/TLS, PKI, entropie, protocoles de clés.',
                suggestedQuestions: [
                  'Différence AES vs RSA ?',
                  'Pourquoi MD5 est-il cassé ?',
                  'Comment fonctionne TLS ?',
                  'C\'est quoi une PKI ?',
                  'Qu\'est-ce que l\'entropie cryptographique ?',
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEncryptionTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const LabNotice(
            title: 'Chiffrement simulé',
            message:
                'Le chiffrement est une démonstration simplifiée (XOR), '
                'pas un AES réel.',
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: 12),
          // Sélection de l'algorithme
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Algorithme de Chiffrement',
                    style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedCipher,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'AES', child: Text('AES-256')),
                            DropdownMenuItem(value: 'DES', child: Text('DES')),
                            DropdownMenuItem(value: '3DES', child: Text('3DES')),
                            DropdownMenuItem(value: 'RSA', child: Text('RSA')),
                            DropdownMenuItem(value: 'Blowfish', child: Text('Blowfish')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedCipher = value!);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          value: 'CBC',
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'CBC', child: Text('CBC')),
                            DropdownMenuItem(value: 'ECB', child: Text('ECB')),
                            DropdownMenuItem(value: 'CFB', child: Text('CFB')),
                            DropdownMenuItem(value: 'OFB', child: Text('OFB')),
                            DropdownMenuItem(value: 'CTR', child: Text('CTR')),
                          ],
                          onChanged: (value) {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Zone de texte clair
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.text_fields, color: TdcColors.crypto),
                      const SizedBox(width: 8),
                      const Text(
                        'Texte Clair',
                        style: TextStyle(
                          color: TdcColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _plainTextController.clear(),
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _plainTextController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Entrez le texte à chiffrer...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Clé de chiffrement
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.vpn_key, color: TdcColors.crypto),
                      const SizedBox(width: 8),
                      const Text(
                        'Clé de Chiffrement',
                        style: TextStyle(
                          color: TdcColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _generateKey,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Générer une clé',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _keyController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Clé de chiffrement...',
                      suffixIcon: Icon(Icons.visibility_off),
                    ),
                    obscureText: true,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isEncrypting ? null : _encryptText,
                  icon: _isEncrypting 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock),
                  label: Text(_isEncrypting ? 'Chiffrement...' : 'Chiffrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TdcColors.crypto,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isDecrypting ? null : _decryptText,
                  icon: _isDecrypting 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open),
                  label: Text(_isDecrypting ? 'Déchiffrement...' : 'Déchiffrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TdcColors.network,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Zone de texte chiffré
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.enhanced_encryption, color: TdcColors.crypto),
                      const SizedBox(width: 8),
                      const Text(
                        'Texte Chiffré',
                        style: TextStyle(
                          color: TdcColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _copyCipherText,
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copier',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cipherTextController,
                    maxLines: 4,
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Texte chiffré apparaîtra ici...',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const LabNotice(
            title: 'Hashage local',
            message: 'Hash SHA-256 calculé localement. Pas d\'appel réseau.',
            icon: Icons.fingerprint,
          ),
          const SizedBox(height: 12),
          // Sélection de l'algorithme de hash
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.fingerprint, color: TdcColors.crypto),
                  const SizedBox(width: 8),
                  const Text(
                    'Algorithme de Hashage',
                    style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _selectedHash,
                    items: const [
                      DropdownMenuItem(value: 'SHA-256', child: Text('SHA-256')),
                      DropdownMenuItem(value: 'SHA-512', child: Text('SHA-512')),
                      DropdownMenuItem(value: 'MD5', child: Text('MD5')),
                      DropdownMenuItem(value: 'SHA-1', child: Text('SHA-1')),
                      DropdownMenuItem(value: 'SHA-3', child: Text('SHA-3')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedHash = value!);
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Zone d'entrée pour le hash
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.input, color: TdcColors.crypto),
                      const SizedBox(width: 8),
                      const Text(
                        'Données à Hasher',
                        style: TextStyle(
                          color: TdcColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hashInputController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Entrez les données à hasher...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isHashing ? null : _hashData,
                    icon: _isHashing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint),
                    label: Text(_isHashing ? 'Hashage...' : 'Hasher'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TdcColors.crypto,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Résultat du hash
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: TdcColors.crypto),
                      const SizedBox(width: 8),
                      const Text(
                        'Résultat du Hash',
                        style: TextStyle(
                          color: TdcColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _copyHash,
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copier',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: TdcColors.border),
                    ),
                    child: SelectableText(
                      _hashResult.isEmpty ? 'Le hash apparaîtra ici...' : _hashResult,
                      style: const TextStyle(
                        color: TdcColors.system,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Longueur: ${_hashResult.length} caractères',
                        style: const TextStyle(
                          color: TdcColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Algorithme: $_selectedHash',
                        style: const TextStyle(
                          color: TdcColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const LabNotice(
            title: 'Signature simulée',
            message:
                'Signature générée aléatoirement pour la démo (pas de RSA réel).',
            icon: Icons.gpp_maybe,
          ),
          const SizedBox(height: 12),
          // Sélection de l'algorithme de signature
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.gavel, color: TdcColors.crypto),
                  const SizedBox(width: 8),
                  const Text(
                    'Algorithme de Signature',
                    style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _selectedSignature,
                    items: const [
                      DropdownMenuItem(value: 'RSA', child: Text('RSA')),
                      DropdownMenuItem(value: 'ECDSA', child: Text('ECDSA')),
                      DropdownMenuItem(value: 'DSA', child: Text('DSA')),
                      DropdownMenuItem(value: 'EdDSA', child: Text('EdDSA')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedSignature = value!);
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Clés
          Row(
            children: [
              Expanded(
                child: Card(
                  color: TdcColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.vpn_key, color: TdcColors.crypto),
                            const SizedBox(width: 8),
                            const Text(
                              'Clé Privée',
                              style: TextStyle(
                                color: TdcColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _privateKeyController,
                          maxLines: 3,
                          readOnly: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Clé privée...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  color: TdcColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.public, color: TdcColors.crypto),
                            const SizedBox(width: 8),
                            const Text(
                              'Clé Publique',
                              style: TextStyle(
                                color: TdcColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _publicKeyController,
                          maxLines: 3,
                          readOnly: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Clé publique...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Zone de signature
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit, color: TdcColors.crypto),
                      const SizedBox(width: 8),
                      const Text(
                        'Message à Signer',
                        style: TextStyle(
                          color: TdcColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _signInputController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Entrez le message à signer...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSigning ? null : _signMessage,
                          icon: _isSigning 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.gavel),
                          label: Text(_isSigning ? 'Signature...' : 'Signer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TdcColors.crypto,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isVerifying ? null : _verifySignature,
                          icon: _isVerifying 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.verified),
                          label: Text(_isVerifying ? 'Vérification...' : 'Vérifier'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TdcColors.network,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Résultats
          Row(
            children: [
              Expanded(
                child: Card(
                  color: TdcColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.fingerprint, color: TdcColors.crypto),
                            const SizedBox(width: 8),
                            const Text(
                              'Signature',
                              style: TextStyle(
                                color: TdcColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _copySignature,
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copier',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: TdcColors.border),
                          ),
                          child: SelectableText(
                            _signatureResult.isEmpty ? 'Signature...' : _signatureResult,
                            style: const TextStyle(
                              color: TdcColors.system,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  color: TdcColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_user, color: TdcColors.crypto),
                            const SizedBox(width: 8),
                            const Text(
                              'Vérification',
                              style: TextStyle(
                                color: TdcColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _verificationResult 
                                ? TdcColors.system.withOpacity(0.1)
                                : TdcColors.security.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _verificationResult 
                                  ? TdcColors.system.withOpacity(0.3)
                                  : TdcColors.security.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _verificationResult ? Icons.check_circle : Icons.error,
                                color: _verificationResult ? TdcColors.system : TdcColors.security,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _verificationResult ? 'Signature Valide' : 'Signature Invalide',
                                style: TextStyle(
                                  color: _verificationResult ? TdcColors.system : TdcColors.security,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Méthodes de simulation
  Future<void> _encryptText() async {
    setState(() => _isEncrypting = true);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_plainTextController.text.isNotEmpty && _keyController.text.isNotEmpty) {
      // Simuler le chiffrement
      final bytes = utf8.encode(_plainTextController.text);
      final key = utf8.encode(_keyController.text);
      final encrypted = _simulateAES(bytes, key);
      
      setState(() {
        _cipherTextController.text = encrypted;
        _isEncrypting = false;
      });
    } else {
      setState(() => _isEncrypting = false);
    }
  }

  Future<void> _decryptText() async {
    setState(() => _isDecrypting = true);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_cipherTextController.text.isNotEmpty && _keyController.text.isNotEmpty) {
      // Simuler le déchiffrement
      final decrypted = _simulateAESDecrypt(_cipherTextController.text);
      
      setState(() {
        _plainTextController.text = decrypted;
        _isDecrypting = false;
      });
    } else {
      setState(() => _isDecrypting = false);
    }
  }

  Future<void> _hashData() async {
    setState(() => _isHashing = true);
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (_hashInputController.text.isNotEmpty) {
      String hash;
      switch (_selectedHash) {
        case 'SHA-256':
          hash = sha256.convert(utf8.encode(_hashInputController.text)).toString();
          break;
        case 'SHA-512':
          hash = sha512.convert(utf8.encode(_hashInputController.text)).toString();
          break;
        case 'MD5':
          hash = md5.convert(utf8.encode(_hashInputController.text)).toString();
          break;
        default:
          hash = sha256.convert(utf8.encode(_hashInputController.text)).toString();
      }
      
      setState(() {
        _hashResult = hash;
        _isHashing = false;
      });
    } else {
      setState(() => _isHashing = false);
    }
  }

  Future<void> _signMessage() async {
    setState(() => _isSigning = true);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_signInputController.text.isNotEmpty) {
      // Simuler la signature
      final message = _signInputController.text;
      final hash = sha256.convert(utf8.encode(message)).toString();
      final signature = _simulateRSASign(hash);
      
      setState(() {
        _signatureResult = signature;
        _isSigning = false;
      });
    } else {
      setState(() => _isSigning = false);
    }
  }

  Future<void> _verifySignature() async {
    setState(() => _isVerifying = true);
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Simuler la vérification
    setState(() {
      _verificationResult = _signatureResult.isNotEmpty;
      _isVerifying = false;
    });
  }

  void _generateKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    final key = base64.encode(keyBytes);
    setState(() {
      _keyController.text = key;
    });
  }

  void _copyCipherText() {
    Clipboard.setData(ClipboardData(text: _cipherTextController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Texte chiffré copié')),
    );
  }

  void _copyHash() {
    Clipboard.setData(ClipboardData(text: _hashResult));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hash copié')),
    );
  }

  void _copySignature() {
    Clipboard.setData(ClipboardData(text: _signatureResult));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signature copiée')),
    );
  }

  // Méthodes de simulation (simplifiées pour la démo)
  String _simulateAES(List<int> data, List<int> key) {
    // Simuler AES avec un simple XOR pour la démo
    final encrypted = <int>[];
    for (int i = 0; i < data.length; i++) {
      encrypted.add(data[i] ^ key[i % key.length]);
    }
    return base64.encode(encrypted);
  }

  String _simulateAESDecrypt(String encryptedText) {
    try {
      final encrypted = base64.decode(encryptedText);
      final key = utf8.encode(_keyController.text);
      final decrypted = <int>[];
      for (int i = 0; i < encrypted.length; i++) {
        decrypted.add(encrypted[i] ^ key[i % key.length]);
      }
      return utf8.decode(decrypted);
    } catch (e) {
      return 'Erreur de déchiffrement';
    }
  }

  String _simulateRSASign(String hash) {
    // Simuler une signature RSA
    final random = Random();
    final signature = List<int>.generate(64, (i) => random.nextInt(256));
    return base64.encode(signature);
  }
}
