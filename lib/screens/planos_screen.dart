import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/workout_plan_model.dart';
import '../providers/workout_provider.dart';

import '../widgets/theme_toggle_button.dart';

class PlanosScreen extends StatelessWidget {
  const PlanosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planos da semana'),
        actions: const [ThemeToggleButton()],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(34),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Organize seus exercícios por dia.',
                style: TextStyle(color: Color(0xFF636E72)),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          if (!provider.initialized && provider.lastError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(provider.lastError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: provider.retryInitialization,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final weekday = index + 1;
              final dayExercises = provider.plansForDay(weekday);
              return _DayPlanCard(
                weekday: weekday,
                exercises: dayExercises,
                onPressed: () => _editDay(context, weekday, dayExercises),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editDay(
    BuildContext context,
    int weekday,
    List<WorkoutPlanModel> exercises,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
        child: DayPlanEditorSheet(
          weekday: weekday,
          initialExercises: exercises,
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${WorkoutPlanModel.weekdayName(weekday)} atualizado.'),
        ),
      );
    }
  }
}

class _DayPlanCard extends StatelessWidget {
  const _DayPlanCard({
    required this.weekday,
    required this.exercises,
    required this.onPressed,
  });

  final int weekday;
  final List<WorkoutPlanModel> exercises;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasExercises = exercises.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      WorkoutPlanModel.weekdayName(weekday).substring(0, 1),
                      style: const TextStyle(
                        color: Color(0xFF6C5CE7),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    WorkoutPlanModel.weekdayName(weekday),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (hasExercises)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${exercises.length} ${exercises.length == 1 ? 'exercício' : 'exercícios'}',
                      style: const TextStyle(
                        color: Color(0xFF238754),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!hasExercises)
              const Text(
                'Nenhum exercício adicionado',
                style: TextStyle(color: Color(0xFF636E72)),
              )
            else
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: exercises
                    .map((exercise) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F4FF),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          exercise.nome,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5144B5),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(hasExercises ? Icons.edit_outlined : Icons.add),
                label: Text(
                  hasExercises ? 'Editar treino' : 'Adicionar Exercícios',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DayPlanEditorSheet extends StatefulWidget {
  const DayPlanEditorSheet({
    super.key,
    required this.weekday,
    required this.initialExercises,
  });

  final int weekday;
  final List<WorkoutPlanModel> initialExercises;

  @override
  State<DayPlanEditorSheet> createState() => _DayPlanEditorSheetState();
}

class _DayPlanEditorSheetState extends State<DayPlanEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  late List<_ExerciseDraft> _drafts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _drafts = widget.initialExercises.map(_ExerciseDraft.fromPlan).toList();
    if (_drafts.isEmpty) _drafts.add(_ExerciseDraft.empty());
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addDraft() => setState(() => _drafts.add(_ExerciseDraft.empty()));

  void _removeDraft(int index) {
    late final _ExerciseDraft removed;
    setState(() => removed = _drafts.removeAt(index));
    // Let TextFormField unmount before disposing the controllers it used.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  Future<void> _chooseImage(int index) async {
    final draft = _drafts[index];
    try {
      // Do not pass imageQuality/maxWidth: GIF animation and original quality
      // must be preserved. Android's system photo picker opens locally.
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;

      final extension = p
          .extension(picked.name.isNotEmpty ? picked.name : picked.path)
          .toLowerCase();
      const allowedExtensions = <String>{
        '.gif',
        '.png',
        '.jpg',
        '.jpeg',
        '.webp',
      };
      if (!allowedExtensions.contains(extension)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escolha um arquivo GIF, PNG, JPG, JPEG ou WEBP.'),
          ),
        );
        return;
      }

      final fileSize = await picked.length();
      if (!mounted) return;
      const maxBytes = 15 * 1024 * 1024;
      if (fileSize > maxBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O arquivo deve ter no máximo 15 MB.')),
        );
        return;
      }
      if (fileSize == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O arquivo selecionado está vazio.')),
        );
        return;
      }

      final documents = await getApplicationDocumentsDirectory();
      final mediaDirectory = Directory(p.join(documents.path, 'exercise_gifs'));
      await mediaDirectory.create(recursive: true);
      final fileName =
          'exercise_${DateTime.now().microsecondsSinceEpoch}$extension';
      final destination = File(p.join(mediaDirectory.path, fileName));
      await File(picked.path).copy(destination.path);
      if (!mounted) return;

      setState(() {
        draft.caminhoLocalGif = destination.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagem salva no celular para uso offline.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível selecionar a imagem: $error')),
      );
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_drafts.isNotEmpty && !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final exercises = _drafts
        .map((draft) {
          final parsedLoad =
              double.tryParse(
                draft.loadController.text.trim().replaceAll(',', '.'),
              ) ??
              0;
          return WorkoutPlanModel(
            diaSemana: widget.weekday,
            nome: draft.nameController.text.trim(),
            carga: parsedLoad,
            series: int.tryParse(draft.seriesController.text.trim()) ?? 3,
            repeticoes:
                int.tryParse(draft.repetitionsController.text.trim()) ?? 10,
            // Retain no remote URL. Existing legacy urlGif values are not reused.
            urlGif: null,
            caminhoLocalGif: draft.caminhoLocalGif,
          );
        })
        .toList(growable: false);

    try {
      await context.read<WorkoutProvider>().saveDayExercises(
        widget.weekday,
        exercises,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o treino: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayName = WorkoutPlanModel.weekdayName(widget.weekday);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        dayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Adicione, edite ou remova exercícios.',
                        style: TextStyle(
                          color: Color(0xFF636E72),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                itemCount: _drafts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, itemIndex) {
                  final draft = _drafts[itemIndex];
                  final hasSavedImage =
                      draft.caminhoLocalGif != null &&
                      File(draft.caminhoLocalGif!).existsSync();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Exercício ${itemIndex + 1}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remover exercício',
                                onPressed: _saving
                                    ? null
                                    : () => _removeDraft(itemIndex),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Color(0xFFD63031),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: draft.nameController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Nome do Exercício *',
                              hintText: 'Ex.: Supino reto',
                              prefixIcon: Icon(Icons.fitness_center),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Informe o nome do exercício.'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextFormField(
                                  controller: draft.loadController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Carga (kg)',
                                  ),
                                  validator: (value) {
                                    final parsed = double.tryParse(
                                      (value ?? '').replaceAll(',', '.'),
                                    );
                                    if (parsed == null || parsed < 0) {
                                      return 'Use 0 ou mais.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: draft.seriesController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Séries',
                                  ),
                                  validator: (value) {
                                    final parsed = int.tryParse(value ?? '');
                                    if (parsed == null ||
                                        parsed < 1 ||
                                        parsed > 30) {
                                      return 'Use 1 a 30.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: draft.repetitionsController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Repetições',
                                  ),
                                  validator: (value) {
                                    final parsed = int.tryParse(value ?? '');
                                    if (parsed == null ||
                                        parsed < 1 ||
                                        parsed > 500) {
                                      return 'Use 1 a 500.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _saving
                                ? null
                                : () => _chooseImage(itemIndex),
                            icon: Icon(
                              hasSavedImage
                                  ? Icons.check_circle
                                  : Icons.image_search_outlined,
                            ),
                            label: Text(
                              hasSavedImage
                                  ? 'Foto/GIF salvo para uso offline'
                                  : 'Escolher foto/GIF da galeria (opcional)',
                            ),
                          ),
                          if (hasSavedImage) ...<Widget>[
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.offline_pin,
                                  size: 17,
                                  color: Color(0xFF238754),
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Imagem disponível localmente',
                                    style: TextStyle(
                                      color: Color(0xFF238754),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => setState(() {
                                    draft.caminhoLocalGif = null;
                                  }),
                                  child: const Text('Remover imagem'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE6E7EF))),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _addDraft,
                    child: const Text('Adicionar Mais'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_saving ? 'Salvando...' : 'Concluído'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseDraft {
  _ExerciseDraft({
    required this.nameController,
    required this.loadController,
    required this.seriesController,
    required this.repetitionsController,
    this.caminhoLocalGif,
  });

  final TextEditingController nameController;
  final TextEditingController loadController;
  final TextEditingController seriesController;
  final TextEditingController repetitionsController;
  String? caminhoLocalGif;

  factory _ExerciseDraft.empty() => _ExerciseDraft(
    nameController: TextEditingController(),
    loadController: TextEditingController(text: '0'),
    seriesController: TextEditingController(text: '3'),
    repetitionsController: TextEditingController(text: '10'),
  );

  factory _ExerciseDraft.fromPlan(WorkoutPlanModel plan) => _ExerciseDraft(
    nameController: TextEditingController(text: plan.nome),
    loadController: TextEditingController(text: _numberText(plan.carga)),
    seriesController: TextEditingController(text: plan.series.toString()),
    repetitionsController: TextEditingController(
      text: plan.repeticoes.toString(),
    ),
    caminhoLocalGif: plan.caminhoLocalGif,
  );

  void dispose() {
    nameController.dispose();
    loadController.dispose();
    seriesController.dispose();
    repetitionsController.dispose();
  }

  static String _numberText(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
}
