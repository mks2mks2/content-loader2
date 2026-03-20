import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/password_service.dart';

class PasswordScreen extends StatefulWidget {
  /// Chamado quando a senha correta é digitada.
  final VoidCallback onSuccess;

  /// Se true, exibe mensagem de "internet reconectada"
  final bool internetReconnected;

  const PasswordScreen({
    super.key,
    required this.onSuccess,
    this.internetReconnected = false,
  });

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _countdownTimer;
  int _secondsLeft = 0;
  bool _wrongPassword = false;
  bool _shake = false;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _startTimer();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    setState(() {
      _secondsLeft = PasswordService.secondsUntilChange();
    });
  }

  void _submit() {
    final input = _controller.text.trim();
    if (PasswordService.validate(input)) {
      _countdownTimer?.cancel();
      widget.onSuccess();
    } else {
      setState(() {
        _wrongPassword = true;
        _shake = true;
      });
      _controller.clear();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _shake = false);
      });
    }
  }

  String _formatCountdown() {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone de cadeado
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: AppTheme.accent, size: 36),
                ).animate().fadeIn(duration: 400.ms).scale(
                    begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 24),

                Text(
                  'ACESSO RESTRITO',
                  style: GoogleFonts.spaceMono(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 10),

                // Mensagem de contexto
                Text(
                  widget.internetReconnected
                      ? 'Internet reconectada.\nDigite a senha para continuar.'
                      : 'Solicite a senha ao professor\npara acessar o conteúdo.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 40),

                // Campo de senha com animação de shake
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  transform: Matrix4.translationValues(
                      _shake ? 8.0 : 0.0, 0, 0),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                    maxLength: 6,
                    autocorrect: false,
                    enableSuggestions: false,
                    obscureText: false,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000aaa',
                      hintStyle: GoogleFonts.spaceMono(
                        color: AppTheme.textSecondary.withOpacity(0.4),
                        fontSize: 28,
                        letterSpacing: 8,
                      ),
                      filled: true,
                      fillColor: AppTheme.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _wrongPassword
                              ? AppTheme.error
                              : AppTheme.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _wrongPassword
                              ? AppTheme.error
                              : AppTheme.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _wrongPassword
                              ? AppTheme.error
                              : AppTheme.accent,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                    ),
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) {
                      if (_wrongPassword) {
                        setState(() => _wrongPassword = false);
                      }
                    },
                  ),
                ).animate().fadeIn(delay: 200.ms),

                // Mensagem de erro
                AnimatedOpacity(
                  opacity: _wrongPassword ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Senha incorreta. Tente novamente.',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botão confirmar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'CONFIRMAR',
                      style: GoogleFonts.spaceMono(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 32),

                // Contador regressivo
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_rounded,
                          color: AppTheme.textSecondary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Senha muda em ',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _formatCountdown(),
                        style: GoogleFonts.spaceMono(
                          color: _secondsLeft <= 20
                              ? AppTheme.error
                              : AppTheme.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
