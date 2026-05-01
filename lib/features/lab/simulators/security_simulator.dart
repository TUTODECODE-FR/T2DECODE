// ============================================================
// Security Simulator - Simulation sécurité ultra-professionnelle
// ============================================================
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/lab/widgets/lab_widgets.dart';
import 'package:tutodecode/features/lab/widgets/simulator_ai_assistant.dart';

class SecuritySimulator extends StatefulWidget {
  const SecuritySimulator({super.key});

  @override
  State<SecuritySimulator> createState() => _SecuritySimulatorState();
}

class _SecuritySimulatorState extends State<SecuritySimulator>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // États des simulations
  bool _isScanning = false;
  bool _isBruteForcing = false;
  bool _isAnalyzing = false;
  
  // Données de simulation
  List<Vulnerability> _vulnerabilities = [];
  List<LogEntry> _logEntries = [];
  
  // Métriques de sécurité
  int _threatLevel = 0;
  int _blockedAttacks = 0;
  int _activeConnections = 0;
  double _securityScore = 100.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeSecurityData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _targetController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _initializeSecurityData() {
    // Initialiser avec des données d'exemple
    _vulnerabilities = [
      Vulnerability(
        type: 'SQL Injection',
        severity: 'Critical',
        description: 'Paramètres non filtrés dans la requête SQL',
        url: '/api/users',
        cvss: 9.8,
        cve: 'CVE-EXEMPLE-0001',
      ),
      Vulnerability(
        type: 'XSS',
        severity: 'High',
        description: 'Injection de script dans les champs de saisie',
        url: '/search',
        cvss: 7.5,
        cve: 'CVE-EXEMPLE-0002',
      ),
    ];
    
    _logEntries = [
      LogEntry(
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        level: 'WARNING',
        source: 'IDS',
        message: 'Tentative d\'injection SQL détectée',
        ip: '192.168.1.100',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header avec métriques de sécurité
        LabGlassContainer(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.security, color: TdcColors.security, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'SÉCURITÉ RÉSEAU & INFRA',
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
                      color: TdcColors.security.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TdcColors.security.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: TdcColors.security,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'IDS/IPS (DÉMO)',
                          style: TextStyle(
                            color: TdcColors.security,
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
                    'Aucune attaque réelle. Alertes, CVE et logs sont fictifs.',
                icon: Icons.info_outline,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LabMetricCard(
                      title: 'Score Sécurité',
                      value: '${_securityScore.toStringAsFixed(1)}%',
                      icon: Icons.shield,
                      color: _getSecurityColor('${_securityScore.toStringAsFixed(1)}%'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabMetricCard(
                      title: 'Menace',
                      value: '$_threatLevel/10',
                      icon: Icons.warning,
                      color: _threatLevel > 5 ? TdcColors.security : TdcColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabMetricCard(
                      title: 'Blocages',
                      value: '$_blockedAttacks',
                      icon: Icons.block,
                      color: TdcColors.danger,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabMetricCard(
                      title: 'Actifs',
                      value: '$_activeConnections',
                      icon: Icons.link,
                      color: TdcColors.success,
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
            indicatorColor: TdcColors.security,
            labelColor: TdcColors.security,
            unselectedLabelColor: TdcColors.textMuted,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Scan Vuln'),
              Tab(text: 'Pentest'),
              Tab(text: 'IDS/IPS'),
              Tab(text: '🤖 IA'),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildVulnerabilityScanTab(),
              _buildPentestTab(),
              _buildIdsIpsTab(),
              const SimulatorAIAssistant(
                topic: 'Cybersécurité & Pentest',
                accentColor: TdcColors.security,
                systemPrompt:
                    'Tu es un expert en cybersécurité offensive et défensive (OSCP/CEH). Réponds en français. '
                    'Domaines couverts : scan de vulnérabilités, tests de pénétration, IDS/IPS, analyse forensique, '
                    'CVE/CVSS, OWASP Top 10, chiffrement, hardening système, réponse aux incidents. '
                    'Ne fournis pas de code malveillant réel — reste dans un contexte éducatif.',
                suggestedQuestions: [
                  'Qu\'est-ce que le CVSS ?',
                  'Comment fonctionne un IDS/IPS ?',
                  'Expliquer l\'injection SQL',
                  'Différence pentest vs audit ?',
                  'C\'est quoi le XSS ?',
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }


  Color _getSecurityColor(String value) {
    if (value.contains('%')) {
      final score = double.tryParse(value.replaceAll('%', '')) ?? 0;
      if (score >= 80) return TdcColors.success;
      if (score >= 60) return TdcColors.warning;
      return TdcColors.security;
    }
    return TdcColors.textPrimary;
  }

  Widget _buildVulnerabilityScanTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contrôles de scan
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuration du Scan',
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
                        child: TextField(
                          controller: _targetController,
                          decoration: const InputDecoration(
                            labelText: 'Cible (URL ou IP)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.track_changes),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isScanning ? null : _performVulnerabilityScan,
                        icon: _isScanning 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isScanning ? 'Scan...' : 'Scanner'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TdcColors.security,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Scan SQL Injection'),
                          value: true,
                          onChanged: (value) {},
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Scan XSS'),
                          value: true,
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
          
          // Résultats du scan
          Expanded(
            child: Card(
              color: TdcColors.surface,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.bug_report, color: TdcColors.security),
                        const SizedBox(width: 8),
                        const Text(
                          'Vulnérabilités Détectées',
                          style: TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getVulnerabilityCountColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getVulnerabilityCountColor().withOpacity(0.3)),
                          ),
                          child: Text(
                            '${_vulnerabilities.length} vulnérabilités',
                            style: TextStyle(
                              color: _getVulnerabilityCountColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _vulnerabilities.length,
                      itemBuilder: (context, index) {
                        final vulnerability = _vulnerabilities[index];
                        return _buildVulnerabilityCard(vulnerability);
                      },
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

  Widget _buildVulnerabilityCard(Vulnerability vulnerability) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getSeverityColor(vulnerability.severity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getSeverityColor(vulnerability.severity).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSeverityColor(vulnerability.severity),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vulnerability.severity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vulnerability.type,
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                  'CVSS: ${vulnerability.cvss}',
                  style: const TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            vulnerability.description,
            style: const TextStyle(
              color: TdcColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.link, color: TdcColors.textTertiary, size: 16),
              const SizedBox(width: 4),
              Text(
                vulnerability.url,
                style: const TextStyle(
                  color: TdcColors.network,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                vulnerability.cve,
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPentestTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contrôles Pentest
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _targetController,
                          decoration: const InputDecoration(
                            labelText: 'Cible',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.track_changes),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isBruteForcing ? null : _startBruteForce,
                        icon: _isBruteForcing 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_open),
                        label: Text(_isBruteForcing ? 'Test...' : 'Brute Force'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TdcColors.security,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Wordlist',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.list),
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
          
          // Résultats du Pentest
          Expanded(
            child: Card(
              color: TdcColors.surface,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'Résultats du Pentest',
                      style: TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return _buildPentestResult(index);
                      },
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

  Widget _buildPentestResult(int index) {
    final attempts = ['admin:123456', 'root:password', 'user:user', 'test:test'];
    final attempt = attempts[index % attempts.length];
    final success = index == 3; // Simuler un succès
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success 
            ? TdcColors.system.withOpacity(0.1)
            : TdcColors.border.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: success 
              ? TdcColors.system.withOpacity(0.3)
              : TdcColors.border.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.close,
            color: success ? TdcColors.success : TdcColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt,
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  success ? 'Connexion réussie!' : 'Échec de connexion',
                  style: TextStyle(
                    color: success ? TdcColors.success : TdcColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (success)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TdcColors.system,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SUCCESS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIdsIpsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contrôles IDS/IPS
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SwitchListTile(
                                title: const Text('IDS Actif'),
                                value: true,
                                onChanged: (value) {},
                              ),
                            ),
                            Expanded(
                              child: SwitchListTile(
                                title: const Text('IPS Actif'),
                                value: true,
                                onChanged: (value) {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _startIdsAnalysis,
                        icon: _isAnalyzing 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.analytics),
                        label: Text(_isAnalyzing ? 'Analyse...' : 'Analyser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TdcColors.security,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Logs de sécurité
          Expanded(
            child: Card(
              color: TdcColors.surface,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.list_alt, color: TdcColors.security),
                        const SizedBox(width: 8),
                        const Text(
                          'Logs de Sécurité',
                          style: TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: TdcColors.security.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: TdcColors.security.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'DÉMO',
                            style: TextStyle(
                              color: TdcColors.security,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _logEntries.length,
                      itemBuilder: (context, index) {
                        final log = _logEntries[index];
                        return _buildLogEntry(log);
                      },
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

  Widget _buildLogEntry(LogEntry log) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getLogLevelColor(log.level).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getLogLevelColor(log.level).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getLogLevelColor(log.level),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.level,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                log.source,
                style: const TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                log.timestamp.toIso8601String().substring(11, 19),
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            log.message,
            style: const TextStyle(
              color: TdcColors.textSecondary,
              fontSize: 11,
            ),
          ),
          if (log.ip.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.lan, color: TdcColors.textTertiary, size: 12),
                const SizedBox(width: 4),
                Text(
                  'IP: ${log.ip}',
                  style: const TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Méthodes de simulation
  Future<void> _performVulnerabilityScan() async {
    setState(() => _isScanning = true);
    
    await Future.delayed(const Duration(seconds: 3));
    
    final newVulnerabilities = [
      Vulnerability(
        type: 'Directory Traversal',
        severity: 'Medium',
        description: 'Accès aux fichiers système via ../',
        url: '/files',
        cvss: 5.3,
        cve: 'CVE-EXEMPLE-0003',
      ),
      Vulnerability(
        type: 'Weak Password',
        severity: 'Low',
        description: 'Politique de mot de passe faible',
        url: '/login',
        cvss: 3.1,
        cve: 'CVE-EXEMPLE-0004',
      ),
    ];
    
    setState(() {
      _isScanning = false;
      _vulnerabilities.addAll(newVulnerabilities);
      _securityScore = (_vulnerabilities.length > 5) ? 45.0 : 75.0;
    });
  }

  Future<void> _startBruteForce() async {
    setState(() => _isBruteForcing = true);
    
    await Future.delayed(const Duration(seconds: 5));
    
    setState(() => _isBruteForcing = false);
  }

  Future<void> _startIdsAnalysis() async {
    setState(() => _isAnalyzing = true);
    
    // Simuler l'analyse et l'ajout de logs
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final log = LogEntry(
        timestamp: DateTime.now(),
        level: ['INFO', 'WARNING', 'CRITICAL'][Random().nextInt(3)],
        source: 'IDS',
        message: 'Activité réseau suspecte détectée',
        ip: '192.168.1.${Random().nextInt(254) + 1}',
      );
      
      setState(() {
        _logEntries.insert(0, log);
        if (_logEntries.length > 50) {
          _logEntries.removeLast();
        }
      });
    }
    
    setState(() => _isAnalyzing = false);
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical': return TdcColors.security;
      case 'High': return TdcColors.crypto;
      case 'Medium': return Colors.yellow;
      case 'Low': return TdcColors.network;
      default: return TdcColors.border;
    }
  }

  Color _getVulnerabilityCountColor() {
    if (_vulnerabilities.length >= 5) return TdcColors.security;
    if (_vulnerabilities.length >= 3) return TdcColors.crypto;
    return TdcColors.system;
  }

  Color _getLogLevelColor(String level) {
    switch (level) {
      case 'CRITICAL': return TdcColors.security;
      case 'WARNING': return TdcColors.crypto;
      case 'INFO': return TdcColors.network;
      default: return TdcColors.border;
    }
  }
}

// Modèles de données
class Vulnerability {
  final String type;
  final String severity;
  final String description;
  final String url;
  final double cvss;
  final String cve;

  Vulnerability({
    required this.type,
    required this.severity,
    required this.description,
    required this.url,
    required this.cvss,
    required this.cve,
  });
}

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String source;
  final String message;
  final String ip;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
    required this.ip,
  });
}

class NetworkConnection {
  final String sourceIp;
  final String destIp;
  final int port;
  final String protocol;
  final String state;
  final DateTime timestamp;

  NetworkConnection({
    required this.sourceIp,
    required this.destIp,
    required this.port,
    required this.protocol,
    required this.state,
    required this.timestamp,
  });
}

class SecurityEvent {
  final String type;
  final String description;
  final String severity;
  final DateTime timestamp;
  final String sourceIp;

  SecurityEvent({
    required this.type,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.sourceIp,
  });
}
