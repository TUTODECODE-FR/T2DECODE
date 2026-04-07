// ============================================================
// Ethical Hacking Simulator — Simulateur de hacking éthique avancé
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

class EthicalHackingSimulator extends StatefulWidget {
  const EthicalHackingSimulator({super.key});

  @override
  State<EthicalHackingSimulator> createState() => _EthicalHackingSimulatorState();
}

class _EthicalHackingSimulatorState extends State<EthicalHackingSimulator>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Nmap Scanner State
  final _targetController = TextEditingController(text: '192.168.1.0/24');
  final List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  double _scanProgress = 0.0;
  
  // SQL Injection State
  final _sqlUrlController = TextEditingController(text: 'http://testsite.com/login.php');
  final _sqlPayloadController = TextEditingController(text: "' OR '1'='1");
  final List<SqlInjectionResult> _sqlResults = [];
  bool _isInjecting = false;
  
  // Password Cracker State
  final _hashController = TextEditingController(text: '5f4dcc3b5aa765d61d8327deb882cf99');
  final List<String> _passwordList = ['password', '123456', 'admin', 'qwerty', 'letmein'];
  final List<CrackResult> _crackResults = [];
  bool _isCracking = false;
  int _currentPasswordIndex = 0;
  
  // Network Sniffer State
  final List<PacketData> _capturedPackets = [];
  bool _isSniffing = false;
  Timer? _snifferTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _snifferTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TdcColors.surface,
            border: Border(bottom: BorderSide(color: TdcColors.border)),
          ),
          child: Row(
            children: [
              Icon(Icons.security, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Laboratoire de Hacking Éthique',
                style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Text(
                  'MODE FORMATION',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: TdcColors.surfaceAlt.withOpacity(0.3),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.red.shade700,
            labelColor: Colors.red.shade700,
            unselectedLabelColor: TdcColors.textMuted,
            tabs: const [
              Tab(text: 'Nmap Scanner'),
              Tab(text: 'SQL Injection'),
              Tab(text: 'Password Cracker'),
              Tab(text: 'Network Sniffer'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildNmapTab(),
              _buildSqlInjectionTab(),
              _buildPasswordCrackerTab(),
              _buildNetworkSnifferTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNmapTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nmap Port Scanner',
                style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Simulation de scan de ports pour identifier les services ouverts sur un réseau.',
                style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetController,
                      style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Cible (IP ou réseau)',
                        prefixIcon: const Icon(Icons.lan, size: 18),
                        filled: true,
                        fillColor: TdcColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _startNmapScan,
                    icon: _isScanning 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.radar),
                    label: Text(_isScanning ? 'Scan en cours...' : 'Scanner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
              if (_isScanning) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _scanProgress, backgroundColor: TdcColors.surfaceAlt, valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade700)),
              ],
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TdcColors.border),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final result = _scanResults[index];
                return _buildScanResult(result);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanResult(ScanResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.isOpen ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.isOpen ? Icons.lock_open : Icons.lock,
                color: result.isOpen ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${result.ip}:${result.port}',
                style: TextStyle(
                  color: result.isOpen ? Colors.green : Colors.red,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                result.state,
                style: TextStyle(
                  color: result.isOpen ? Colors.green.shade300 : Colors.red.shade300,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (result.service.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Service: ${result.service} (${result.version})',
              style: const TextStyle(
                color: TdcColors.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
          if (result.osFingerprint.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'OS: ${result.osFingerprint}',
              style: const TextStyle(
                color: TdcColors.textMuted,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSqlInjectionTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SQL Injection Tester',
                style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Testez les vulnérabilités SQL injection sur des endpoints simulés.',
                style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sqlUrlController,
                      style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'URL cible',
                        prefixIcon: const Icon(Icons.link, size: 18),
                        filled: true,
                        fillColor: TdcColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sqlPayloadController,
                      style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Payload SQL',
                        prefixIcon: const Icon(Icons.code, size: 18),
                        filled: true,
                        fillColor: TdcColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isInjecting ? null : _testSqlInjection,
                    icon: _isInjecting 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.bug_report),
                    label: Text(_isInjecting ? 'Test...' : 'Tester'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TdcColors.border),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sqlResults.length,
              itemBuilder: (context, index) {
                final result = _sqlResults[index];
                return _buildSqlResult(result);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSqlResult(SqlInjectionResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.isVulnerable ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.isVulnerable ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.isVulnerable ? Icons.warning : Icons.security,
                color: result.isVulnerable ? Colors.orange : Colors.green,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                result.isVulnerable ? 'VULNÉRABLE' : 'SÉCURISÉ',
                style: TextStyle(
                  color: result.isVulnerable ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                result.statusCode.toString(),
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Payload: ${result.payload}',
            style: const TextStyle(
              color: TdcColors.textMuted,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          if (result.response.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Response: ${result.response}',
              style: const TextStyle(
                color: TdcColors.textSecondary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordCrackerTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Password Hash Cracker',
                style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cassage de mots de passe par force brute et dictionnaire.',
                style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hashController,
                      style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Hash MD5 à cracker',
                        prefixIcon: const Icon(Icons.vpn_key, size: 18),
                        filled: true,
                        fillColor: TdcColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isCracking ? null : _startPasswordCracking,
                    icon: _isCracking 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.lock_open),
                    label: Text(_isCracking ? 'Cassage...' : 'Cracker'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
              if (_isCracking) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Test: $_currentPasswordIndex/${_passwordList.length}',
                      style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _currentPasswordIndex / _passwordList.length,
                        backgroundColor: TdcColors.surfaceAlt,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade700),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TdcColors.border),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _crackResults.length,
              itemBuilder: (context, index) {
                final result = _crackResults[index];
                return _buildCrackResult(result);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCrackResult(CrackResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.isCracked ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.isCracked ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.isCracked ? Icons.check_circle : Icons.error,
                color: result.isCracked ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                result.isCracked ? 'CRACKÉ' : 'ÉCHEC',
                style: TextStyle(
                  color: result.isCracked ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (result.isCracked)
                Text(
                  '${result.attempts} tentatives',
                  style: const TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (result.isCracked) ...[
            const SizedBox(height: 8),
            Text(
              'Mot de passe: ${result.password}',
              style: const TextStyle(
                color: Colors.green,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Hash: ${result.hash}',
            style: const TextStyle(
              color: TdcColors.textMuted,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSnifferTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Network Packet Sniffer',
                style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Capture et analyse des paquets réseau en temps réel.',
                style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isSniffing ? _stopSniffing : _startSniffing,
                    icon: Icon(_isSniffing ? Icons.stop : Icons.play_arrow),
                    label: Text(_isSniffing ? 'Arrêter' : 'Commencer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSniffing ? Colors.red : Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _capturedPackets.clear()),
                    icon: const Icon(Icons.clear),
                    label: const Text('Vider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TdcColors.surfaceAlt,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TdcColors.border),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _capturedPackets.length,
              itemBuilder: (context, index) {
                final packet = _capturedPackets[index];
                return _buildPacketData(packet);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPacketData(PacketData packet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getPacketColor(packet.protocol).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getPacketColor(packet.protocol).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getPacketColor(packet.protocol),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                packet.protocol.toUpperCase(),
                style: TextStyle(
                  color: _getPacketColor(packet.protocol),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${packet.sourceIp}:${packet.sourcePort} → ${packet.destIp}:${packet.destPort}',
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '${packet.size} bytes',
                style: const TextStyle(
                  color: TdcColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          if (packet.payload.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              packet.payload,
              style: const TextStyle(
                color: TdcColors.textMuted,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPacketColor(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'tcp': return Colors.blue;
      case 'udp': return Colors.green;
      case 'http': return Colors.orange;
      case 'https': return Colors.purple;
      case 'dns': return Colors.red;
      default: return Colors.grey;
    }
  }

  // Simulation methods
  Future<void> _startNmapScan() async {
    setState(() {
      _isScanning = true;
      _scanResults.clear();
      _scanProgress = 0.0;
    });

    final target = _targetController.text;
    final random = Random();

    // Simuler scan progressif
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      final port = 20 + i;
      final isOpen = random.nextDouble() > 0.6;
      
      setState(() {
        _scanResults.add(ScanResult(
          ip: target.contains('/') ? '192.168.1.${100 + i}' : target,
          port: port,
          state: isOpen ? 'open' : 'closed',
          service: _getServiceForPort(port),
          version: isOpen ? 'v1.0.0' : '',
          isOpen: isOpen,
          osFingerprint: isOpen ? 'Linux 4.15' : '',
        ));
        _scanProgress = (i + 1) / 10;
      });
    }

    setState(() => _isScanning = false);
  }

  Future<void> _testSqlInjection() async {
    setState(() {
      _isInjecting = true;
      _sqlResults.clear();
    });

    final url = _sqlUrlController.text;
    final payload = _sqlPayloadController.text;
    final random = Random();

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final isVulnerable = payload.contains('OR') && random.nextDouble() > 0.3;
    
    setState(() {
      _sqlResults.add(SqlInjectionResult(
        url: url,
        payload: payload,
        isVulnerable: isVulnerable,
        statusCode: isVulnerable ? 200 : 401,
        response: isVulnerable 
            ? '{"success": true, "user": "admin", "token": "fake_jwt_token"}'
            : '{"error": "Invalid credentials"}',
      ));
      _isInjecting = false;
    });
  }

  Future<void> _startPasswordCracking() async {
    setState(() {
      _isCracking = true;
      _crackResults.clear();
      _currentPasswordIndex = 0;
    });

    final targetHash = _hashController.text;
    
    for (int i = 0; i < _passwordList.length; i++) {
      setState(() => _currentPasswordIndex = i + 1);
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;
      
      // Simuler hash MD5 (simplifié)
      final password = _passwordList[i];
      final computedHash = _generateMd5(password);
      final isCracked = computedHash == targetHash;
      
      setState(() {
        _crackResults.add(CrackResult(
          hash: targetHash,
          password: password,
          isCracked: isCracked,
          attempts: i + 1,
        ));
        
        if (isCracked) {
          _isCracking = false;
          return;
        }
      });
    }

    setState(() => _isCracking = false);
  }

  void _startSniffing() {
    setState(() => _isSniffing = true);
    
    _snifferTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!_isSniffing || !mounted) {
        timer.cancel();
        return;
      }
      
      final random = Random();
      final protocols = ['TCP', 'UDP', 'HTTP', 'DNS'];
      final protocol = protocols[random.nextInt(protocols.length)];
      
      setState(() {
        _capturedPackets.add(PacketData(
          protocol: protocol,
          sourceIp: '192.168.1.${10 + random.nextInt(100)}',
          sourcePort: 1000 + random.nextInt(60000),
          destIp: '8.8.8.8',
          destPort: _getPortForProtocol(protocol),
          size: 64 + random.nextInt(1400),
          payload: _generatePayload(protocol),
        ));
        
        // Garder seulement les 50 derniers paquets
        if (_capturedPackets.length > 50) {
          _capturedPackets.removeAt(0);
        }
      });
    });
  }

  void _stopSniffing() {
    setState(() => _isSniffing = false);
    _snifferTimer?.cancel();
  }

  String _getServiceForPort(int port) {
    switch (port) {
      case 21: return 'FTP';
      case 22: return 'SSH';
      case 23: return 'Telnet';
      case 25: return 'SMTP';
      case 53: return 'DNS';
      case 80: return 'HTTP';
      case 110: return 'POP3';
      case 143: return 'IMAP';
      case 443: return 'HTTPS';
      case 993: return 'IMAPS';
      case 995: return 'POP3S';
      default: return 'Unknown';
    }
  }

  int _getPortForProtocol(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'tcp': return 80;
      case 'udp': return 53;
      case 'http': return 80;
      case 'dns': return 53;
      default: return 80;
    }
  }

  String _generatePayload(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'http':
        return 'GET /index.html HTTP/1.1\\nHost: example.com';
      case 'dns':
        return 'Query: A example.com';
      case 'tcp':
        return 'SYN packet';
      case 'udp':
        return 'UDP datagram';
      default:
        return 'Raw data';
    }
  }

  String _generateMd5(String input) {
    // Simulation très basique de MD5 (pour la démo)
    return input.hashCode.abs().toRadixString(16).padLeft(32, '0');
  }
}

// Models
class ScanResult {
  final String ip;
  final int port;
  final String state;
  final String service;
  final String version;
  final bool isOpen;
  final String osFingerprint;

  const ScanResult({
    required this.ip,
    required this.port,
    required this.state,
    required this.service,
    required this.version,
    required this.isOpen,
    required this.osFingerprint,
  });
}

class SqlInjectionResult {
  final String url;
  final String payload;
  final bool isVulnerable;
  final int statusCode;
  final String response;

  const SqlInjectionResult({
    required this.url,
    required this.payload,
    required this.isVulnerable,
    required this.statusCode,
    required this.response,
  });
}

class CrackResult {
  final String hash;
  final String password;
  final bool isCracked;
  final int attempts;

  const CrackResult({
    required this.hash,
    required this.password,
    required this.isCracked,
    required this.attempts,
  });
}

class PacketData {
  final String protocol;
  final String sourceIp;
  final int sourcePort;
  final String destIp;
  final int destPort;
  final int size;
  final String payload;

  const PacketData({
    required this.protocol,
    required this.sourceIp,
    required this.sourcePort,
    required this.destIp,
    required this.destPort,
    required this.size,
    required this.payload,
  });
}
