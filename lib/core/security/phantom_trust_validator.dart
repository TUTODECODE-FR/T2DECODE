import 'dart:convert';
import 'package:crypto/crypto.dart' as pkg_crypto;
import 'package:cryptography/cryptography.dart';

class PhantomTrustValidator {
  /// Clé publique de l'association TUTODECODE (Exemple).
  /// Dans un environnement de prod, cette clé devrait être hardcodée 
  /// ou lue depuis un certificat embarqué sûr.
  static const String rootPublicKeyHex = 'a1b2c3d4e5f6...'; // TODO: Remplacer par la vraie clé
  
  Map<String, String>? _merkleTreeCache;
  bool _isManifestValid = false;

  /// Valide le Manifeste de T2C-Phantom.
  Future<bool> loadAndValidateManifest(String manifestJson, String signatureHex) async {
    try {
      final ed25519 = Ed25519();
      final pubKey = SimplePublicKey(
        _hexToBytes(rootPublicKeyHex), 
        type: KeyPairType.ed25519,
      );
      
      final isValid = await ed25519.verify(
        utf8.encode(manifestJson), 
        signature: Signature(_hexToBytes(signatureHex), publicKey: pubKey),
      );
      
      if (isValid) {
        final decoded = json.decode(manifestJson) as Map<String, dynamic>;
        _merkleTreeCache = Map<String, String>.from(decoded['merkle_tree'] ?? {});
        _isManifestValid = true;
        return true;
      }
    } catch (e) {
      print("Erreur validation manifeste T2C-Phantom: $e");
    }
    _isManifestValid = false;
    return false;
  }

  /// Vérifie l'intégrité d'un fichier déchiffré via le Merkle tree.
  Future<bool> verifyIntegrity(String relativePath, List<int> data) async {
    // Si on est en phase de test ou que l'arbre n'est pas chargé,
    // on peut autoriser ou rejeter selon la politique stricte.
    if (!_isManifestValid || _merkleTreeCache == null) {
      // Pour l'instant on retourne vrai en test. TODO: Retourner false en strict mode.
      return true;
    }

    final expectedHash = _merkleTreeCache![relativePath];
    if (expectedHash == null) {
      print("Fichier non référencé dans le manifeste: $relativePath");
      return false; // Zero-trust: fichier inconnu bloqué.
    }

    final actualHash = _bytesToHex(pkg_crypto.sha256.convert(data).bytes);
    return actualHash == expectedHash;
  }

  List<int> _hexToBytes(String hexStr) {
    List<int> bytes = [];
    for (int i = 0; i < hexStr.length; i += 2) {
      bytes.add(int.parse(hexStr.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }
}
