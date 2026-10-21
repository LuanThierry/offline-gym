import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../modelos/plano_de_treino.dart';
import '../provedores/estado_treino.dart';
import '../servicos/notificacoes_de_treino.dart';
import '../componentes/botao_de_configuracoes.dart';
import '../componentes/foto_de_perfil_com_ofensiva.dart';
import '../dominio/sistema_gamificacao.dart';
import '../dominio/calculadora_nutricional.dart';
import '../componentes/modal_conquista_ofensiva.dart';

class TelaDePerfil extends StatefulWidget {
  const TelaDePerfil({super.key, this.isFirstUse = false});

  final bool isFirstUse;

  @override
  State<TelaDePerfil> createState() => _EstadoDaTelaDePerfil();
}

class _EstadoDaTelaDePerfil extends State<TelaDePerfil> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _goalWeightController = TextEditingController();
  final _heightController = TextEditingController();
  String _objective = 'Hipertrofia';
  String _experienceLevel = 'Iniciante';
  String _sex = 'Masculino';
  double _activityFactor = 1.55;
  bool _editing = false;
  bool _saving = false;
  bool _remindersEnabled = true;
  String? _photoPath;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    final provedor = context.read<ProvedorDeTreino>();
    final perfil = provedor.perfil;
    _editing = widget.isFirstUse || perfil == null;
    _nameController.text = perfil?.nome ?? '';
    _ageController.text = perfil?.idade?.toString() ?? '';
    final height = perfil?.alturaCm;
    _heightController.text = height == null ? '' : _textoNumerico(height);
    final weight = provedor.pesoCorporalAtualKg;
    _weightController.text = weight == null ? '' : _textoNumerico(weight);
    _goalWeightController.text =
        perfil?.metaPesoKg == null ? '' : _textoNumerico(perfil!.metaPesoKg!);
    _objective = _normalizarObjetivo(perfil?.objetivoPrincipal);
    _experienceLevel = _normalizarExperiencia(perfil?.nivelExperiencia);
    _sex = perfil?.sexo ?? 'Masculino';
    _activityFactor = perfil?.fatorAtividade ?? 1.55;
    _photoPath = perfil?.caminhoFoto;
    _remindersEnabled = perfil?.lembretesAtivos ?? true;
    _reminderTime = TimeOfDay(
      hour: perfil?.horaLembrete ?? 9,
      minute: perfil?.minutoLembrete ?? 0,
    );
  }

  static String _normalizarObjetivo(String? valor) {
    final v = (valor ?? '').trim();
    if (v.startsWith('Emagrecimento')) return 'Emagrecimento / Definição';
    if (v.startsWith('Força')) return 'Força Bruta';
    if (v.startsWith('Saúde')) return 'Saúde & Consistência';
    return 'Hipertrofia';
  }

  static String _normalizarExperiencia(String? valor) {
    const validos = {'Iniciante', 'Intermediário', 'Avançado'};
    if (valor != null && validos.contains(valor)) return valor;
    return 'Iniciante';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _goalWeightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  String _textoNumerico(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  Future<void> _escolherFoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1200,
      );
      if (picked == null || !mounted) return;
      final documents = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(documents.path, 'profile_images'));
      await folder.create(recursive: true);
      final extension = p.extension(picked.path).isEmpty
          ? '.jpg'
          : p.extension(picked.path).toLowerCase();
      final destination = File(
        p.join(
          folder.path,
          'profile_${DateTime.now().microsecondsSinceEpoch}$extension',
        ),
      );
      await destination.writeAsBytes(await picked.readAsBytes(), flush: true);
      final previousPhotoPath = _photoPath;
      if (previousPhotoPath != null && previousPhotoPath != destination.path) {
        try {
          final oldFile = File(previousPhotoPath);
          if (oldFile.existsSync() && oldFile.path.contains('profile_images')) {
            await oldFile.delete();
          }
        } catch (_) {}
      }
      if (mounted) setState(() => _photoPath = destination.path);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível escolher a foto: $erro')),
      );
    }
  }

  Future<void> _escolherHorarioDoLembrete() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: 'Escolha o horário do lembrete',
    );
    if (time != null && mounted) setState(() => _reminderTime = time);
  }

  Future<void> _salvar() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite seu nome para continuar.')),
      );
      return;
    }
    final ageText = _ageController.text.trim();
    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    if (ageText.isNotEmpty && (age == null || age < 1 || age > 120)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma idade válida.')),
      );
      return;
    }
    final weightText = _weightController.text.trim().replaceAll(',', '.');
    final weight = weightText.isEmpty ? null : double.tryParse(weightText);
    if (weightText.isNotEmpty &&
        (weight == null || weight <= 0 || weight > 500)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um peso corporal válido.')),
      );
      return;
    }
    final goalWeightText =
        _goalWeightController.text.trim().replaceAll(',', '.');
    final goalWeight =
        goalWeightText.isEmpty ? null : double.tryParse(goalWeightText);
    if (goalWeightText.isNotEmpty &&
        (goalWeight == null || goalWeight <= 0 || goalWeight > 500)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma meta de peso válida.')),
      );
      return;
    }

    final heightText = _heightController.text.trim().replaceAll(',', '.');
    final height = heightText.isEmpty ? null : double.tryParse(heightText);
    if (heightText.isNotEmpty &&
        (height == null || height < 50 || height > 280)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe uma altura válida em cm (ex: 175).'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final fotoAnterior = context.read<ProvedorDeTreino>().perfil?.caminhoFoto;
      final remindersEnabled = _remindersEnabled;
      final provedor = context.read<ProvedorDeTreino>();
      if (remindersEnabled) {
        try {
          await ServicoDeNotificacoesDeTreino.instance.solicitarPermissao();
        } catch (_) {
          // Falha de permissão de notificação não impede salvar o perfil;
          // a pessoa pode alterar essa preferência depois.
        }
      }
      if (!mounted) return;
      await provedor.salvarPerfil(
        PerfilDoUsuario(
          nome: name,
          idade: age,
          caminhoFoto: _photoPath,
          lembretesAtivos: remindersEnabled,
          horaLembrete: _reminderTime.hour,
          minutoLembrete: _reminderTime.minute,
          metaPesoKg: goalWeight,
          objetivoPrincipal: _objective,
          nivelExperiencia: _experienceLevel,
          onboardingConcluido: true,
          alturaCm: height,
          sexo: _sex,
          fatorAtividade: _activityFactor,
        ),
        currentWeightKg: weight,
      );
      if (fotoAnterior != null && fotoAnterior != _photoPath) {
        await _excluirFotoAnterior(fotoAnterior);
      }
      if (!mounted) return;
      if (widget.isFirstUse) {
        // O contêiner principal abre a próxima etapa ou as abas do aplicativo.
        setState(() => _editing = false);
      } else {
        Navigator.of(context).pop();
      }
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o perfil: $erro')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _excluirFotoAnterior(String caminho) async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      final pasta = p.normalize(p.join(documents.path, 'profile_images'));
      final arquivo = p.normalize(caminho);
      if (p.isWithin(pasta, arquivo) && await File(arquivo).exists()) {
        await File(arquivo).delete();
      }
    } on FileSystemException {
      // A limpeza é oportunista e não deve impedir o salvamento do perfil.
    }
  }

  @override
  Widget build(BuildContext context) {
    final provedor = context.watch<ProvedorDeTreino>();
    final perfil = provedor.perfil;
    final editable = _editing || perfil == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstUse ? 'Seu perfil' : 'Perfil'),
        automaticallyImplyLeading: !widget.isFirstUse,
        actions: widget.isFirstUse
            ? const <Widget>[]
            : const <Widget>[BotaoDeConfiguracoes()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: <Widget>[
            Center(
              child: FotoDePerfilComOfensiva(
                caminhoFoto: _photoPath,
                diasSeguidos: provedor.ofensivaAtual,
                diametro: 112,
                permiteEditar: editable,
                aoEditar: _escolherFoto,
              ),
            ),
            const SizedBox(height: 22),
            if (!editable) ...<Widget>[
              Center(
                child: Text(
                  perfil.nome,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (editable) ...<Widget>[
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Seu nome'),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _ageController,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Idade',
                        suffixText: 'anos',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      enabled: !_saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Peso atual',
                        suffixText: 'kg',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _goalWeightController,
                      enabled: !_saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Meta de peso',
                        suffixText: 'kg',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _experienceLevel,
                      decoration: const InputDecoration(
                        labelText: 'Experiência',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Iniciante',
                          child: Text('Iniciante'),
                        ),
                        DropdownMenuItem(
                          value: 'Intermediário',
                          child: Text('Intermediário'),
                        ),
                        DropdownMenuItem(
                          value: 'Avançado',
                          child: Text('Avançado'),
                        ),
                      ],
                      onChanged: _saving
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _experienceLevel = val);
                              }
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _objective,
                decoration: const InputDecoration(
                  labelText: 'Objetivo principal',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Hipertrofia',
                    child: Text('Ganho de massa muscular (Hipertrofia)'),
                  ),
                  DropdownMenuItem(
                    value: 'Emagrecimento / Definição',
                    child: Text('Perda de gordura & Definição'),
                  ),
                  DropdownMenuItem(
                    value: 'Força Bruta',
                    child: Text('Ganho de força & Performance'),
                  ),
                  DropdownMenuItem(
                    value: 'Saúde & Consistência',
                    child: Text('Saúde geral, longevidade & rotina'),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() => _objective = val);
                        }
                      },
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      enabled: !_saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Altura',
                        suffixText: 'cm',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _sex,
                      decoration: const InputDecoration(
                        labelText: 'Sexo biológico',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Masculino',
                          child: Text('Masculino'),
                        ),
                        DropdownMenuItem(
                          value: 'Feminino',
                          child: Text('Feminino'),
                        ),
                      ],
                      onChanged: _saving
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _sex = val);
                              }
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<double>(
                isExpanded: true,
                initialValue: _activityFactor,
                decoration: const InputDecoration(
                  labelText: 'Nível de atividade diária',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 1.2,
                    child: Text('Sedentário (pouco exercício)'),
                  ),
                  DropdownMenuItem(
                    value: 1.375,
                    child: Text('Levemente Ativo (1 a 3 dias/sem)'),
                  ),
                  DropdownMenuItem(
                    value: 1.55,
                    child: Text('Moderadamente Ativo (3 a 5 dias/sem)'),
                  ),
                  DropdownMenuItem(
                    value: 1.725,
                    child: Text('Muito Ativo (6 a 7 dias/sem)'),
                  ),
                  DropdownMenuItem(
                    value: 1.9,
                    child: Text('Extremamente Ativo (atleta / pesado)'),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() => _activityFactor = val);
                        }
                      },
              ),
            ] else ...<Widget>[
              Row(
                children: [
                  Expanded(
                    child: _ValorDoPerfil(
                      label: 'Idade',
                      value: perfil.idade == null
                          ? 'Não informado'
                          : '${perfil.idade} anos',
                    ),
                  ),
                  Expanded(
                    child: _ValorDoPerfil(
                      label: 'Nível',
                      value: perfil.nivelExperiencia,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _ValorDoPerfil(
                      label: 'Peso atual',
                      value: provedor.pesoCorporalAtualKg == null
                          ? 'Não informado'
                          : '${_textoNumerico(provedor.pesoCorporalAtualKg!)} kg',
                    ),
                  ),
                  Expanded(
                    child: _ValorDoPerfil(
                      label: 'Meta de peso',
                      value: perfil.metaPesoKg == null
                          ? 'Não definida'
                          : '${_textoNumerico(perfil.metaPesoKg!)} kg',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _ValorDoPerfil(
                      label: 'Altura',
                      value: perfil.alturaCm == null
                          ? 'Não informada'
                          : '${_textoNumerico(perfil.alturaCm!)} cm',
                    ),
                  ),
                  Expanded(
                    child: _ValorDoPerfil(
                      label: 'Sexo',
                      value: perfil.sexo,
                    ),
                  ),
                ],
              ),
              _ValorDoPerfil(
                label: 'Objetivo principal',
                value: perfil.objetivoPrincipal,
              ),
            ],
            const SizedBox(height: 18),
            if (perfil != null) ...[
              _CardMetasNutricionais(
                perfil: perfil,
                pesoAtualKg: provedor.pesoCorporalAtualKg,
              ),
              const SizedBox(height: 14),
            ],
            Card(
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (provedor.ofensivaAtual == 0
                            ? Theme.of(context).colorScheme.primary
                            : SistemaGamificacao.obterClasseAtual(
                                provedor.ofensivaAtual,
                              ).cor)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    provedor.ofensivaAtual == 0
                        ? Icons.emoji_events_outlined
                        : SistemaGamificacao.obterClasseAtual(
                            provedor.ofensivaAtual,
                          ).icone,
                    color: provedor.ofensivaAtual == 0
                        ? Theme.of(context).colorScheme.primary
                        : SistemaGamificacao.obterClasseAtual(
                            provedor.ofensivaAtual,
                          ).cor,
                  ),
                ),
                title: Text(
                  'Nível & Conquistas · ${SistemaGamificacao.obterClasseAtual(provedor.ofensivaAtual).nome}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${provedor.ofensivaAtual} ${provedor.ofensivaAtual == 1 ? 'dia' : 'dias'} de ofensiva · ${provedor.historico.length} treinos concluídos',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => ModalConquistaOfensiva.exibir(
                  context,
                  diasSeguidos: provedor.ofensivaAtual,
                  totalTreinos: provedor.historico.length,
                  treinosNaSemana: provedor.treinosNaSemana(DateTime.now()),
                  acabouDeConcluir: false,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.stars_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text(
                  'Hábitos & Tarefas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${provedor.habitos.where((h) => h.ativo).length} hábitos ativos · ${provedor.tarefasPendentes.length} tarefas pendentes',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  provedor.solicitarAbrirHabitosHoje();
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Lembretes de treino',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Receber lembrete nos dias de treino'),
              value: _remindersEnabled,
              onChanged: editable && !_saving
                  ? (value) => setState(() => _remindersEnabled = value)
                  : null,
            ),
            if (_remindersEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Horário'),
                subtitle: Text(_reminderTime.format(context)),
                trailing: const Icon(Icons.schedule_rounded),
                enabled: editable && !_saving,
                onTap: editable && !_saving ? _escolherHorarioDoLembrete : null,
              ),
            if (editable) ...<Widget>[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _salvar,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Salvando...' : 'Salvar perfil'),
                ),
              ),
              if (!widget.isFirstUse && perfil != null) ...<Widget>[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed:
                        _saving ? null : () => setState(() => _editing = false),
                    child: const Text('Cancelar edição'),
                  ),
                ),
              ],
            ] else ...<Widget>[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Editar perfil'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ValorDoPerfil extends StatelessWidget {
  const _ValorDoPerfil({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: Theme.of(context).textTheme.bodySmall),
        subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _CardMetasNutricionais extends StatelessWidget {
  const _CardMetasNutricionais({
    required this.perfil,
    required this.pesoAtualKg,
  });

  final PerfilDoUsuario perfil;
  final double? pesoAtualKg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dadosIncompletos = pesoAtualKg == null || perfil.alturaCm == null;

    if (dadosIncompletos) {
      final faltaPeso = pesoAtualKg == null;
      final faltaAltura = perfil.alturaCm == null;
      final mensagemFalta = faltaPeso && faltaAltura
          ? 'Informe seu peso atual e sua altura no perfil'
          : faltaPeso
              ? 'Informe seu peso atual no perfil'
              : 'Informe sua altura no perfil';

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metas de Nutrição & Calorias',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'TMB / TDEE · Fórmula Mifflin-St Jeor',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.accessibility_new_rounded,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dados corporais pendentes',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$mensagemFalta para calcular com precisão sua Taxa Metabólica Basal (TMB), gasto diário (TDEE) e divisão de proteínas, carboidratos e gorduras.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final peso = pesoAtualKg!;
    final altura = perfil.alturaCm!;
    final idade = perfil.idade ?? 25;
    final sexo = perfil.sexo;
    final objetivo = perfil.objetivoPrincipal;
    final fator = perfil.fatorAtividade;

    final metas = CalculadoraNutricional.calcularMetas(
      pesoKg: peso,
      alturaCm: altura,
      idade: idade,
      sexo: sexo,
      objetivo: objetivo,
      fatorAtividade: fator,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metas de Nutrição & Calorias',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'TMB / TDEE · Fórmula Mifflin-St Jeor (Offline)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${metas.caloriasAlvoKcal.round()} kcal / dia',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Meta Diária (${metas.objetivo})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TMB: ${metas.tmbKcal.round()} kcal',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Gasto TDEE: ${metas.tdeeKcal.round()} kcal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Barra visual de divisão de macronutrientes
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(
                      flex: metas.percentualProteina.round().clamp(1, 100),
                      child: Container(color: theme.colorScheme.primary),
                    ),
                    Expanded(
                      flex: metas.percentualCarboidrato.round().clamp(1, 100),
                      child: Container(color: const Color(0xFF0984E3)),
                    ),
                    Expanded(
                      flex: metas.percentualGordura.round().clamp(1, 100),
                      child: Container(color: const Color(0xFFE17055)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ItemMacroNutriente(
                    titulo: 'Proteína',
                    quantidade: '${metas.proteinaGramas.round()}g',
                    percentual: '${metas.percentualProteina.round()}%',
                    cor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ItemMacroNutriente(
                    titulo: 'Carboidrato',
                    quantidade: '${metas.carboidratoGramas.round()}g',
                    percentual: '${metas.percentualCarboidrato.round()}%',
                    cor: const Color(0xFF0984E3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ItemMacroNutriente(
                    titulo: 'Gordura',
                    quantidade: '${metas.gorduraGramas.round()}g',
                    percentual: '${metas.percentualGordura.round()}%',
                    cor: const Color(0xFFE17055),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ItemMacroNutriente(
                    titulo: 'Água',
                    quantidade: '${metas.aguaLitros.toStringAsFixed(1)}L',
                    percentual: '35ml/kg',
                    cor: const Color(0xFF00B894),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Recomendações esportivas calculadas para o seu peso atual (${peso.toStringAsFixed(1)} kg) e nível de atividade.',
              style: TextStyle(
                fontSize: 11,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemMacroNutriente extends StatelessWidget {
  const _ItemMacroNutriente({
    required this.titulo,
    required this.quantidade,
    required this.percentual,
    required this.cor,
  });

  final String titulo;
  final String quantidade;
  final String percentual;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            quantidade,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            percentual,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
