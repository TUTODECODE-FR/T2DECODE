/// Validation et normalisation de l'URL de base Ollama.
///
/// Objectifs :
/// - Refuser les schémas autres que http/https.
/// - Refuser les userinfo (user:pass@) et les chemins/queries/fragments.
/// - Autoriser HTTP uniquement sur loopback (localhost/127.0.0.1/::1).
/// - Autoriser HTTPS sur loopback, *.local (mDNS) ou IPs privées (LAN/VPN).
library ollama_host;

class OllamaHost {
  static const String defaultBaseUrl = 'http://localhost:11434';

  static String normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty base URL');
    }

    var withScheme = trimmed;
    if (!withScheme.contains('://')) {
      final lower = withScheme.toLowerCase();
      final loopbackLike = lower.startsWith('localhost') ||
          lower.startsWith('127.0.0.1') ||
          lower.startsWith('::1') ||
          lower.startsWith('[::1]');
      withScheme = '${loopbackLike ? 'http' : 'https'}://$withScheme';
    }

    Uri uri;
    try {
      uri = Uri.parse(withScheme);
    } catch (_) {
      throw const FormatException('Invalid base URL');
    }

    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException('Unsupported scheme');
    }
    if (uri.userInfo.isNotEmpty) {
      throw const FormatException('Userinfo not allowed');
    }
    if (uri.host.isEmpty) {
      throw const FormatException('Missing host');
    }
    if ((uri.path.isNotEmpty && uri.path != '/') || uri.hasQuery || uri.hasFragment) {
      throw const FormatException('Path/query/fragment not allowed');
    }

    final normalized = uri
        .replace(
          path: '',
          query: null,
          fragment: null,
        )
        .toString()
        .replaceFirst(RegExp(r'/$'), '');

    final normalizedUri = Uri.parse(normalized);
    if (!_isAllowed(normalizedUri)) {
      throw const FormatException('Host not allowed');
    }

    return normalized;
  }

  static bool isAllowed(String raw) {
    try {
      normalize(raw);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _isAllowed(Uri uri) {
    final host = uri.host.toLowerCase();
    final isLoopback = host == 'localhost' || host == '127.0.0.1' || host == '::1';

    if (uri.scheme == 'http') {
      return isLoopback;
    }

    // https
    if (isLoopback) return true;
    if (host.endsWith('.local')) return true;
    if (_isPrivateIpv4(host)) return true;
    if (_isLocalishIpv6(host)) return true;
    return false;
  }

  static bool _isPrivateIpv4(String host) {
    final m = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$').firstMatch(host);
    if (m == null) return false;

    final o1 = int.parse(m.group(1)!);
    final o2 = int.parse(m.group(2)!);
    final o3 = int.parse(m.group(3)!);
    final o4 = int.parse(m.group(4)!);

    if (o1 > 255 || o2 > 255 || o3 > 255 || o4 > 255) return false;

    // 10.0.0.0/8
    if (o1 == 10) return true;
    // 192.168.0.0/16
    if (o1 == 192 && o2 == 168) return true;
    // 172.16.0.0/12
    if (o1 == 172 && o2 >= 16 && o2 <= 31) return true;
    // 100.64.0.0/10 (CGNAT) — utile pour certains VPN.
    if (o1 == 100 && o2 >= 64 && o2 <= 127) return true;

    return false;
  }

  static bool _isLocalishIpv6(String host) {
    // Uri.host renvoie l'IPv6 sans crochets.
    final h = host.toLowerCase();
    if (!h.contains(':')) return false;

    // ULA: fc00::/7 (fcxx / fdxx) + link-local fe80::/10.
    return h.startsWith('fc') || h.startsWith('fd') || h.startsWith('fe80:');
  }
}
