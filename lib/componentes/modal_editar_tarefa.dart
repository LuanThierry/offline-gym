import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../modelos/habito.dart';

class ModalEditarTarefa extends StatefulWidget {
  const ModalEditarTarefa({super.key, this.tarefa});

  final TarefaToDo? tarefa;

  static Future<TarefaToDo?> exibir(BuildContext context,
      {TarefaToDo? tarefa}) {
    return showModalBottomSheet<TarefaToDo>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: ModalEditarTarefa(tarefa: tarefa),
      ),
    );
  }

  @override
  State<ModalEditarTarefa> createState() => _EstadoDoModalEditarTarefa();
}

class _EstadoDoModalEditarTarefa extends State<ModalEditarTarefa> {
  final _tituloController = TextEditingController();
  String _prioridade = 'media';
  String _categoria = 'Geral';
  DateTime? _dataLimite;

  @override
  void initState() {
    super.initState();
    final t = widget.tarefa;
    if (t != null) {
      _tituloController.text = t.titulo;
      _prioridade = t.prioridade;
      _categoria = t.categoria;
      if (t.dataLimiteISO != null) {
        _dataLimite = DateTime.tryParse(t.dataLimiteISO!);
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataLimite ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dataLimite = picked);
    }
  }

  void _salvar() {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o que precisa ser feito.')),
      );
      return;
    }

    final novaOuAtualizada = (widget.tarefa ??
            TarefaToDo(
              titulo: titulo,
              dataCriacaoISO: DateTime.now().toIso8601String(),
            ))
        .copiarCom(
      titulo: titulo,
      prioridade: _prioridade,
      categoria: _categoria,
      dataLimiteISO: _dataLimite?.toIso8601String(),
      limparDataLimite: _dataLimite == null,
    );

    Navigator.of(context).pop(novaOuAtualizada);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoje = DateTime.now();
    final hojeZero = DateTime(hoje.year, hoje.month, hoje.day);
    final amanhaZero = hojeZero.add(const Duration(days: 1));
    final proxSemanaZero = hojeZero.add(const Duration(days: 7));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.tarefa == null ? 'Nova Tarefa' : 'Editar Tarefa',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Título da tarefa
          TextField(
            controller: _tituloController,
            textCapitalization: TextCapitalization.sentences,
            autofocus: widget.tarefa == null,
            decoration: const InputDecoration(
              labelText: 'O que precisa fazer? *',
              hintText: 'Ex: Comprar creatina, Agendar avaliação...',
            ),
          ),
          const SizedBox(height: 18),

          // Prioridade
          Text(
            'Prioridade',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPrioridadeChip('baixa', 'Baixa', const Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              _buildPrioridadeChip('media', 'Média', const Color(0xFFFF9800)),
              const SizedBox(width: 8),
              _buildPrioridadeChip('alta', 'Alta', const Color(0xFFFF5252)),
            ],
          ),
          const SizedBox(height: 18),

          // Data limite com atalhos rápidos
          Text(
            'Prazo (opcional)',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  label: const Text('Hoje'),
                  onPressed: () => setState(() => _dataLimite = hojeZero),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Amanhã'),
                  onPressed: () => setState(() => _dataLimite = amanhaZero),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Daqui a 7 dias'),
                  onPressed: () => setState(() => _dataLimite = proxSemanaZero),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: const Text('Calendário...'),
                  onPressed: _escolherData,
                ),
              ],
            ),
          ),
          if (_dataLimite != null) ...[
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                Icons.event_available_rounded,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Prazo definido: ${DateFormat('dd/MM/yyyy').format(_dataLimite!)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: IconButton(
                tooltip: 'Remover prazo',
                icon: const Icon(Icons.clear_rounded, size: 20),
                onPressed: () => setState(() => _dataLimite = null),
              ),
              onTap: _escolherData,
            ),
          ],
          const SizedBox(height: 20),

          // Botão Salvar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                widget.tarefa == null
                    ? 'Adicionar Tarefa'
                    : 'Salvar Alterações',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioridadeChip(String valor, String label, Color cor) {
    final isSelected = _prioridade == valor;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: cor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? cor : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? cor : Theme.of(context).colorScheme.outlineVariant,
      ),
      onSelected: (val) {
        if (val) setState(() => _prioridade = valor);
      },
    );
  }
}
