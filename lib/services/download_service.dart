import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resultado do processo de sincronização
enum SyncStatus { upToDate, updated, failed }

class SyncResult {
  final SyncStatus status;
  final String? error;
  final String? localIndexPath;

  const SyncResult({
    required this.status,
    this.error,
    this.localIndexPath,
  });
}

class DownloadService {
  // ─── CONFIGURAÇÃO ────────────────────────────────────────────────────────────
  // Altere apenas esta URL para apontar para o seu servidor InfinityFree
  static const String _baseUrl = 'https://seusite.infinityfreeapp.com';
  static const String _manifestPath = '/manifest.json';
  // ─────────────────────────────────────────────────────────────────────────────

  static const String _prefVersion = 'content_version';
  static const String _prefIndexPath = 'local_index_path';

  // Cabeçalhos para evitar bloqueio anti-bot do InfinityFree
  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/json,*/*',
  };

  /// Executa a sincronização completa.
  /// [onProgress] recebe dois valores: arquivo atual e total de arquivos.
  static Future<SyncResult> sync({
    required void Function(int current, int total, String fileName) onProgress,
  }) async {
    try {
      // 1. Baixar o manifesto
      final manifest = await _fetchManifest();
      if (manifest == null) {
        return const SyncResult(
          status: SyncStatus.failed,
          error: 'Não foi possível obter o manifesto do servidor.\n'
              'Verifique sua conexão e tente novamente.',
        );
      }

      final remoteVersion = manifest['version'] as String? ?? '0';
      final files = List<String>.from(manifest['files'] as List? ?? []);

      if (files.isEmpty) {
        return const SyncResult(
          status: SyncStatus.failed,
          error: 'O manifesto está vazio. Nenhum arquivo para baixar.',
        );
      }

      // 2. Comparar versão local com remota
      final prefs = await SharedPreferences.getInstance();
      final localVersion = prefs.getString(_prefVersion) ?? '';
      final existingIndexPath = prefs.getString(_prefIndexPath) ?? '';

      if (localVersion == remoteVersion && existingIndexPath.isNotEmpty) {
        final existingFile = File(existingIndexPath);
        if (await existingFile.exists()) {
          return SyncResult(
            status: SyncStatus.upToDate,
            localIndexPath: existingIndexPath,
          );
        }
      }

      // 3. Preparar diretório local
      final appDir = await getApplicationDocumentsDirectory();
      final contentDir = Directory('${appDir.path}/content');
      if (await contentDir.exists()) {
        await contentDir.delete(recursive: true);
      }
      await contentDir.create(recursive: true);

      // 4. Baixar cada arquivo
      String? indexPath;
      for (int i = 0; i < files.length; i++) {
        final fileName = files[i];
        onProgress(i + 1, files.length, fileName);

        final success = await _downloadFile(
          remotePath: fileName,
          localDir: contentDir.path,
        );

        if (!success) {
          return SyncResult(
            status: SyncStatus.failed,
            error: 'Falha ao baixar o arquivo: $fileName',
          );
        }

        if (fileName == 'index.html' || indexPath == null) {
          indexPath = '${contentDir.path}/$fileName';
        }
      }

      // 5. Salvar versão e caminho localmente
      await prefs.setString(_prefVersion, remoteVersion);
      await prefs.setString(_prefIndexPath, indexPath!);

      return SyncResult(
        status: SyncStatus.updated,
        localIndexPath: indexPath,
      );
    } catch (e) {
      return SyncResult(
        status: SyncStatus.failed,
        error: 'Erro inesperado: $e',
      );
    }
  }

  /// Retorna o caminho local do index.html salvo anteriormente (se existir).
  static Future<String?> getCachedIndexPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefIndexPath);
    if (path == null) return null;
    final file = File(path);
    return (await file.exists()) ? path : null;
  }

  // ── Helpers privados ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> _fetchManifest() async {
    try {
      final uri = Uri.parse('$_baseUrl$_manifestPath');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> _downloadFile({
    required String remotePath,
    required String localDir,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$remotePath');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return false;

      final localFile = File('$localDir/$remotePath');
      await localFile.parent.create(recursive: true);
      await localFile.writeAsBytes(response.bodyBytes);
      return true;
    } catch (_) {
      return false;
    }
  }
}
