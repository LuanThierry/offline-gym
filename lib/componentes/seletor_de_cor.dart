import 'package:flutter/material.dart';

/// Modal e diálogo avançado para seleção de cor personalizada (Color Picker)
/// com paleta neon esportiva, espectro livre de matiz (HSV) e campo hexadecimal.
class DialogoSeletorDeCor extends StatefulWidget {
  const DialogoSeletorDeCor({
    super.key,
    required this.corInicial,
    this.titulo = 'Escolha sua Cor Neon',
  });

  final Color corInicial;
  final String titulo;

  static Future<Color?> abrir(
    BuildContext context, {
    Color? corInicial,
    String titulo = 'Escolha sua Cor Neon',
  }) {
    return showDialog<Color>(
      context: context,
      builder: (ctx) => DialogoSeletorDeCor(
        corInicial: corInicial ?? const Color(0xFF7C4DFF),
        titulo: titulo,
      ),
    );
  }

  @override
  State<DialogoSeletorDeCor> createState() => _DialogoSeletorDeCorState();
}

class _DialogoSeletorDeCorState extends State<DialogoSeletorDeCor> {
  late Color _corAtual;
  late double _hue;
  late double _saturation;
  late double _value;
  late final TextEditingController _hexController;

  static const List<Color> _coresEsportivasNeon = <Color>[
    // Roxos e Violetas
    Color(0xFF7C4DFF),
    Color(0xFF9D4EDD),
    Color(0xFF6C5CE7),
    Color(0xFFB388FF),
    // Verdes e Volt
    Color(0xFF00E676),
    Color(0xFF00FF88),
    Color(0xFF00C853),
    Color(0xFFCCFF00),
    Color(0xFFA6FF00),
    // Cianos e Turquesas
    Color(0xFF00E5FF),
    Color(0xFF18FFFF),
    Color(0xFF00BFA5),
    Color(0xFF00F5D4),
    // Azuis Elétricos
    Color(0xFF2979FF),
    Color(0xFF0066FF),
    Color(0xFF448AFF),
    Color(0xFF82B1FF),
    // Vermelhos e Carmim
    Color(0xFFFF1744),
    Color(0xFFFF5252),
    Color(0xFFFF2E63),
    Color(0xFFE91E63),
    // Rosas e Magentas
    Color(0xFFFF007F),
    Color(0xFFF72585),
    Color(0xFFFF4081),
    Color(0xFFEA00D9),
    // Laranjas e Âmbar
    Color(0xFFFF6D00),
    Color(0xFFFF9100),
    Color(0xFFFFAB00),
    Color(0xFFFFB300),
    Color(0xFFFFD600),
    // Monocromáticos e Titânio
    Color(0xFF546E7A),
    Color(0xFF78909C),
    Color(0xFF90A4AE),
    Color(0xFFECEFF1),
  ];

  @override
  void initState() {
    super.initState();
    _corAtual = widget.corInicial;
    final hsv = HSVColor.fromColor(_corAtual);
    _hue = hsv.hue;
    _saturation = hsv.saturation == 0 ? 0.9 : hsv.saturation;
    _value = hsv.value == 0 ? 0.95 : hsv.value;
    _hexController = TextEditingController(text: _colorToHex(_corAtual));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _atualizarCor(Color novaCor, {bool atualizarHex = true}) {
    setState(() {
      _corAtual = novaCor;
      final hsv = HSVColor.fromColor(novaCor);
      _hue = hsv.hue;
      _saturation = hsv.saturation == 0 ? 0.9 : hsv.saturation;
      _value = hsv.value == 0 ? 0.95 : hsv.value;
      if (atualizarHex) {
        _hexController.text = _colorToHex(novaCor);
      }
    });
  }

  void _atualizarDeHSV() {
    final novaCor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    setState(() {
      _corAtual = novaCor;
      _hexController.text = _colorToHex(novaCor);
    });
  }

  void _aplicarHex(String valor) {
    final limpo = valor.replaceAll('#', '').trim();
    if (limpo.length == 6) {
      final corInt = int.tryParse('FF$limpo', radix: 16);
      if (corInt != null) {
        _atualizarCor(Color(corInt), atualizarHex: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF14141C) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _corAtual.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _corAtual.withValues(alpha: 0.45),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(Icons.palette_rounded, color: _corAtual, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.titulo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Prévia da cor e Efeito Neon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0E0E14) : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _corAtual.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _corAtual.withValues(alpha: 0.25),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Amostra circular brilhante
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _corAtual,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _corAtual.withValues(alpha: 0.8),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Brilho Neon Ativo',
                            style: TextStyle(
                              color: _corAtual,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Código: ${_colorToHex(_corAtual)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Controle deslizante de Matiz (Hue)
              Row(
                children: [
                  const Icon(Icons.color_lens_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Espectro de Cores (0° a 360°)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF0000),
                      Color(0xFFFFFF00),
                      Color(0xFF00FF00),
                      Color(0xFF00FFFF),
                      Color(0xFF0000FF),
                      Color(0xFFFF00FF),
                      Color(0xFFFF0000),
                    ],
                  ),
                ),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 26,
                    trackShape: const RoundedRectSliderTrackShape(),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 15,
                      elevation: 4,
                    ),
                    thumbColor: Colors.white,
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                  ),
                  child: Slider(
                    value: _hue,
                    min: 0,
                    max: 360,
                    onChanged: (val) {
                      _hue = val;
                      _atualizarDeHSV();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Controle de Saturação / Intensidade Neon
              Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Vibração & Intensidade: ${(_saturation * 100).round()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _saturation,
                min: 0.3,
                max: 1.0,
                activeColor: _corAtual,
                onChanged: (val) {
                  _saturation = val;
                  _atualizarDeHSV();
                },
              ),
              const SizedBox(height: 12),

              // Paleta de Atalhos Rápidos Neon Esportivos
              Text(
                'Paleta Neon Rápida',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: _coresEsportivasNeon.map((c) {
                  final isSelected = c.toARGB32() == _corAtual.toARGB32();
                  return GestureDetector(
                    onTap: () => _atualizarCor(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Campo Hexadecimal
              TextField(
                controller: _hexController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 7,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: 'Código Hexadecimal',
                  prefixIcon: Icon(Icons.tag_rounded, color: _corAtual),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    tooltip: 'Aplicar Hex',
                    onPressed: () => _aplicarHex(_hexController.text),
                  ),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: _aplicarHex,
              ),
              const SizedBox(height: 22),

              // Botões de Ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _corAtual,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: _corAtual.withValues(alpha: 0.6),
                      ),
                      onPressed: () => Navigator.of(context).pop(_corAtual),
                      child: const Text(
                        'Aplicar Cor',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
