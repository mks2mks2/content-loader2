import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/download_service.dart';
import 'password_screen.dart';
import 'webview_screen.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  _Phase _phase = _Phase.checking;
  int _current = 0;
  int _total = 0;
  String _currentFile = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    setState(() => _phase = _Phase.checking);

    final result = await DownloadService.sync(
      onProgress: (current, total, fileName) {
        if (!mounted) return;
        setState(() {
          _phase = _Phase.downloading;
          _current = current;
          _total = total;
          _currentFile = fileName;
        });
      },
    );

    if (!mounted) return;

    if (result.status == SyncStatus.failed) {
      final cached = await DownloadService.getCachedIndexPath();
      if (cached != null && mounted) {
        setState(() => _phase = _Phase.offlineWarning);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _goToPassword(cached);
      } else {
        setState(() {
          _phase = _Phase.error;
          _errorMessage = result.error ?? 'Erro desconhecido.';
        });
      }
      return;
    }

    setState(() => _phase = _Phase.done);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _goToPassword(result.localIndexPath!);
  }

  void _goToPassword(String localPath) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PasswordScreen(
          onSuccess: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => WebViewScreen(localPath: localPath),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_phase) {
      case _Phase.checking:
        return _buildChecking();
      case _Phase.downloading:
        return _buildDownloading();
      case _Phase.done:
        return _buildDone();
      case _Phase.offlineWarning:
        return _buildOfflineWarning();
      case _Phase.error:
        return _buildError();
    }
  }

  Widget _buildChecking() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogo(),
        const SizedBox(height: 48),
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
              color: AppTheme.accent, strokeWidth: 2.5),
        ),
        const SizedBox(height: 20),
        Text('Verificando atualizações...',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textSecondary, fontSize: 14)),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildDownloading() {
    final progress = _total > 0 ? _current / _total : 0.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogo(),
        const SizedBox(height: 48),
        Container(
          height: 6,
          decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(3)),
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.accent.withOpacity(0.5),
                        blurRadius: 8)
                  ],
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(_currentFile,
                  style: GoogleFonts.spaceMono(
                      color: AppTheme.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ),
            Text('$_current / $_total',
                style: GoogleFonts.spaceMono(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Text('${(progress * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.spaceMono(
                color: AppTheme.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Baixando conteúdo...',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogo(),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded,
              color: AppTheme.accent, size: 36),
        ),
        const SizedBox(height: 16),
        Text('Conteúdo atualizado!',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ],
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildOfflineWarning() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogo(),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.wifi_off_rounded,
              color: Colors.orange, size: 36),
        ),
        const SizedBox(height: 16),
        Text('Sem conexão',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Abrindo conteúdo salvo anteriormente...',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textSecondary, fontSize: 13)),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogo(),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.cloud_off_rounded,
              color: AppTheme.error, size: 36),
        ),
        const SizedBox(height: 20),
        Text('Não foi possível sincronizar',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(_errorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _phase = _Phase.checking;
              _current = 0;
              _total = 0;
            });
            _startSync();
          },
          icon: const Icon(Icons.refresh_rounded),
          label: Text('Tentar novamente',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.black,
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
          ),
          child: const Icon(Icons.language_rounded,
              color: AppTheme.accent, size: 32),
        ),
        const SizedBox(height: 16),
        Text('HTML VIEWER',
            style: GoogleFonts.spaceMono(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 3)),
      ],
    );
  }
}

enum _Phase { checking, downloading, done, offlineWarning, error }
