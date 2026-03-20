/// Gera e valida senhas com base na data e hora atual.
/// Formato: 3 números + 3 letras minúsculas (ex: 472abx)
/// A senha muda a cada 2 minutos.
class PasswordService {
  // Intervalo em minutos
  static const int _intervalMinutes = 2;

  // Chave secreta — altere para um valor único seu!
  // Use a mesma chave no gerador HTML.
  static const String _secretKey = 'MINHA_CHAVE_SECRETA_123';

  /// Retorna a senha válida para o momento atual.
  static String currentPassword() {
    return _generateFor(DateTime.now());
  }

  /// Valida se a senha digitada está correta.
  /// Aceita a senha do período atual e do período anterior
  /// (tolerância de 1 período para evitar problemas de timing).
  static bool validate(String input) {
    final now = DateTime.now();
    final current = _generateFor(now);
    final previous = _generateFor(
      now.subtract(Duration(minutes: _intervalMinutes)),
    );
    final cleaned = input.trim().toLowerCase();
    return cleaned == current || cleaned == previous;
  }

  /// Retorna quantos segundos faltam para a senha mudar.
  static int secondsUntilChange() {
    final now = DateTime.now();
    final secondsInPeriod = _intervalMinutes * 60;
    final elapsed = (now.minute % _intervalMinutes) * 60 + now.second;
    return secondsInPeriod - elapsed;
  }

  // ── Geração ───────────────────────────────────────────────────────────────

  static String _generateFor(DateTime dt) {
    // Calcular o "slot" de tempo — muda a cada _intervalMinutes
    final slot = (dt.hour * 60 + dt.minute) ~/ _intervalMinutes;

    // Montar a semente: data + slot + chave secreta
    final seed = '${dt.year}${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}'
        '${slot.toString().padLeft(4, '0')}'
        '$_secretKey';

    // Hash simples determinístico (não criptográfico, mas suficiente)
    int hash = 5381;
    for (final char in seed.codeUnits) {
      hash = ((hash << 5) + hash) ^ char;
      hash = hash & 0x7FFFFFFF; // manter positivo 31 bits
    }

    // Derivar 3 números (000–999)
    final n1 = hash % 10;
    final n2 = (hash ~/ 10) % 10;
    final n3 = (hash ~/ 100) % 10;

    // Derivar 3 letras minúsculas (a–z)
    const letters = 'abcdefghijklmnopqrstuvwxyz';
    final l1 = letters[(hash ~/ 1000) % 26];
    final l2 = letters[(hash ~/ 10000) % 26];
    final l3 = letters[(hash ~/ 100000) % 26];

    return '$n1$n2$n3$l1$l2$l3';
  }
}
