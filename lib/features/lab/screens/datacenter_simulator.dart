// ============================================================
// Datacenter Simulator — Simulation de gestion de datacenter
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

class DatacenterSimulator extends StatefulWidget {
  const DatacenterSimulator({super.key});

  @override
  State<DatacenterSimulator> createState() => _DatacenterSimulatorState();
}

class _DatacenterSimulatorState extends State<DatacenterSimulator>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Datacenter State
  final List<Rack> _racks = [];
  final List<Server> _servers = [];
  final List<PowerUnit> _powerUnits = [];
  final List<CoolingUnit> _coolingUnits = [];
  final List<Incident> _activeIncidents = [];
  double _totalPowerConsumption = 0.0;
  double _totalTemperature = 22.0;
  bool _isMonitoring = false;
  Timer? _monitoringTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeDatacenter();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _monitoringTimer?.cancel();
    super.dispose();
  }

  void _initializeDatacenter() {
    _racks.clear(); _servers.clear(); _powerUnits.clear(); _coolingUnits.clear(); _activeIncidents.clear();
    // Initialiser les racks
    for (int i = 0; i < 8; i++) {
      _racks.add(Rack(
        id: 'RACK-${String.fromCharCode(65 + i)}',
        position: i,
        servers: [],
        temperature: 20.0 + Random().nextDouble() * 5,
        powerUsage: 0.0,
      ));
    }

    // Initialiser les serveurs
    for (int i = 0; i < 24; i++) {
      final rackIndex = i % 8;
      final server = Server(
        id: 'SRV-${(i + 1).toString().padLeft(3, '0')}',
        rackId: 'RACK-${String.fromCharCode(65 + rackIndex)}',
        position: i ~/ 8,
        status: ServerStatus.running,
        cpuUsage: 10 + Random().nextDouble() * 40,
        memoryUsage: 20 + Random().nextDouble() * 30,
        temperature: 30.0 + Random().nextDouble() * 10,
        powerConsumption: 100.0 + Random().nextDouble() * 200,
        uptime: Duration(hours: Random().nextInt(1000)),
      );
      _servers.add(server);
      _racks[rackIndex].servers.add(server);
    }

    // Initialiser les unités de puissance
    for (int i = 0; i < 4; i++) {
      _powerUnits.add(PowerUnit(
        id: 'PDU-${i + 1}',
        status: PowerUnitStatus.active,
        capacity: 5000.0,
        currentLoad: 2000.0 + Random().nextDouble() * 1000,
        voltage: 230.0,
        frequency: 50.0,
      ));
    }

    // Initialiser les unités de refroidissement
    for (int i = 0; i < 3; i++) {
      _coolingUnits.add(CoolingUnit(
        id: 'CRAC-${i + 1}',
        status: CoolingUnitStatus.active,
        targetTemperature: 21.0,
        currentTemperature: 20.0,
        fanSpeed: 50 + Random().nextInt(20),
        coolingCapacity: 500.0,
        currentLoad: 250.0,
      ));
    }

    _calculateMetrics();
  }

  void _calculateMetrics() {
    _totalPowerConsumption = _servers.where((s) => s.status == ServerStatus.running).fold(0.0, (sum, server) => sum + server.powerConsumption);
    _totalTemperature = _racks.isEmpty ? 22.0 : 
        _racks.fold(0.0, (sum, rack) => sum + rack.temperature) / _racks.length;
    
    // Impact of Cooling failures
    final activeCooling = _coolingUnits.where((u) => u.status == CoolingUnitStatus.active).length;
    if (activeCooling < _coolingUnits.length) {
      _totalTemperature += (3 - activeCooling) * 2.5; 
    }
  }

  void _triggerRandomIncident() {
    final rand = Random();
    if (rand.nextDouble() > 0.15) return; // 15% chance per tick

    final type = IncidentType.values[rand.nextInt(IncidentType.values.length)];
    Incident? incident;

    switch (type) {
      case IncidentType.powerFailure:
        final unit = _powerUnits[rand.nextInt(_powerUnits.length)];
        if (unit.status == PowerUnitStatus.active) {
          incident = Incident(id: 'INC-${rand.nextInt(999)}', type: type, description: 'Panne critique PDU: ${unit.id}', targetId: unit.id);
          _powerUnits[_powerUnits.indexOf(unit)] = unit.copyWith(status: PowerUnitStatus.error);
        }
        break;
      case IncidentType.coolingFailure:
        final unit = _coolingUnits[rand.nextInt(_coolingUnits.length)];
        if (unit.status == CoolingUnitStatus.active) {
          incident = Incident(id: 'INC-${rand.nextInt(999)}', type: type, description: 'Surchauffe compresseur: ${unit.id}', targetId: unit.id);
          _coolingUnits[_coolingUnits.indexOf(unit)] = unit.copyWith(status: CoolingUnitStatus.error);
        }
        break;
      case IncidentType.serverError:
        final srv = _servers[rand.nextInt(_servers.length)];
        if (srv.status == ServerStatus.running) {
          incident = Incident(id: 'INC-${rand.nextInt(999)}', type: type, description: 'Kernel Panic: ${srv.id}', targetId: srv.id);
          _servers[_servers.indexOf(srv)] = srv.copyWith(status: ServerStatus.error, cpuUsage: 0, powerConsumption: 5);
        }
        break;
    }

    if (incident != null && !_activeIncidents.any((i) => i.targetId == incident!.targetId)) {
      _activeIncidents.add(incident);
    }
  }

  void _resolveIncident(Incident incident) {
    setState(() {
      _activeIncidents.remove(incident);
      if (incident.type == IncidentType.powerFailure) {
        final i = _powerUnits.indexWhere((u) => u.id == incident.targetId);
        if (i != -1) _powerUnits[i] = _powerUnits[i].copyWith(status: PowerUnitStatus.active);
      } else if (incident.type == IncidentType.coolingFailure) {
        final i = _coolingUnits.indexWhere((u) => u.id == incident.targetId);
        if (i != -1) _coolingUnits[i] = _coolingUnits[i].copyWith(status: CoolingUnitStatus.active);
      } else {
        final i = _servers.indexWhere((s) => s.id == incident.targetId);
        if (i != -1) _servers[i] = _servers[i].copyWith(status: ServerStatus.running);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: TdcColors.surface, border: Border(bottom: BorderSide(color: TdcColors.border))),
          child: Row(
            children: [
              Icon(Icons.dns, color: Colors.blue.shade700, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Datacenter Explorer', style: TextStyle(color: TdcColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${_activeIncidents.length} incidents actifs', style: TextStyle(color: _activeIncidents.isEmpty ? Colors.green : Colors.red, fontSize: 11)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isMonitoring ? null : _initializeDatacenter,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
                style: ElevatedButton.styleFrom(backgroundColor: TdcColors.surfaceAlt),
              ),
            ],
          ),
        ),
        _buildMetricsBar(),
        Container(
          color: TdcColors.surfaceAlt.withOpacity(0.3),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.blue.shade700,
            labelColor: Colors.blue.shade700,
            tabs: [
              const Tab(text: 'Salles/Racks'),
              const Tab(text: 'Serveurs'),
              const Tab(text: 'Énergie'),
              const Tab(text: 'Refroidissement'),
              Tab(child: Row(children: [const Text('Incidents'), if(_activeIncidents.isNotEmpty) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text('${_activeIncidents.length}', style: const TextStyle(color: Colors.white, fontSize: 10)))]))
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRacksTab(),
              _buildServersTab(),
              _buildPowerTab(),
              _buildCoolingTab(),
              _buildIncidentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentsTab() {
    if (_activeIncidents.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_outline, color: Colors.green, size: 64), SizedBox(height: 16), Text('Tous les systèmes sont nominaux', style: TextStyle(color: TdcColors.textMuted))]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeIncidents.length,
      itemBuilder: (context, i) {
        final inc = _activeIncidents[i];
        return Card(
          color: Colors.red.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: TdcRadius.md, side: const BorderSide(color: Colors.red, width: 0.5)),
          child: ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: Text(inc.description, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            subtitle: Text('ID: ${inc.id} | Target: ${inc.targetId}'),
            trailing: ElevatedButton(onPressed: () => _resolveIncident(inc), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('RÉPARER')),
          ),
        );
      },
    );
  }

  Widget _buildMetricsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surfaceAlt.withOpacity(0.2), border: Border(bottom: BorderSide(color: TdcColors.border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric('⚡', '${_totalPowerConsumption.toStringAsFixed(0)}W', 'Puissance'),
          _buildMetric('🌡️', '${_totalTemperature.toStringAsFixed(1)}°C', 'Temp'),
          IconButton(
            onPressed: _toggleMonitoring, 
            icon: Icon(_isMonitoring ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 40, color: _isMonitoring ? Colors.red : Colors.green)),
          _buildMetric('💧', '45%', 'Humidité'),
          _buildMetric('🖥️', '${_servers.length}', 'Hosts'),
        ],
      ),
    );
  }

  Widget _buildMetric(String icon, String val, String sub) => Column(children: [Text(icon, style: const TextStyle(fontSize: 20)), Text(val, style: const TextStyle(fontWeight: FontWeight.bold)), Text(sub, style: const TextStyle(fontSize: 10, color: TdcColors.textMuted))]);

  Widget _buildRacksTab() => GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.5, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: _racks.length, itemBuilder: (_, i) => _buildRackCard(_racks[i]));

  Widget _buildRackCard(Rack rack) {
    final hasError = _activeIncidents.any((inc) => inc.targetId == rack.id || rack.servers.any((s) => s.status == ServerStatus.error));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: hasError ? Colors.red : TdcColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(rack.id, style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), if(hasError) const Icon(Icons.error, color: Colors.red, size: 14)]),
        const Spacer(),
        LinearProgressIndicator(value: rack.temperature / 80, backgroundColor: TdcColors.surfaceAlt, color: _getTemperatureColor(rack.temperature)),
        const SizedBox(height: 8),
        Text('${rack.servers.length} serveurs | ${rack.temperature.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 11, color: TdcColors.textMuted)),
      ]),
    );
  }

  Widget _buildServersTab() => ListView.separated(padding: const EdgeInsets.all(16), itemCount: _servers.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) => _buildServerCard(_servers[i]));

  Widget _buildServerCard(Server server) {
    final isError = server.status == ServerStatus.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: isError ? Colors.red : TdcColors.border)),
      child: Row(children: [
        Container(width: 8, height: 32, decoration: BoxDecoration(color: _getServerStatusColor(server.status), borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(server.id, style: const TextStyle(fontWeight: FontWeight.bold)), Text(server.rackId, style: const TextStyle(fontSize: 11, color: TdcColors.textMuted))])),
        _buildMiniMetric('CPU', '${server.cpuUsage.toInt()}%'),
        _buildMiniMetric('Temp', '${server.temperature.toInt()}°C'),
        if(isError) IconButton(icon: const Icon(Icons.build, size: 18, color: Colors.green), onPressed: () => _resolveIncident(_activeIncidents.firstWhere((inc) => inc.targetId == server.id))),
      ]),
    );
  }

  Widget _buildMiniMetric(String label, String val) => Padding(padding: const EdgeInsets.only(left: 16), child: Column(children: [Text(label, style: const TextStyle(fontSize: 9, color: TdcColors.textMuted)), Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]));

  Widget _buildPowerTab() => GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.2, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: _powerUnits.length, itemBuilder: (_, i) => _buildPowerUnitCard(_powerUnits[i]));

  Widget _buildPowerUnitCard(PowerUnit unit) {
    final isError = unit.status == PowerUnitStatus.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: isError ? Colors.red : TdcColors.border)),
      child: Column(children: [
        Row(children: [const Icon(Icons.bolt, size: 16), const SizedBox(width: 8), Text(unit.id), const Spacer(), Icon(Icons.circle, color: isError ? Colors.red : Colors.green, size: 10)]),
        const Spacer(),
        Text('${unit.currentLoad.toInt()}W / ${unit.capacity.toInt()}W', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        if(isError) ElevatedButton(onPressed: () => _resolveIncident(_activeIncidents.firstWhere((inc) => inc.targetId == unit.id)), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 30)), child: const Text('Réparer PDU')),
      ]),
    );
  }

  Widget _buildCoolingTab() => GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.2, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: _coolingUnits.length, itemBuilder: (_, i) => _buildCoolingUnitCard(_coolingUnits[i]));

  Widget _buildCoolingUnitCard(CoolingUnit unit) {
    final isError = unit.status == CoolingUnitStatus.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: isError ? Colors.red : TdcColors.border)),
      child: Column(children: [
        Row(children: [const Icon(Icons.ac_unit, size: 16), const SizedBox(width: 8), Text(unit.id), const Spacer(), Icon(Icons.circle, color: isError ? Colors.red : Colors.green, size: 10)]),
        const Spacer(),
        Text('Fan: ${unit.fanSpeed}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        if(isError) ElevatedButton(onPressed: () => _resolveIncident(_activeIncidents.firstWhere((inc) => inc.targetId == unit.id)), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 30)), child: const Text('Réparer CRAC')),
      ]),
    );
  }

  void _toggleMonitoring() {
    setState(() { _isMonitoring = !_isMonitoring; });
    if (_isMonitoring) {
      _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isMonitoring || !mounted) { timer.cancel(); return; }
        _updateMetrics();
        _triggerRandomIncident();
      });
    } else {
      _monitoringTimer?.cancel();
    }
  }

  void _updateMetrics() {
    final random = Random();
    for (int i = 0; i < _servers.length; i++) {
      final s = _servers[i];
      if (s.status == ServerStatus.running) {
        _servers[i] = s.copyWith(
          cpuUsage: (s.cpuUsage + (random.nextDouble() - 0.5) * 10).clamp(5, 95),
          temperature: (s.temperature + (random.nextDouble() - 0.5) * 4).clamp(30, 75),
          powerConsumption: (s.powerConsumption + (random.nextDouble() - 0.5) * 20).clamp(100, 450),
        );
      }
    }
    for (int i = 0; i < _racks.length; i++) {
      final r = _racks[i];
      final srvs = _servers.where((s) => s.rackId == r.id);
      final avgT = srvs.isEmpty ? 25.0 : srvs.fold<double>(0.0, (sum, s) => sum + s.temperature) / srvs.length;
      _racks[i] = r.copyWith(temperature: avgT, powerUsage: srvs.fold<double>(0.0, (sum, s) => sum + s.powerConsumption));
    }
    _calculateMetrics();
    setState(() {});
  }

  Color _getTemperatureColor(double temp) => temp > 60 ? Colors.red : (temp > 45 ? Colors.orange : Colors.green);
  Color _getServerStatusColor(ServerStatus status) {
    switch(status) {
      case ServerStatus.running: return Colors.green;
      case ServerStatus.error: return Colors.red;
      case ServerStatus.maintenance: return Colors.orange;
      case ServerStatus.stopped: return Colors.grey;
    }
  }
}

// Models & Enums
enum IncidentType { powerFailure, coolingFailure, serverError }
class Incident {
  final String id;
  final IncidentType type;
  final String description;
  final String targetId;
  Incident({required this.id, required this.type, required this.description, required this.targetId});
}

class Rack {
  final String id;
  final int position;
  final List<Server> servers;
  final double temperature;
  final double powerUsage;
  const Rack({required this.id, required this.position, required this.servers, required this.temperature, required this.powerUsage});
  Rack copyWith({double? temperature, double? powerUsage}) => Rack(id: id, position: position, servers: servers, temperature: temperature ?? this.temperature, powerUsage: powerUsage ?? this.powerUsage);
}

class Server {
  final String id;
  final String rackId;
  final int position;
  final ServerStatus status;
  final double cpuUsage;
  final double memoryUsage;
  final double temperature;
  final double powerConsumption;
  final Duration uptime;
  const Server({required this.id, required this.rackId, required this.position, required this.status, required this.cpuUsage, required this.memoryUsage, required this.temperature, required this.powerConsumption, required this.uptime});
  Server copyWith({ServerStatus? status, double? cpuUsage, double? temperature, double? powerConsumption}) => Server(id: id, rackId: rackId, position: position, status: status ?? this.status, cpuUsage: cpuUsage ?? this.cpuUsage, memoryUsage: memoryUsage, temperature: temperature ?? this.temperature, powerConsumption: powerConsumption ?? this.powerConsumption, uptime: uptime);
}

enum ServerStatus { running, stopped, maintenance, error }
class PowerUnit {
  final String id;
  final PowerUnitStatus status;
  final double capacity;
  final double currentLoad;
  final double voltage;
  final double frequency;
  const PowerUnit({required this.id, required this.status, required this.capacity, required this.currentLoad, required this.voltage, required this.frequency});
  PowerUnit copyWith({PowerUnitStatus? status, double? currentLoad}) => PowerUnit(id: id, status: status ?? this.status, capacity: capacity, currentLoad: currentLoad ?? this.currentLoad, voltage: voltage, frequency: frequency);
}

enum PowerUnitStatus { active, inactive, maintenance, error }
class CoolingUnit {
  final String id;
  final CoolingUnitStatus status;
  final double targetTemperature;
  final double currentTemperature;
  final int fanSpeed;
  final double coolingCapacity;
  final double currentLoad;
  const CoolingUnit({required this.id, required this.status, required this.targetTemperature, required this.currentTemperature, required this.fanSpeed, required this.coolingCapacity, required this.currentLoad});
  CoolingUnit copyWith({CoolingUnitStatus? status}) => CoolingUnit(id: id, status: status ?? this.status, targetTemperature: targetTemperature, currentTemperature: currentTemperature, fanSpeed: fanSpeed, coolingCapacity: coolingCapacity, currentLoad: currentLoad);
}

enum CoolingUnitStatus { active, inactive, maintenance, error }
