// ignore_for_file: unused_element
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// Network Simulator - Simulation réseau ultra-professionnelle
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import '../widgets/lab_widgets.dart';
import '../widgets/simulator_ai_assistant.dart';

class NetworkSimulator extends StatefulWidget {
  const NetworkSimulator({super.key});

  @override
  State<NetworkSimulator> createState() => _NetworkSimulatorState();
}

class _NetworkSimulatorState extends State<NetworkSimulator>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  
  // États des simulations
  bool _isScanning = false;
  bool _isPinging = false;
  bool _isTracing = false;
  bool _isSniffing = false;
  
  // Données de simulation
  List<NetworkDevice> _discoveredDevices = [];
  final List<PingResult> _pingResults = [];
  final List<TraceHop> _traceHops = [];
  final List<CapturedPacket> _capturedPackets = [];
  
  // Métriques réseau
  double _bandwidthUsage = 0.0;
  final int _packetLoss = 0;
  int _latency = 0;
  int _totalPackets = 0;
  
  late AnimationController _scanController;
  late AnimationController _packetController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _scanController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _packetController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    
    _initializeNetworkData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scanController.dispose();
    _packetController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  void _initializeNetworkData() {
    // Initialiser avec des données d'exemple
    _discoveredDevices = [
      NetworkDevice(
        ip: '192.168.1.1',
        mac: 'AA:BB:CC:DD:EE:FF',
        hostname: 'router.local',
        type: 'Router',
        os: 'OpenWrt 19.07',
        openPorts: [22, 80, 443],
        responseTime: 2,
      ),
      NetworkDevice(
        ip: '192.168.1.100',
        mac: '11:22:33:44:55:66',
        hostname: 'server-01',
        type: 'Server',
        os: 'Ubuntu 22.04 LTS',
        openPorts: [22, 80, 443, 3306, 5432],
        responseTime: 5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          // Header avec métriques simulées
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const LabNotice(
                  title: 'Simulation pédagogique',
                  message:
                      'Données synthétiques. Aucun scan réseau réel ni capture de paquets.',
                  icon: Icons.info_outline,
                ),
              ],
            ),
          ),
          // Custom TabBar inside Lab
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              indicatorColor: TdcColors.network,
              labelColor: TdcColors.network,
              unselectedLabelColor: TdcColors.textMuted,
              isScrollable: true,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.1),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'SCAN RÉSEAU'),
                Tab(text: 'PING'),
                Tab(text: 'TRACEROUTE'),
                Tab(text: 'SNIFFER'),
                Tab(text: 'GUIDE'),
                Tab(text: '🤖 IA'),
              ],
            ),
          ),
          
          const Divider(height: 1, color: TdcColors.border),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNetworkScanTab(),
                _buildPingTab(),
                _buildTracerouteTab(),
                _buildSnifferTab(),
                _buildGuideTab(),
                const SimulatorAIAssistant(
                  topic: 'Réseau & Architecture',
                  accentColor: TdcColors.network,
                  systemPrompt:
                      'Tu es Ghost, l\'expert réseau de T2DECODE. Ta mission est d\'aider à comprendre les paquets et les câbles. '
                      'Sois ultra-sympa, utilise des métaphores (comme comparer un paquet à une lettre), et ne sois pas sec. '
                      'Tu maîtrises les 7 couches de l\'informatique (Hardware > Kernel > Drivers > OS > Libs > Software > App) '
                      'ainsi que le modèle OSI (7 couches aussi). '
                      'Expertise : TCP/IP, UDP, ICMP (Ping), DNS, Scans SYN/ACK, reniflage (sniffing) et sécurité réseau.',
                  suggestedQuestions: [
                    'Explique-moi les 7 couches de l\'informatique ?',
                    'Un mémo pour retenir les couches informatiques ?',
                    'Différence entre TCP et UDP ?',
                    'C\'est quoi exactement le Kernel ?',
                    'À quoi sert le TTL dans un paquet ?',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildGuideSection(
          'Scan Réseau',
          'Le scan réseau permet de découvrir les hôtes actifs et les services ouverts sur un segment. '
          'Il utilise des techniques comme le SYN Scan (half-open) pour rester discret ou le TCP Connect pour confirmer l\'ouverture d\'un port.',
          Icons.search,
        ),
        const SizedBox(height: 24),
        _buildGuideSection(
          'ICMP & Ping',
          'Le protocole ICMP (Internet Control Message Protocol) est utilisé par la commande ping pour vérifier la connectivité. '
          'Il mesure le temps aller-retour (RTT) et rapporte d\'éventuelles pertes de paquets.',
          Icons.send,
        ),
        const SizedBox(height: 24),
        _buildGuideSection(
          'Traceroute',
          'Traceroute identifie chaque saut (hop) entre vous et une destination en incrémentant le TTL (Time To Live) de chaque paquet. '
          'Chaque routeur sur le chemin renvoie un message ICMP Time Exceeded, révélant son identité.',
          Icons.route,
        ),
        const SizedBox(height: 24),
        _buildGuideSection(
          'Packet Sniffing',
          'Le "sniffing" consiste à capturer les paquets bruts circulant sur une interface. '
          'Cela permet d\'analyser les flux, de déboguer des applications ou d\'identifier des trafics suspects.',
          Icons.compare_arrows,
        ),
      ],
    );
  }

  Widget _buildGuideSection(String title, String description, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: TdcColors.network, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(
            color: TdcColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: TdcColors.border),
      ],
    );
  }

  Widget _buildNetworkScanTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contrôles de scan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TdcColors.surfaceAlt,
              border: Border.all(color: TdcColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuration du Scan',
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ipController,
                        style: const TextStyle(color: TdcColors.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Plage IP (ex: 192.168.1.0/24)',
                          prefixIcon: Icon(Icons.lan, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : _performNetworkScan,
                      icon: _isScanning 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.search, size: 18),
                      label: Text(_isScanning ? 'Scan...' : 'Scanner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TdcColors.network,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Résultats du scan
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: TdcColors.bg,
                border: Border.all(color: TdcColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: TdcColors.border)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.devices, color: TdcColors.network, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Appareils Découverts',
                          style: TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_discoveredDevices.length} appareils',
                          style: const TextStyle(
                            color: TdcColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final device = _discoveredDevices[index];
                        return _buildDeviceCard(device);
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

  Widget _buildDeviceCard(NetworkDevice device) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getDeviceIcon(device.type),
                color: TdcColors.network,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.hostname,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${device.ip} • ${device.mac}',
                      style: const TextStyle(
                        color: TdcColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: TdcColors.network.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${device.responseTime}ms',
                  style: const TextStyle(
                    color: TdcColors.network,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                device.os,
                style: const TextStyle(
                  color: TdcColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              ...device.openPorts.map((port) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: TdcColors.network.withValues(alpha: 0.1),
                    border: Border.all(color: TdcColors.network.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '$port',
                    style: const TextStyle(
                      color: TdcColors.network,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPingTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contrôles Ping
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TdcColors.surfaceAlt,
              border: Border.all(color: TdcColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    style: const TextStyle(color: TdcColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Adresse IP ou domaine',
                      prefixIcon: Icon(Icons.lan, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isPinging ? null : _performPing,
                  icon: _isPinging 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(_isPinging ? 'Ping...' : 'Ping'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TdcColors.network,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Résultats Ping
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: TdcColors.bg,
                border: Border.all(color: TdcColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: TdcColors.border)),
                    ),
                    child: const Text(
                      'RÉPONSES ICMP',
                      style: TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _pingResults.length,
                      itemBuilder: (context, index) {
                        final result = _pingResults[index];
                        return _buildPingResultCard(result);
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

  Widget _buildPingResultCard(PingResult result) {
    final statusColor = result.success ? TdcColors.success : TdcColors.danger;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            result.success ? Icons.check_circle_outline : Icons.error_outline,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${result.bytes} bytes from ${result.target}: icmp_seq=${result.sequence} ttl=${result.ttl} time=${result.time}ms',
              style: const TextStyle(
                color: TdcColors.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracerouteTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contrôles Traceroute
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TdcColors.surfaceAlt,
              border: Border.all(color: TdcColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _domainController,
                    style: const TextStyle(color: TdcColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Domaine ou IP',
                      prefixIcon: Icon(Icons.language, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isTracing ? null : _performTraceroute,
                  icon: _isTracing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.route, size: 18),
                  label: Text(_isTracing ? 'Trace...' : 'Traceroute'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TdcColors.network,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Résultats Traceroute
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: TdcColors.bg,
                border: Border.all(color: TdcColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: TdcColors.border)),
                    ),
                    child: const Text(
                      'PARCOURS RÉSEAU',
                      style: TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _traceHops.length,
                      itemBuilder: (context, index) {
                        final hop = _traceHops[index];
                        return _buildHopCard(hop, index);
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

  Widget _buildHopCard(TraceHop hop, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        border: Border.all(color: TdcColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: TdcColors.network),
            ),
            child: Center(
              child: Text(
                '${hop.hop}',
                style: const TextStyle(
                  color: TdcColors.network,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hop.hostname,
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  hop.ip,
                  style: const TextStyle(
                    color: TdcColors.textMuted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          ...hop.times.map((time) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '${time}ms',
              style: TextStyle(
                color: time < 50 ? TdcColors.success : TdcColors.warning,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSnifferTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contrôles Sniffer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TdcColors.surfaceAlt,
              border: Border.all(color: TdcColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: 'eth0',
                          isExpanded: true,
                          dropdownColor: TdcColors.surfaceAlt,
                          style: const TextStyle(color: TdcColors.textPrimary, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: 'eth0', child: Text('Interface eth0')),
                            DropdownMenuItem(value: 'wlan0', child: Text('Interface wlan0')),
                            DropdownMenuItem(value: 'lo', child: Text('Interface lo')),
                          ],
                          onChanged: (value) {},
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSniffing ? _stopSniffing : _startSniffing,
                      icon: Icon(_isSniffing ? Icons.stop : Icons.play_arrow, size: 18),
                      label: Text(_isSniffing ? 'Arrêter' : 'Démarrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSniffing ? TdcColors.danger : TdcColors.network,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Paquets capturés
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: TdcColors.bg,
                border: Border.all(color: TdcColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: TdcColors.border)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: TdcColors.network, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'FLUX DE PAQUETS',
                          style: TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        if (_isSniffing)
                          const Text(
                            'CAPTURE ACTIVE',
                            style: TextStyle(
                              color: TdcColors.success,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate(onPlay: (c) => c.repeat()).fadeIn().fadeOut(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _capturedPackets.length,
                      itemBuilder: (context, index) {
                        final packet = _capturedPackets[index];
                        return _buildPacketCard(packet);
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

  Widget _buildPacketCard(CapturedPacket packet) {
    final protoColor = _getProtocolColor(packet.protocol);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt.withValues(alpha: 0.5),
        border: Border(left: BorderSide(color: protoColor, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                packet.protocol.toUpperCase(),
                style: TextStyle(
                  color: protoColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${packet.sourceIp}:${packet.sourcePort} → ${packet.destIp}:${packet.destPort}',
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${packet.size}b',
                style: const TextStyle(color: TdcColors.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${packet.timestamp.substring(11, 19)} | ${packet.info}',
            style: const TextStyle(
              color: TdcColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes de simulation améliorées
  Future<void> _performNetworkScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
    final scanResults = [
      NetworkDevice(
        ip: '192.168.1.1',
        mac: '00:11:22:33:44:55',
        hostname: 'Gateway',
        type: 'Router',
        os: 'Tdc-OS/Core',
        openPorts: [80, 443, 53],
        responseTime: 1,
      ),
      NetworkDevice(
        ip: '192.168.1.12',
        mac: 'AA:BB:CC:DD:EE:FF',
        hostname: 'Dev-Station',
        type: 'Desktop',
        os: 'Linux 6.x',
        openPorts: [22, 3000, 8080],
        responseTime: 4,
      ),
      NetworkDevice(
        ip: '192.168.1.25',
        mac: 'FF:EE:DD:CC:BB:AA',
        hostname: 'Main-Server',
        type: 'Server',
        os: 'Ubuntu 22.04',
        openPorts: [22, 443, 3306],
        responseTime: 2,
      ),
    ];

    for (var device in scanResults) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _discoveredDevices.add(device);
      });
    }
    
    setState(() => _isScanning = false);
  }

  Future<void> _performPing() async {
    if (_isPinging) return;
    setState(() {
      _isPinging = true;
      _pingResults.clear();
    });
    
    final target = _ipController.text.isEmpty ? '127.0.0.1' : _ipController.text;

    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      
      final result = PingResult(
        sequence: i + 1,
        target: target,
        bytes: 64,
        time: 5 + (i * 2) + (i % 2 == 0 ? 1 : 0),
        ttl: 64,
        success: true,
      );
      
      setState(() {
        _pingResults.add(result);
        _latency = result.time;
      });
    }
    
    setState(() => _isPinging = false);
  }

  Future<void> _performTraceroute() async {
    if (_isTracing) return;
    setState(() {
      _isTracing = true;
      _traceHops.clear();
    });
    
    final hops = [
      TraceHop(hop: 1, hostname: 'gateway', ip: '192.168.1.1', times: [1, 1, 2]),
      TraceHop(hop: 2, hostname: 'isp-gw', ip: '10.20.30.1', times: [12, 14, 11]),
      TraceHop(hop: 3, hostname: 'backbone-core', ip: '80.50.60.2', times: [22, 25, 21]),
      TraceHop(hop: 4, hostname: 'target-node', ip: '1.2.3.4', times: [35, 38, 34]),
    ];
    
    for (var hop in hops) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      setState(() {
        _traceHops.add(hop);
      });
    }
    
    setState(() => _isTracing = false);
  }

  Future<void> _startSniffing() async {
    if (_isSniffing) return;
    setState(() => _isSniffing = true);
    
    while (_isSniffing) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) break;
      
      final protocols = ['tcp', 'udp', 'icmp'];
      final proto = protocols[DateTime.now().millisecond % 3];
      
      final packet = CapturedPacket(
        timestamp: DateTime.now().toIso8601String(),
        sourceIp: '192.168.1.${10 + (DateTime.now().second % 20)}',
        sourcePort: 1024 + (DateTime.now().millisecond % 5000),
        destIp: '1.1.1.1',
        destPort: proto == 'udp' ? 53 : 443,
        protocol: proto,
        size: 40 + (DateTime.now().millisecond % 1000),
        info: proto == 'icmp' ? 'Echo Request' : (proto == 'udp' ? 'DNS Query' : 'TLS Handshake'),
      );
      
      setState(() {
        _capturedPackets.insert(0, packet);
        if (_capturedPackets.length > 50) _capturedPackets.removeLast();
        _totalPackets++;
        _bandwidthUsage = 0.5 + (DateTime.now().second % 5) / 2.0;
      });
    }
  }

  void _stopSniffing() => setState(() => _isSniffing = false);
  void _clearPackets() => setState(() => _capturedPackets.clear());

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'Router': return Icons.router;
      case 'Server': return Icons.dns;
      case 'Desktop': return Icons.computer;
      default: return Icons.device_hub;
    }
  }

  Color _getProtocolColor(String protocol) {
    switch (protocol) {
      case 'tcp': return TdcColors.network;
      case 'udp': return TdcColors.system;
      case 'icmp': return TdcColors.crypto;
      default: return TdcColors.textMuted;
    }
  }
}

// Modèles de données
class NetworkDevice {
  final String ip;
  final String mac;
  final String hostname;
  final String type;
  final String os;
  final List<int> openPorts;
  final int responseTime;

  NetworkDevice({
    required this.ip,
    required this.mac,
    required this.hostname,
    required this.type,
    required this.os,
    required this.openPorts,
    required this.responseTime,
  });
}

class PingResult {
  final int sequence;
  final String target;
  final int bytes;
  final int time;
  final int ttl;
  final bool success;

  PingResult({
    required this.sequence,
    required this.target,
    required this.bytes,
    required this.time,
    required this.ttl,
    required this.success,
  });
}

class TraceHop {
  final int hop;
  final String hostname;
  final String ip;
  final List<int> times;

  TraceHop({
    required this.hop,
    required this.hostname,
    required this.ip,
    required this.times,
  });
}

class CapturedPacket {
  final String timestamp;
  final String sourceIp;
  final int sourcePort;
  final String destIp;
  final int destPort;
  final String protocol;
  final int size;
  final String info;

  CapturedPacket({
    required this.timestamp,
    required this.sourceIp,
    required this.sourcePort,
    required this.destIp,
    required this.destPort,
    required this.protocol,
    required this.size,
    required this.info,
  });
}
