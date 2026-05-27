// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// System Simulator - Simulation système ultra-professionnelle
// ============================================================
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/lab/widgets/lab_widgets.dart';
import 'package:tutodecode/features/lab/widgets/simulator_ai_assistant.dart';

class SystemSimulator extends StatefulWidget {
  const SystemSimulator({super.key});

  @override
  State<SystemSimulator> createState() => _SystemSimulatorState();
}

class _SystemSimulatorState extends State<SystemSimulator>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _performanceController;
  
  // Données système
  List<SystemProcess> _processes = [];
  List<DiskPartition> _partitions = [];
  List<SystemService> _services = [];
  
  // Métriques simulées
  double _cpuUsage = 0.0;
  double _memoryUsage = 0.0;
  double _diskUsage = 0.0;
  double _networkUsage = 0.0;
  double _temperature = 45.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _performanceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    
    _initializeSystemData();
    _startRealTimeMonitoring();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _performanceController.dispose();
    super.dispose();
  }

  void _initializeSystemData() {
    // Initialiser avec des données d'exemple
    _processes = [
      SystemProcess(
        pid: 1,
        name: 'systemd',
        user: 'root',
        cpu: 0.1,
        memory: 2.5,
        status: 'Running',
        startTime: DateTime.now().subtract(const Duration(hours: 24)),
      ),
      SystemProcess(
        pid: 1234,
        name: 'chrome',
        user: 'user',
        cpu: 15.2,
        memory: 25.8,
        status: 'Running',
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SystemProcess(
        pid: 5678,
        name: 'docker',
        user: 'root',
        cpu: 8.7,
        memory: 12.3,
        status: 'Running',
        startTime: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
    
    _partitions = [
      DiskPartition(
        device: '/dev/sda1',
        mountPoint: '/',
        size: 500000, // MB
        used: 250000,
        available: 250000,
        filesystem: 'ext4',
      ),
      DiskPartition(
        device: '/dev/sda2',
        mountPoint: '/home',
        size: 1000000, // MB
        used: 450000,
        available: 550000,
        filesystem: 'ext4',
      ),
    ];
    
    _services = [
      SystemService(
        name: 'nginx',
        status: 'Active',
        enabled: true,
        description: 'High performance web server',
        loadedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      SystemService(
        name: 'mysql',
        status: 'Active',
        enabled: true,
        description: 'MySQL database server',
        loadedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      SystemService(
        name: 'docker',
        status: 'Active',
        enabled: true,
        description: 'Docker container runtime',
        loadedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  void _startRealTimeMonitoring() {
    // Simuler les métriques
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _cpuUsage = (Random().nextDouble() * 30 + 10).clamp(0.0, 100.0);
          _memoryUsage = (Random().nextDouble() * 20 + 60).clamp(0.0, 100.0);
          _diskUsage = (Random().nextDouble() * 5 + 45).clamp(0.0, 100.0);
          _networkUsage = (Random().nextDouble() * 100).clamp(0.0, 100.0);
          _temperature = (Random().nextDouble() * 20 + 40).clamp(30.0, 85.0);
        });
        _startRealTimeMonitoring();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header avec métriques système
        LabGlassContainer(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.computer, color: TdcColors.system, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'MONITORING SYSTÈME AVANCÉ',
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
                      color: TdcColors.system.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TdcColors.system.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: TdcColors.system,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'MODE DÉMO',
                          style: TextStyle(
                            color: TdcColors.system,
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
                    'Données synthétiques. Aucun accès aux processus réels de la machine.',
                icon: Icons.info_outline,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LabMetricCard(
                      title: 'CPU',
                      value: '${_cpuUsage.toStringAsFixed(1)}%',
                      icon: Icons.memory,
                      color: _getMetricColor('${_cpuUsage.toStringAsFixed(1)}%'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabMetricCard(
                      title: 'RAM',
                      value: '${_memoryUsage.toStringAsFixed(1)}%',
                      icon: Icons.sd_storage,
                      color: _getMetricColor('${_memoryUsage.toStringAsFixed(1)}%'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabMetricCard(
                      title: 'Disque',
                      value: '${_diskUsage.toStringAsFixed(1)}%',
                      icon: Icons.storage,
                      color: _getMetricColor('${_diskUsage.toStringAsFixed(1)}%'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabMetricCard(
                      title: 'Réseau',
                      value: '${_networkUsage.toStringAsFixed(1)}M',
                      icon: Icons.network_check,
                      color: TdcColors.network,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabMetricCard(
                      title: 'Temp',
                      value: '${_temperature.toStringAsFixed(1)}°C',
                      icon: Icons.thermostat,
                      color: _temperature > 70 ? TdcColors.danger : TdcColors.warning,
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
            indicatorColor: TdcColors.system,
            labelColor: TdcColors.system,
            unselectedLabelColor: TdcColors.textMuted,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Processus'),
              Tab(text: 'Services'),
              Tab(text: 'Disques'),
              Tab(text: 'Applications'),
              Tab(text: '🤖 IA'),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProcessesTab(),
              _buildServicesTab(),
              _buildDisksTab(),
              _buildApplicationsTab(),
              const SimulatorAIAssistant(
                topic: 'Système & Architecture',
                accentColor: TdcColors.system,
                systemPrompt:
                    'Tu es Ghost, l\'expert T2DECODE spécialisé en architecture PC et OS. '
                    'Ton but est d\'expliquer comment la magie opère entre le silicium et l\'écran. '
                    'Sois pédagogue, sympa et utilise des analogies concrètes. Ne sois pas sec. '
                    'Expertise : Les 7 couches informatiques (Hardware, Kernel, Drivers, OS, Libs, Software, App), '
                    'ordonnancement CPU, gestion mémoire (MMU/Swap), services systemd, VFS et monitoring.',
                suggestedQuestions: [
                  'Explique les 7 couches de l\'informatique ?',
                  'Comment retenir ces couches facilement ?',
                  'C\'est quoi exactement le Kernel ?',
                  'Comment le CPU gère plusieurs tâches ?',
                  'Pourquoi mon PC chauffe quand je compile ?',
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }


  Color _getMetricColor(String value) {
    final numericValue = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    if (numericValue > 80) return TdcColors.security;
    if (numericValue > 60) return TdcColors.crypto;
    return TdcColors.system;
  }

  Widget _buildProcessesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contrôles des processus
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Filtrer les processus',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _refreshProcesses,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualiser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TdcColors.system,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Liste des processus
          Expanded(
            child: Card(
              color: TdcColors.surface,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.list, color: TdcColors.system),
                        const SizedBox(width: 8),
                        const Text(
                          'Processus Actifs',
                          style: TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_processes.length} processus',
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
                      itemCount: _processes.length,
                      itemBuilder: (context, index) {
                        final process = _processes[index];
                        return _buildProcessCard(process);
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

  Widget _buildProcessCard(SystemProcess process) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt.withOpacity(0.5),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: TdcColors.system,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '${process.pid}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
                      process.name,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Utilisateur: ${process.user}',
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
                  color: process.status == 'Running' 
                      ? TdcColors.system.withOpacity(0.1)
                      : TdcColors.security.withOpacity(0.1),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: process.status == 'Running' 
                        ? TdcColors.system.withOpacity(0.3)
                        : TdcColors.security.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  process.status,
                  style: TextStyle(
                    color: process.status == 'Running' ? TdcColors.system : TdcColors.security,
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
              Expanded(
                child: _buildProcessMetric('CPU', '${process.cpu.toStringAsFixed(1)}%'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildProcessMetric('RAM', '${process.memory.toStringAsFixed(1)}%'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildProcessMetric('Durée', _formatDuration(DateTime.now().difference(process.startTime))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TdcColors.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contrôles des services
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Rechercher un service',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _refreshServices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualiser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TdcColors.system,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Liste des services
          Expanded(
            child: Card(
              color: TdcColors.surface,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: TdcColors.system),
                        const SizedBox(width: 8),
                        const Text(
                          'Services Système',
                          style: TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_services.length} services',
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
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        return _buildServiceCard(service);
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

  Widget _buildServiceCard(SystemService service) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: service.status == 'Active' 
            ? TdcColors.system.withOpacity(0.1)
            : TdcColors.security.withOpacity(0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: service.status == 'Active' 
              ? TdcColors.system.withOpacity(0.3)
              : TdcColors.security.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                service.status == 'Active' ? Icons.check_circle : Icons.error,
                color: service.status == 'Active' ? TdcColors.system : TdcColors.security,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      service.description,
                      style: const TextStyle(
                        color: TdcColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: service.status == 'Active' 
                          ? TdcColors.system.withOpacity(0.1)
                          : TdcColors.security.withOpacity(0.1),
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: service.status == 'Active' 
                            ? TdcColors.system.withOpacity(0.3)
                            : TdcColors.security.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      service.status,
                      style: TextStyle(
                        color: service.status == 'Active' ? TdcColors.system : TdcColors.security,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: service.enabled,
                    onChanged: (value) {
                      setState(() {
                        service.enabled = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, color: TdcColors.textTertiary, size: 16),
              const SizedBox(width: 4),
              Text(
                'Démarré: ${_formatDateTime(service.loadedAt)}',
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisksTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contrôles des disques
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _refreshDisks,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Analyser les disques'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TdcColors.system,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _optimizeDisks,
                      icon: const Icon(Icons.tune),
                      label: const Text('Optimiser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TdcColors.network,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Liste des partitions
          Expanded(
            child: Card(
              color: TdcColors.surface,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.storage, color: TdcColors.system),
                        const SizedBox(width: 8),
                        const Text(
                          'Partitions de Disque',
                          style: TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _partitions.length,
                      itemBuilder: (context, index) {
                        final partition = _partitions[index];
                        return _buildPartitionCard(partition);
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

  Widget _buildApplicationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LabNotice(
            title: 'La 7ème Couche : L\'Application',
            message: 'Visualisation de la hiérarchie informatique complète, du silicium à l\'utilisateur.',
            icon: Icons.layers,
          ),
          const SizedBox(height: 32),
          _buildLayerCard(
            '7. USER APPLICATION',
            'T2DECODE, Navigateur, Jeux',
            'Interface avec l\'utilisateur final.',
            TdcColors.accent,
            Icons.phonelink,
          ),
          _buildLayerConnector(),
          _buildLayerCard(
            '6. SOFTWARE / MIDDLEWARE',
            'Bases de données, Serveurs Web',
            'Services applicatifs de haut niveau.',
            TdcColors.network,
            Icons.dns,
          ),
          _buildLayerConnector(),
          _buildLayerCard(
            '5. LIBRARIES (LIBS)',
            'Frameworks, DLL, Shared Objects',
            'Code réutilisable par les applications.',
            TdcColors.crypto,
            Icons.auto_stories,
          ),
          _buildLayerConnector(),
          _buildLayerCard(
            '4. OPERATING SYSTEM (OS)',
            'Ubuntu, macOS, Windows',
            'Gestion globale de l\'environnement.',
            TdcColors.system,
            Icons.window,
          ),
          _buildLayerConnector(),
          _buildLayerCard(
            '3. DRIVERS (PILOTES)',
            'Pilotes GPU, Wi-Fi, USB',
            'Traduction entre OS et Matériel.',
            TdcColors.security,
            Icons.settings_input_component,
          ),
          _buildLayerConnector(),
          _buildLayerCard(
            '2. KERNEL (NOYAU)',
            'Linux, XNU, NT',
            'Gestionnaire central des ressources.',
            TdcColors.danger,
            Icons.hub,
          ),
          _buildLayerConnector(),
          _buildLayerCard(
            '1. HARDWARE (MATÉRIEL)',
            'CPU, RAM, Disque, GPU',
            'La base physique de l\'informatique.',
            Colors.grey,
            Icons.memory,
          ),
          const SizedBox(height: 40),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TdcColors.surface,
                border: Border.all(color: TdcColors.border),
              ),
              child: const Text(
                'MÉMO : "Hé, Kevin ! Donne-Os Le Super Ananas."',
                style: TextStyle(
                  color: TdcColors.accent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerCard(String title, String subtitle, String desc, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: TdcColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  desc,
                  style: const TextStyle(color: TdcColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerConnector() {
    return Center(
      child: Container(
        width: 2,
        height: 20,
        color: TdcColors.border,
      ),
    );
  }

  Widget _buildPartitionCard(DiskPartition partition) {
    final usagePercentage = (partition.used / partition.size) * 100;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt.withOpacity(0.5),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.storage, color: TdcColors.system, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partition.device,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Monté sur ${partition.mountPoint} • ${partition.filesystem}',
                      style: const TextStyle(
                        color: TdcColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${usagePercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: usagePercentage > 80 ? TdcColors.security : TdcColors.system,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de progression
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: TdcColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: usagePercentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: usagePercentage > 80 ? TdcColors.security : TdcColors.system,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${_formatBytes(partition.used)} utilisés',
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '${_formatBytes(partition.available)} libres',
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${_formatBytes(partition.size)}',
                style: const TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires
  void _refreshProcesses() {
    setState(() {
      // Simuler le rafraîchissement des processus
      _processes.shuffle();
    });
  }

  void _refreshServices() {
    setState(() {
      // Simuler le rafraîchissement des services
    });
  }

  void _refreshDisks() {
    setState(() {
      // Simuler le rafraîchissement des disques
    });
  }

  void _optimizeDisks() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Optimisation des disques en cours...')),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}j';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1000000) {
      return '${(bytes / 1000000).toStringAsFixed(1)} GB';
    } else if (bytes >= 1000) {
      return '${(bytes / 1000).toStringAsFixed(1)} MB';
    } else {
      return '$bytes KB';
    }
  }
}

// Modèles de données
class SystemProcess {
  final int pid;
  final String name;
  final String user;
  final double cpu;
  final double memory;
  final String status;
  final DateTime startTime;

  SystemProcess({
    required this.pid,
    required this.name,
    required this.user,
    required this.cpu,
    required this.memory,
    required this.status,
    required this.startTime,
  });
}

class DiskPartition {
  final String device;
  final String mountPoint;
  final int size;
  final int used;
  final int available;
  final String filesystem;

  DiskPartition({
    required this.device,
    required this.mountPoint,
    required this.size,
    required this.used,
    required this.available,
    required this.filesystem,
  });
}

class SystemService {
  final String name;
  final String status;
  bool enabled;
  final String description;
  final DateTime loadedAt;

  SystemService({
    required this.name,
    required this.status,
    required this.enabled,
    required this.description,
    required this.loadedAt,
  });
}

class PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;

  PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
  });
}
