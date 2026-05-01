// ============================================================
// Cloud Simulator - Simulation cloud ultra-professionnelle
// ============================================================
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/lab/widgets/lab_widgets.dart';
import 'package:tutodecode/features/lab/widgets/simulator_ai_assistant.dart';

class CloudSimulator extends StatefulWidget {
  const CloudSimulator({super.key});

  @override
  State<CloudSimulator> createState() => _CloudSimulatorState();
}

class _CloudSimulatorState extends State<CloudSimulator>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // États des simulations
  bool _isDeploying = false;
  
  // Données cloud
  List<CloudInstance> _instances = [];
  List<CloudService> _services = [];
  List<DeploymentJob> _deployments = [];
  
  // Métriques cloud
  double _totalCost = 0.0;
  int _activeInstances = 0;
  double _avgResponseTime = 0.0;
  int _totalRequests = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeCloudData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeCloudData() {
    // Initialiser avec des données d'exemple
    _instances = [
      CloudInstance(
        id: 'i-1234567890abcdef0',
        name: 'web-server-01',
        type: 't3.medium',
        status: 'Running',
        region: 'eu-west-3',
        publicIp: '52.47.123.45',
        privateIp: '10.0.1.100',
        cpu: 2,
        memory: 4.0,
        storage: 20,
        hourlyCost: 0.0416,
        launchTime: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      CloudInstance(
        id: 'i-abcdef0123456789',
        name: 'database-01',
        type: 'db.t3.micro',
        status: 'Running',
        region: 'eu-west-3',
        publicIp: '',
        privateIp: '10.0.2.50',
        cpu: 1,
        memory: 1.0,
        storage: 20,
        hourlyCost: 0.013,
        launchTime: DateTime.now().subtract(const Duration(hours: 24)),
      ),
    ];
    
    _services = [
      CloudService(
        name: 'Load Balancer',
        type: 'Application Load Balancer',
        status: 'Active',
        region: 'eu-west-3',
        endpoint: 'lb-tutodecode-123456.eu-west-3.elb.amazonaws.com',
        monthlyCost: 25.0,
      ),
      CloudService(
        name: 'RDS Database',
        type: 'MySQL',
        status: 'Available',
        region: 'eu-west-3',
        endpoint: 'tutodecode-db.c7abcdef.eu-west-3.rds.amazonaws.com',
        monthlyCost: 15.0,
      ),
    ];
    
    _deployments = [
      DeploymentJob(
        id: 'deploy-123456',
        application: 'web-app',
        environment: 'production',
        status: 'Completed',
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now().subtract(const Duration(minutes: 25)),
        duration: const Duration(minutes: 5),
      ),
    ];
    
    _calculateMetrics();
  }

  void _calculateMetrics() {
    _activeInstances = _instances.where((i) => i.status == 'Running').length;
    _totalCost = _instances.fold(0.0, (sum, instance) {
      final hours = DateTime.now().difference(instance.launchTime).inHours;
      return sum + (hours * instance.hourlyCost);
    });
    _totalRequests = Random().nextInt(10000) + 5000;
    _avgResponseTime = Random().nextDouble() * 200 + 50;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header avec métriques cloud
        LabGlassContainer(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.cloud, color: TdcColors.cloud, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'INFRASTRUCTURE CLOUD HYBRIDE',
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
                      color: TdcColors.cloud.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TdcColors.cloud.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: TdcColors.cloud,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'MULTI-REGION (DÉMO)',
                          style: TextStyle(
                            color: TdcColors.cloud,
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
                    'Aucun accès cloud/API externe (Zero Cloud). Données fictives.',
                icon: Icons.info_outline,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LabMetricCard(
                      title: 'Instances',
                      value: '$_activeInstances',
                      icon: Icons.dns,
                      color: TdcColors.cloud,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabMetricCard(
                      title: 'Coût/H',
                      value: '\$${_totalCost.toStringAsFixed(3)}',
                      icon: Icons.attach_money,
                      color: TdcColors.system,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabMetricCard(
                      title: 'Requêtes',
                      value: '$_totalRequests',
                      icon: Icons.sync,
                      color: TdcColors.network,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabMetricCard(
                      title: 'Latence',
                      value: '${_avgResponseTime.toStringAsFixed(0)}ms',
                      icon: Icons.timer,
                      color: _avgResponseTime < 100 ? TdcColors.success : TdcColors.warning,
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
            indicatorColor: TdcColors.cloud,
            labelColor: TdcColors.cloud,
            unselectedLabelColor: TdcColors.textMuted,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Instances'),
              Tab(text: 'Services'),
              Tab(text: 'Déploiements'),
              Tab(text: '🤖 IA'),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInstancesTab(),
              _buildServicesTab(),
              _buildDeploymentsTab(),
              const SimulatorAIAssistant(
                topic: 'Cloud & Infrastructure',
                accentColor: TdcColors.cloud,
                systemPrompt:
                    'Tu es un architecte cloud DevOps expert. Réponds en français, de façon concise et pédagogique. '
                    'Domaines couverts : instances VM, load balancers, auto-scaling, déploiements CI/CD, '
                    'monitoring, optimisation des coûts, IaC (Terraform/Ansible), containers Docker/Kubernetes.',
                suggestedQuestions: [
                  'Qu\'est-ce que l\'auto-scaling ?',
                  'Comment optimiser les coûts cloud ?',
                  'Docker vs Kubernetes ?',
                  'Expliquer le blue/green deployment',
                  'Qu\'est-ce qu\'un load balancer ?',
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildInstancesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contrôles des instances
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: 't3.medium',
                      items: const [
                        DropdownMenuItem(value: 't3.micro', child: Text('t3.micro')),
                        DropdownMenuItem(value: 't3.small', child: Text('t3.small')),
                        DropdownMenuItem(value: 't3.medium', child: Text('t3.medium')),
                        DropdownMenuItem(value: 't3.large', child: Text('t3.large')),
                      ],
                      onChanged: (value) {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: 'eu-west-3',
                      items: const [
                        DropdownMenuItem(value: 'eu-west-1', child: Text('eu-west-1')),
                        DropdownMenuItem(value: 'eu-west-2', child: Text('eu-west-2')),
                        DropdownMenuItem(value: 'eu-west-3', child: Text('eu-west-3')),
                        DropdownMenuItem(value: 'us-east-1', child: Text('us-east-1')),
                      ],
                      onChanged: (value) {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isDeploying ? null : _launchInstance,
                    icon: _isDeploying 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.launch),
                    label: Text(_isDeploying ? 'Lancement...' : 'Lancer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TdcColors.cloud,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Liste des instances
          Expanded(
            child: Card(
              color: TdcColors.surface,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.dns, color: TdcColors.cloud),
                        const SizedBox(width: 8),
                        const Text(
                          'Instances Cloud',
                          style: TextStyle(
                            color: TdcColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_instances.length} instances',
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
                      itemCount: _instances.length,
                      itemBuilder: (context, index) {
                        final instance = _instances[index];
                        return _buildInstanceCard(instance);
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

  Widget _buildInstanceCard(CloudInstance instance) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getInstanceStatusColor(instance.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getInstanceStatusColor(instance.status).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getInstanceStatusColor(instance.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getInstanceIcon(instance.status),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instance.name,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${instance.type} • ${instance.region}',
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
                  color: _getInstanceStatusColor(instance.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  instance.status,
                  style: const TextStyle(
                    color: Colors.white,
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
                child: _buildInstanceMetric('CPU', '${instance.cpu} vCPU'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInstanceMetric('RAM', '${instance.memory} GB'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInstanceMetric('Stockage', '${instance.storage} GB'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInstanceMetric('Coût/h', '\$${instance.hourlyCost.toStringAsFixed(4)}'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (instance.publicIp.isNotEmpty) ...[
                Icon(Icons.public, color: TdcColors.textTertiary, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Pub: ${instance.publicIp}',
                  style: const TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Icon(Icons.lan, color: TdcColors.textTertiary, size: 16),
              const SizedBox(width: 4),
              Text(
                'Priv: ${instance.privateIp}',
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _restartInstance(instance),
                    icon: const Icon(Icons.refresh, size: 16),
                    tooltip: 'Redémarrer',
                  ),
                  IconButton(
                    onPressed: () => _stopInstance(instance),
                    icon: const Icon(Icons.stop, size: 16),
                    tooltip: 'Arrêter',
                  ),
                  IconButton(
                    onPressed: () => _terminateInstance(instance),
                    icon: const Icon(Icons.delete, size: 16),
                    tooltip: 'Terminer',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstanceMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TdcColors.textSecondary,
              fontSize: 9,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 11,
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
                    child: ElevatedButton.icon(
                      onPressed: _createService,
                      icon: const Icon(Icons.add),
                      label: const Text('Créer un service'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TdcColors.cloud,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _refreshServices,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualiser'),
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
                        Icon(Icons.cloud_queue, color: TdcColors.cloud),
                        const SizedBox(width: 8),
                        const Text(
                          'Services Cloud',
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

  Widget _buildServiceCard(CloudService service) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: service.status == 'Active' || service.status == 'Available'
            ? TdcColors.system.withOpacity(0.1)
            : TdcColors.security.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: service.status == 'Active' || service.status == 'Available'
              ? TdcColors.system.withOpacity(0.3)
              : TdcColors.security.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getServiceIcon(service.type),
                color: TdcColors.cloud,
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
                      service.type,
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
                  color: service.status == 'Active' || service.status == 'Available'
                      ? TdcColors.system
                      : TdcColors.security,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  service.status,
                  style: const TextStyle(
                    color: Colors.white,
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
              Icon(Icons.location_on, color: TdcColors.textTertiary, size: 16),
              const SizedBox(width: 4),
              Text(
                service.region,
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Icon(Icons.attach_money, color: TdcColors.system, size: 16),
              const SizedBox(width: 4),
              Text(
                '\$${service.monthlyCost.toStringAsFixed(2)}/mois',
                style: const TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (service.endpoint.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.link, color: TdcColors.textTertiary, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    service.endpoint,
                    style: const TextStyle(
                      color: TdcColors.network,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeploymentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contrôles de déploiement
          Card(
            color: TdcColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: 'production',
                      items: const [
                        DropdownMenuItem(value: 'development', child: Text('Development')),
                        DropdownMenuItem(value: 'staging', child: Text('Staging')),
                        DropdownMenuItem(value: 'production', child: Text('Production')),
                      ],
                      onChanged: (value) {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isDeploying ? null : _startDeployment,
                    icon: _isDeploying 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload),
                    label: Text(_isDeploying ? 'Déploiement...' : 'Déployer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TdcColors.cloud,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Historique des déploiements
          Expanded(
            child: Card(
              color: TdcColors.surface,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: TdcColors.cloud),
                        const SizedBox(width: 8),
                        const Text(
                          'Historique des Déploiements',
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
                      itemCount: _deployments.length,
                      itemBuilder: (context, index) {
                        final deployment = _deployments[index];
                        return _buildDeploymentCard(deployment);
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

  Widget _buildDeploymentCard(DeploymentJob deployment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getDeploymentStatusColor(deployment.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getDeploymentStatusColor(deployment.status).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getDeploymentStatusColor(deployment.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getDeploymentIcon(deployment.status),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deployment.application,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${deployment.environment} • ${deployment.id}',
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
                  color: _getDeploymentStatusColor(deployment.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  deployment.status,
                  style: const TextStyle(
                    color: Colors.white,
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
              Icon(Icons.timer, color: TdcColors.textTertiary, size: 16),
              const SizedBox(width: 4),
              Text(
                'Durée: ${deployment.duration.inMinutes} min',
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Icon(Icons.access_time, color: TdcColors.textTertiary, size: 16),
              const SizedBox(width: 4),
              Text(
                'Début: ${_formatDateTime(deployment.startTime)}',
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

  // Méthodes de simulation
  Future<void> _launchInstance() async {
    setState(() => _isDeploying = true);
    
    await Future.delayed(const Duration(seconds: 3));
    
    final newInstance = CloudInstance(
      id: 'i-${DateTime.now().millisecondsSinceEpoch}',
      name: 'instance-${_instances.length + 1}',
      type: 't3.medium',
      status: 'Running',
      region: 'eu-west-3',
      publicIp: '52.47.${Random().nextInt(255)}.${Random().nextInt(255)}',
      privateIp: '10.0.1.${100 + _instances.length}',
      cpu: 2,
      memory: 4.0,
      storage: 20,
      hourlyCost: 0.0416,
      launchTime: DateTime.now(),
    );
    
    setState(() {
      _isDeploying = false;
      _instances.add(newInstance);
      _calculateMetrics();
    });
  }

  void _restartInstance(CloudInstance instance) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Redémarrage de ${instance.name}...')),
    );
  }

  void _stopInstance(CloudInstance instance) {
    setState(() {
      instance.status = 'Stopped';
      _calculateMetrics();
    });
  }

  void _terminateInstance(CloudInstance instance) {
    setState(() {
      _instances.remove(instance);
      _calculateMetrics();
    });
  }

  void _createService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Création de service...')),
    );
  }

  void _refreshServices() {
    setState(() {
      // Simuler le rafraîchissement
    });
  }

  Future<void> _startDeployment() async {
    setState(() => _isDeploying = true);
    
    final deployment = DeploymentJob(
      id: 'deploy-${DateTime.now().millisecondsSinceEpoch}',
      application: 'web-app',
      environment: 'production',
      status: 'In Progress',
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      duration: const Duration(minutes: 0),
    );
    
    setState(() {
      _deployments.insert(0, deployment);
    });
    
    await Future.delayed(const Duration(seconds: 5));
    
    setState(() {
      deployment.status = 'Completed';
      deployment.endTime = DateTime.now();
      deployment.duration = const Duration(minutes: 5);
      _isDeploying = false;
    });
  }

  // Méthodes utilitaires
  Color _getInstanceStatusColor(String status) {
    switch (status) {
      case 'Running': return TdcColors.system;
      case 'Stopped': return TdcColors.crypto;
      case 'Terminated': return TdcColors.security;
      case 'Pending': return TdcColors.network;
      default: return TdcColors.border;
    }
  }

  IconData _getInstanceIcon(String status) {
    switch (status) {
      case 'Running': return Icons.play_arrow;
      case 'Stopped': return Icons.pause;
      case 'Terminated': return Icons.stop;
      case 'Pending': return Icons.hourglass_empty;
      default: return Icons.help;
    }
  }

  IconData _getServiceIcon(String type) {
    switch (type) {
      case 'Application Load Balancer': return Icons.balance;
      case 'MySQL': return Icons.storage;
      case 'S3': return Icons.cloud;
      default: return Icons.cloud_queue;
    }
  }

  Color _getDeploymentStatusColor(String status) {
    switch (status) {
      case 'Completed': return TdcColors.system;
      case 'Failed': return TdcColors.security;
      case 'In Progress': return TdcColors.network;
      case 'Pending': return TdcColors.crypto;
      default: return TdcColors.border;
    }
  }

  IconData _getDeploymentIcon(String status) {
    switch (status) {
      case 'Completed': return Icons.check_circle;
      case 'Failed': return Icons.error;
      case 'In Progress': return Icons.sync;
      case 'Pending': return Icons.schedule;
      default: return Icons.help;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Modèles de données
class CloudInstance {
  final String id;
  final String name;
  final String type;
  String status;
  final String region;
  final String publicIp;
  final String privateIp;
  final int cpu;
  final double memory;
  final int storage;
  final double hourlyCost;
  final DateTime launchTime;

  CloudInstance({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.region,
    required this.publicIp,
    required this.privateIp,
    required this.cpu,
    required this.memory,
    required this.storage,
    required this.hourlyCost,
    required this.launchTime,
  });
}

class CloudService {
  final String name;
  final String type;
  final String status;
  final String region;
  final String endpoint;
  final double monthlyCost;

  CloudService({
    required this.name,
    required this.type,
    required this.status,
    required this.region,
    required this.endpoint,
    required this.monthlyCost,
  });
}

class DeploymentJob {
  final String id;
  final String application;
  final String environment;
  String status;
  final DateTime startTime;
  DateTime endTime;
  Duration duration;

  DeploymentJob({
    required this.id,
    required this.application,
    required this.environment,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });
}

class CloudMetric {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;

  CloudMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
  });
}
