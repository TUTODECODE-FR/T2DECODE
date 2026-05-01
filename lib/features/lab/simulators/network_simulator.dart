// ============================================================
// Network Simulator - Simulation réseau ultra-professionnelle
// ============================================================
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<PingResult> _pingResults = [];
  List<TraceHop> _traceHops = [];
  List<CapturedPacket> _capturedPackets = [];
  
  // Métriques réseau
  double _bandwidthUsage = 0.0;
  int _packetLoss = 0;
  int _latency = 0;
  int _totalPackets = 0;
  
  late AnimationController _scanController;
  late AnimationController _packetController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
      decoration: BoxDecoration(
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
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: Row(
                    children: [
                      Expanded(
                        child: LabMetricCard(
                          title: 'Bande Passante',
                          value: '${_bandwidthUsage.toStringAsFixed(1)} Mbps',
                          icon: Icons.speed,
                          color: TdcColors.network,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabMetricCard(
                          title: 'Latence',
                          value: '${_latency} ms',
                          icon: Icons.timer,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabMetricCard(
                          title: 'Perte Paquets',
                          value: '$_packetLoss%',
                          icon: Icons.warning,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabMetricCard(
                          title: 'Paquets Total',
                          value: '$_totalPackets',
                          icon: Icons.data_usage,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
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
              unselectedLabelColor: Colors.white.withOpacity(0.4),
              isScrollable: true,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'SCAN RÉSEAU'),
                Tab(text: 'PING'),
                Tab(text: 'TRACEROUTE'),
                Tab(text: 'SNIFFER'),
                Tab(text: '🤖 IA'),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Colors.white10),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNetworkScanTab(),
                _buildPingTab(),
                _buildTracerouteTab(),
                _buildSnifferTab(),
                const SimulatorAIAssistant(
                  topic: 'Réseau & Protocoles',
                  accentColor: TdcColors.network,
                  systemPrompt:
                      'Tu es un expert réseau (CCNA/CEH niveau). Réponds en français, de façon concise et pédagogique. '
                      'Domaines couverts : scan réseau, ICMP/ping, traceroute, capture de paquets, protocoles TCP/IP/UDP, '
                      'VLAN, routage, pare-feu, sous-réseaux CIDR. Donne des exemples pratiques avec des commandes usuelles (sans exécution).',
                  suggestedQuestions: [
                    'Comment fonctionne un scan SYN ?',
                    'Différence TCP vs UDP ?',
                    'Qu\'est-ce qu\'un TTL ?',
                    'Comment lire une capture Wireshark ?',
                    'Expliquer le 3-way handshake',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkScanTab() {
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
                          controller: _ipController,
                          decoration: const InputDecoration(
                            labelText: 'Plage IP (ex: 192.168.1.0/24)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lan),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isScanning ? null : _performNetworkScan,
                        icon: _isScanning 
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isScanning ? 'Scan...' : 'Scanner'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TdcColors.network,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _portController,
                          decoration: const InputDecoration(
                            labelText: 'Ports (ex: 22,80,443)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.settings_ethernet),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: 'syn',
                        items: const [
                          DropdownMenuItem(value: 'syn', child: Text('SYN Scan')),
                          DropdownMenuItem(value: 'tcp', child: Text('TCP Connect')),
                          DropdownMenuItem(value: 'udp', child: Text('UDP Scan')),
                        ],
                        onChanged: (value) {},
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
                        Icon(Icons.devices, color: TdcColors.network, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Appareils Découverts',
                          style: TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_discoveredDevices.length} appareils',
                          style: const TextStyle(
                            color: TdcColors.textSecondary,
                            fontSize: 12,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
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
              const SizedBox(width: 8),
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
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TdcColors.network.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TdcColors.network.withOpacity(0.3)),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                device.os,
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              const Text(
                'Ports ouverts: ',
                style: TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              ...device.openPorts.map((port) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: TdcColors.network.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$port',
                    style: const TextStyle(
                      color: TdcColors.network,
                      fontSize: 10,
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
                          controller: _ipController,
                          decoration: const InputDecoration(
                            labelText: 'Adresse IP ou domaine',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lan),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isPinging ? null : _performPing,
                        icon: _isPinging 
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isPinging ? 'Ping...' : 'Ping'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TdcColors.network,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPingOption('Nombre de paquets', '4'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPingOption('Taille (bytes)', '64'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Résultats Ping
          Expanded(
            child: Card(
              color: TdcColors.surface,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'Résultats Ping',
                      style: TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  Widget _buildPingOption(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TdcColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPingResultCard(PingResult result) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.success 
            ? TdcColors.system.withOpacity(0.1)
            : TdcColors.security.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.success 
              ? TdcColors.system.withOpacity(0.3)
              : TdcColors.security.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            result.success ? Icons.check_circle : Icons.error,
            color: result.success ? TdcColors.system : TdcColors.security,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.sequence.toString(),
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${result.bytes} bytes from ${result.target}',
                  style: const TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'time=${result.time}ms',
            style: TextStyle(
              color: result.success ? TdcColors.system : TdcColors.security,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'TTL=${result.ttl}',
            style: const TextStyle(
              color: TdcColors.textSecondary,
              fontSize: 11,
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
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _domainController,
                      decoration: const InputDecoration(
                        labelText: 'Domaine ou IP',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isTracing ? null : _performTraceroute,
                    icon: _isTracing 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.route),
                    label: Text(_isTracing ? 'Trace...' : 'Traceroute'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TdcColors.network,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Résultats Traceroute
          Expanded(
            child: Card(
              color: TdcColors.surface,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'Chemin de Routage',
                      style: TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TdcColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: TdcColors.network,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${hop.hop}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hop.hostname,
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  hop.ip,
                  style: const TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: hop.times.map((time) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: time < 50 
                      ? TdcColors.system.withOpacity(0.1)
                      : time < 100 
                          ? TdcColors.crypto.withOpacity(0.1)
                          : TdcColors.security.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${time}ms',
                  style: TextStyle(
                    color: time < 50 
                        ? TdcColors.system
                        : time < 100 
                            ? TdcColors.crypto
                            : TdcColors.security,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )).toList(),
          ),
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
                              child: DropdownButton<String>(
                                value: 'eth0',
                                items: const [
                                  DropdownMenuItem(value: 'eth0', child: Text('eth0 - Ethernet')),
                                  DropdownMenuItem(value: 'wlan0', child: Text('wlan0 - WiFi')),
                                  DropdownMenuItem(value: 'lo', child: Text('lo - Local')),
                                ],
                                onChanged: (value) {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButton<String>(
                                value: 'tcp',
                                items: const [
                                  DropdownMenuItem(value: 'tcp', child: Text('TCP')),
                                  DropdownMenuItem(value: 'udp', child: Text('UDP')),
                                  DropdownMenuItem(value: 'icmp', child: Text('ICMP')),
                                  DropdownMenuItem(value: 'all', child: Text('All')),
                                ],
                                onChanged: (value) {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Filtre (ex: port 80)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.filter_list),
                                ),
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
                        onPressed: _isSniffing ? _stopSniffing : _startSniffing,
                        icon: Icon(_isSniffing ? Icons.stop : Icons.play_arrow),
                        label: Text(_isSniffing ? 'Arrêter' : 'Capturer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSniffing ? TdcColors.security : TdcColors.network,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _clearPackets,
                        icon: const Icon(Icons.clear),
                        label: const Text('Vider'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TdcColors.border,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statistiques de capture
          Row(
            children: [
              Expanded(
                child: Card(
                  color: TdcColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          '${_capturedPackets.length}',
                          style: const TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Paquets capturés',
                          style: TextStyle(
                            color: TdcColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  color: TdcColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          '$_totalPackets',
                          style: const TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Total paquets',
                          style: TextStyle(
                            color: TdcColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  color: TdcColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          '${_bandwidthUsage.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Mbps',
                          style: TextStyle(
                            color: TdcColors.textSecondary,
                            fontSize: 12,
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
          
          // Paquets capturés
          Expanded(
            child: Card(
              color: TdcColors.surface,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.compare_arrows, color: TdcColors.network),
                        const SizedBox(width: 8),
                        const Text(
                          'Paquets Capturés',
                          style: TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isSniffing)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: TdcColors.security.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: TdcColors.security.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'CAPTURE EN COURS',
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getProtocolColor(packet.protocol).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getProtocolColor(packet.protocol).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getProtocolColor(packet.protocol),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  packet.protocol.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${packet.sourceIp}:${packet.sourcePort} → ${packet.destIp}:${packet.destPort}',
                style: const TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${packet.size} bytes',
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            packet.timestamp,
            style: const TextStyle(
              color: TdcColors.textSecondary,
              fontSize: 10,
            ),
          ),
          if (packet.info.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              packet.info,
              style: const TextStyle(
                color: TdcColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Méthodes de simulation
  Future<void> _performNetworkScan() async {
    setState(() => _isScanning = true);
    _scanController.repeat();
    
    // Simuler un scan réseau
    await Future.delayed(const Duration(seconds: 3));
    
    final newDevices = [
      NetworkDevice(
        ip: '192.168.1.50',
        mac: 'AA:BB:CC:DD:EE:AA',
        hostname: 'desktop-01',
        type: 'Desktop',
        os: 'Windows 11 Pro',
        openPorts: [22, 80, 443, 3389],
        responseTime: 8,
      ),
      NetworkDevice(
        ip: '192.168.1.200',
        mac: 'AA:BB:CC:DD:EE:BB',
        hostname: 'nas-01',
        type: 'NAS',
        os: 'Synology DSM',
        openPorts: [22, 80, 443, 5000, 5001],
        responseTime: 12,
      ),
    ];
    
    setState(() {
      _isScanning = false;
      _discoveredDevices.addAll(newDevices);
    });
    _scanController.stop();
  }

  Future<void> _performPing() async {
    setState(() => _isPinging = true);
    
    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final result = PingResult(
        sequence: i + 1,
        target: _ipController.text.isEmpty ? '8.8.8.8' : _ipController.text,
        bytes: 64,
        time: Random().nextInt(50) + 10,
        ttl: 64,
        success: true,
      );
      
      setState(() {
        _pingResults.add(result);
      });
    }
    
    setState(() => _isPinging = false);
  }

  Future<void> _performTraceroute() async {
    setState(() => _isTracing = true);
    
    final hops = [
      TraceHop(hop: 1, hostname: 'router.local', ip: '192.168.1.1', times: [2, 2, 3]),
      TraceHop(hop: 2, hostname: 'gw-isp.local', ip: '85.10.20.1', times: [15, 16, 14]),
      TraceHop(hop: 3, hostname: 'core-isp.local', ip: '85.10.30.1', times: [18, 19, 17]),
      TraceHop(hop: 4, hostname: 'peering-1.local', ip: '80.90.100.1', times: [25, 26, 24]),
      TraceHop(hop: 5, hostname: 'google-server', ip: '142.250.179.100', times: [35, 36, 34]),
    ];
    
    for (final hop in hops) {
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _traceHops.add(hop);
      });
    }
    
    setState(() => _isTracing = false);
  }

  Future<void> _startSniffing() async {
    setState(() => _isSniffing = true);
    
    // Simuler la capture de paquets
    while (_isSniffing) {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final packet = CapturedPacket(
        timestamp: DateTime.now().toIso8601String(),
        sourceIp: '192.168.1.${Random().nextInt(254) + 1}',
        sourcePort: Random().nextInt(65535),
        destIp: '8.8.8.8',
        destPort: 53,
        protocol: ['tcp', 'udp', 'icmp'][Random().nextInt(3)],
        size: Random().nextInt(1400) + 64,
        info: 'DNS Query',
      );
      
      setState(() {
        _capturedPackets.insert(0, packet);
        if (_capturedPackets.length > 100) {
          _capturedPackets.removeLast();
        }
        _totalPackets++;
        _bandwidthUsage = (_bandwidthUsage * 0.9) + (Random().nextDouble() * 10);
      });
    }
  }

  void _stopSniffing() {
    setState(() => _isSniffing = false);
  }

  void _clearPackets() {
    setState(() {
      _capturedPackets.clear();
      _totalPackets = 0;
      _bandwidthUsage = 0.0;
    });
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'Router': return Icons.router;
      case 'Server': return Icons.dns;
      case 'Desktop': return Icons.computer;
      case 'Mobile': return Icons.smartphone;
      case 'NAS': return Icons.storage;
      default: return Icons.device_hub;
    }
  }

  Color _getProtocolColor(String protocol) {
    switch (protocol) {
      case 'tcp': return TdcColors.network;
      case 'udp': return TdcColors.system;
      case 'icmp': return TdcColors.crypto;
      default: return TdcColors.border;
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
