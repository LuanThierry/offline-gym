/// Regras locais de gamificação calculadas a partir das datas do histórico.
///
/// Não cria registros artificiais: cada dia contado precisa corresponder a ao
/// menos um treino já concluído e salvo no banco local (ou dia protegido com
/// Escudo de Ofensiva conquistado pelo usuário).
class OfensivaTreino {
  const OfensivaTreino._();

  static int calcularDiasConsecutivos(
    Iterable<DateTime> datasComTreino,
    DateTime referencia, {
    Iterable<DateTime> datasProtegidas = const <DateTime>[],
  }) {
    final diasTreino = datasComTreino.map(_somenteData).toSet();
    final diasEscudo = datasProtegidas.map(_somenteData).toSet();
    var dia = _somenteData(referencia);
    if (!diasTreino.contains(dia) && !diasEscudo.contains(dia)) {
      dia = dia.subtract(const Duration(days: 1));
    }
    if (!diasTreino.contains(dia) && !diasEscudo.contains(dia)) return 0;

    var total = 0;
    while (diasTreino.contains(dia) || diasEscudo.contains(dia)) {
      if (diasTreino.contains(dia)) {
        total++;
      }
      dia = dia.subtract(const Duration(days: 1));
    }
    return total;
  }

  static int contarDiasNaSemana(
    Iterable<DateTime> datasComTreino,
    DateTime referencia,
  ) {
    final referenciaSemHora = _somenteData(referencia);
    final inicio = referenciaSemHora.subtract(
      Duration(days: referenciaSemHora.weekday - DateTime.monday),
    );
    final fim = inicio.add(const Duration(days: 7));
    return datasComTreino
        .map(_somenteData)
        .where((dia) => !dia.isBefore(inicio) && dia.isBefore(fim))
        .toSet()
        .length;
  }

  static DateTime _somenteData(DateTime data) =>
      DateTime(data.year, data.month, data.day);
}
