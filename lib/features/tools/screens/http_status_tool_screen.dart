import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class HttpStatusToolScreen extends StatefulWidget {
  const HttpStatusToolScreen({super.key});

  @override
  State<HttpStatusToolScreen> createState() => _HttpStatusToolScreenState();
}

class _HttpStatusToolScreenState extends State<HttpStatusToolScreen> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  final List<Map<String, String>> _statusCodes = [
    {'code': '200', 'title': 'OK', 'desc': 'Requête réussie.', 'tip': 'Tout va bien !'},
    {'code': '201', 'title': 'Created', 'desc': 'Ressource créée.', 'tip': 'Souvent après un POST.'},
    {'code': '301', 'title': 'Moved Permanently', 'desc': 'Redirection permanente.', 'tip': 'Mettre à jour vos liens.'},
    {'code': '302', 'title': 'Found', 'desc': 'Redirection temporaire.', 'tip': 'Le lien a bougé pour l\'instant.'},
    {'code': '400', 'title': 'Bad Request', 'desc': 'Erreur de syntaxe client.', 'tip': 'Vérifiez les données envoyées.'},
    {'code': '401', 'title': 'Unauthorized', 'desc': 'Authentification requise.', 'tip': 'Vérifiez vos identifiants.'},
    {'code': '403', 'title': 'Forbidden', 'desc': 'Accès refusé.', 'tip': 'Permissions insuffisantes sur le serveur.'},
    {'code': '404', 'title': 'Not Found', 'desc': 'Ressource introuvable.', 'tip': 'URL mal tapée ou page supprimée.'},
    {'code': '405', 'title': 'Method Not Allowed', 'desc': 'Méthode non autorisée.', 'tip': 'Ex: tenter un POST sur une route GET.'},
    {'code': '418', 'title': 'I\'m a teapot', 'desc': 'Je suis une théière.', 'tip': 'Easter egg du protocole HTCPCP.'},
    {'code': '429', 'title': 'Too Many Requests', 'desc': 'Trop de requêtes.', 'tip': 'Rate limiting actif, ralentissez !'},
    {'code': '500', 'title': 'Internal Server Error', 'desc': 'Erreur interne serveur.', 'tip': 'Vérifiez les logs côté backend.'},
    {'code': '502', 'title': 'Bad Gateway', 'desc': 'Passerelle incorrecte.', 'tip': 'Souvent un problème de proxy ou nginx.'},
    {'code': '503', 'title': 'Service Unavailable', 'desc': 'Service indisponible.', 'tip': 'Serveur en maintenance ou surchargé.'},
    {'code': '504', 'title': 'Gateway Timeout', 'desc': 'Temps d\'attente dépassé.', 'tip': 'Le serveur amont n\'a pas répondu.'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Codes d\'état HTTP',
        showBackButton: true,
      );
    });
  }

  Color _getColor(String code) {
    if (code.startsWith('2')) return Colors.green;
    if (code.startsWith('3')) return Colors.blue;
    if (code.startsWith('4')) return Colors.orange;
    if (code.startsWith('5')) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _statusCodes.where((s) => s['code']!.contains(_search) || s['title']!.toLowerCase().contains(_search.toLowerCase())).toList();

    return TdcPageWrapper(
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(labelText: 'Rechercher un code ou un nom', prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final s = filtered[i];
                final color = _getColor(s['code']!);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
                        child: Text(s['code']!, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(s['desc']!, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              width: double.infinity,
                              decoration: BoxDecoration(color: TdcColors.bg, borderRadius: BorderRadius.circular(4)),
                              child: Text('💡 Tip: ${s['tip']}', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: TdcColors.textMuted)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
