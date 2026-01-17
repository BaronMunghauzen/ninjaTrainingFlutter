import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../models/exercise_model.dart';
import 'metal_button.dart';
import 'metal_table.dart';
import 'reps_weight_picker_modal.dart';
import 'package:my_app/providers/timer_overlay_provider.dart';
import 'package:provider/provider.dart';

/// Модель данных для строки упражнения
class UserExerciseRow {
  String? userExerciseUuid;
  int reps;
  double weight;
  String status;
  String lastResult;

  UserExerciseRow({
    this.userExerciseUuid,
    this.reps = 0,
    this.weight = 0.0,
    this.status = 'active',
    this.lastResult = '0',
  });
}

/// Виджет таблицы подходов для программ и тренировок
/// Используется для отображения и управления подходами упражнения
class ProgramExerciseSetsTable extends StatefulWidget {
  final ExerciseModel exercise;
  final List<UserExerciseRow> initialRows;
  final String? userUuid;
  final String? trainingDate;
  final String? programUuid;
  final String? trainingUuid;
  final bool isProgram; // true для программ, false для тренировок
  final bool isFreeWorkout; // true для свободных тренировок
  final Future<void> Function(int setNumber)? onLoadLastResult;
  final Function(List<UserExerciseRow>)? onRowsChanged;

  const ProgramExerciseSetsTable({
    super.key,
    required this.exercise,
    required this.initialRows,
    this.userUuid,
    this.trainingDate,
    this.programUuid,
    this.trainingUuid,
    this.isProgram = true, // По умолчанию для программ
    this.isFreeWorkout = false, // По умолчанию не свободная тренировка
    this.onLoadLastResult,
    this.onRowsChanged,
  });

  @override
  State<ProgramExerciseSetsTable> createState() =>
      _ProgramExerciseSetsTableState();
}

class _ProgramExerciseSetsTableState extends State<ProgramExerciseSetsTable> {
  late List<UserExerciseRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = List.from(
      widget.initialRows.map(
        (row) => UserExerciseRow(
          userExerciseUuid: row.userExerciseUuid,
          reps: row.reps,
          weight: row.weight,
          status: row.status,
          lastResult: row.lastResult,
        ),
      ),
    );

    // Для свободных тренировок загружаем все user_exercises при инициализации
    if (widget.isFreeWorkout) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAllUserExercises();
      });
    }
  }

  @override
  void didUpdateWidget(ProgramExerciseSetsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Всегда синхронизируем с initialRows, чтобы получать обновления из родительского виджета
    // Проверяем, изменилась ли длина или данные
    if (oldWidget.initialRows.length != widget.initialRows.length) {
      // Длина изменилась - полностью заменяем
      setState(() {
        _rows = List.from(
          widget.initialRows.map(
            (row) => UserExerciseRow(
              userExerciseUuid: row.userExerciseUuid,
              reps: row.reps,
              weight: row.weight,
              status: row.status,
              lastResult: row.lastResult,
            ),
          ),
        );
      });
    } else {
      // Проверяем, изменились ли элементы или их данные
      bool needsUpdate = false;
      for (int i = 0; i < widget.initialRows.length; i++) {
        if (i >= _rows.length) {
          needsUpdate = true;
          break;
        }
        final newRow = widget.initialRows[i];
        final currentRow = _rows[i];
        if (newRow.userExerciseUuid != currentRow.userExerciseUuid ||
            newRow.reps != currentRow.reps ||
            newRow.weight != currentRow.weight ||
            newRow.status != currentRow.status ||
            newRow.lastResult != currentRow.lastResult) {
          needsUpdate = true;
          break;
        }
      }

      if (needsUpdate) {
        setState(() {
          _rows = List.from(
            widget.initialRows.map(
              (row) => UserExerciseRow(
                userExerciseUuid: row.userExerciseUuid,
                reps: row.reps,
                weight: row.weight,
                status: row.status,
                lastResult: row.lastResult,
              ),
            ),
          );
        });
      }
    }
  }

  String _ending(int n, String one, String many, String few) {
    if (n % 10 == 1 && n % 100 != 11) return one;
    if ([2, 3, 4].contains(n % 10) && !(n % 100 >= 12 && n % 100 <= 14))
      return few;
    return many;
  }

  /// Парсит строку lastResult и извлекает значения повторений и веса
  Map<String, dynamic> _parseLastResult(String lastResult) {
    int reps = 0;
    double weight = 0.0;

    if (lastResult == '0' || lastResult.isEmpty) {
      return {'reps': reps, 'weight': weight};
    }

    final regex = RegExp(r'^(\d+)\s*x\s*([\d.]+)\s*кг$');
    final match = regex.firstMatch(lastResult.trim());

    if (match != null) {
      reps = int.tryParse(match.group(1) ?? '0') ?? 0;
      weight = double.tryParse(match.group(2) ?? '0') ?? 0.0;
    } else {
      reps = int.tryParse(lastResult.trim()) ?? 0;
    }

    return {'reps': reps, 'weight': weight};
  }

  /// Определяет начальные значения для модального окна ввода
  Map<String, dynamic> _getInitialValues(int setIndex) {
    if (setIndex == 0) {
      final lastResult = _rows[setIndex].lastResult;
      final parsed = _parseLastResult(lastResult);
      return {
        'reps': parsed['reps'] as int,
        'weight': parsed['weight'] as double,
      };
    }

    final previousRow = _rows[setIndex - 1];
    if (previousRow.reps > 0 || previousRow.weight > 0) {
      return {'reps': previousRow.reps, 'weight': previousRow.weight};
    }

    final lastResult = _rows[setIndex].lastResult;
    final parsed = _parseLastResult(lastResult);
    return {
      'reps': parsed['reps'] as int,
      'weight': parsed['weight'] as double,
    };
  }

  Future<void> _loadUserExercise(int setNumber) async {
    final userUuid = widget.userUuid ?? '';
    final trainingDate = widget.trainingDate ?? '';
    final programUuid = widget.programUuid;
    final trainingUuid = widget.trainingUuid ?? '';
    final exerciseUuid = widget.exercise.uuid;

    try {
      final queryParams = <String, String>{};

      // Для свободных тренировок загружаем только по exercise_uuid
      if (widget.isFreeWorkout) {
        queryParams['exercise_uuid'] = exerciseUuid;
        // Не добавляем set_number, training_date, training_uuid для свободных тренировок
      } else {
        queryParams['user_uuid'] = userUuid;
        queryParams['set_number'] = (setNumber + 1).toString();
        queryParams['exercise_uuid'] = exerciseUuid;
        queryParams['training_date'] = trainingDate;
        queryParams['training_uuid'] = trainingUuid;

        // Для программ добавляем program_uuid, для тренировок - нет
        if (widget.isProgram && programUuid != null) {
          queryParams['program_uuid'] = programUuid;
        }
      }

      final resp = await ApiService.get(
        '/user_exercises/',
        queryParams: queryParams,
      );

      if (resp.statusCode == 200 && mounted) {
        final data = ApiService.decodeJson(resp.body);

        // Для свободных тренировок обрабатываем список всех подходов
        if (widget.isFreeWorkout) {
          if (data is List && data.isNotEmpty) {
            // Сортируем по set_number
            final sorted = List<Map<String, dynamic>>.from(data);
            sorted.sort((a, b) {
              final setA = a['set_number'] ?? 0;
              final setB = b['set_number'] ?? 0;
              return setA.compareTo(setB);
            });

            // Обновляем все строки, которые есть в данных
            setState(() {
              for (int i = 0; i < sorted.length && i < _rows.length; i++) {
                final row = sorted[i];
                _rows[i] = UserExerciseRow(
                  userExerciseUuid: row['uuid'],
                  reps: row['reps'] ?? 0,
                  weight: (row['weight'] ?? 0).toDouble(),
                  status: row['status'] ?? 'active',
                  lastResult: _rows[i].lastResult,
                );
              }
            });
            widget.onRowsChanged?.call(_rows);
          }
        } else {
          // Для программ и обычных тренировок - стандартная логика
          if (data is List && data.isNotEmpty) {
            final row = data[0];
            setState(() {
              _rows[setNumber] = UserExerciseRow(
                userExerciseUuid: row['uuid'],
                reps: row['reps'] ?? 0,
                weight: (row['weight'] ?? 0).toDouble(),
                status: row['status'] ?? 'active',
                lastResult: _rows[setNumber].lastResult,
              );
            });
            widget.onRowsChanged?.call(_rows);
          } else {
            if (mounted) {
              setState(() {
                _rows[setNumber] = UserExerciseRow(
                  lastResult: _rows[setNumber].lastResult,
                );
              });
              widget.onRowsChanged?.call(_rows);
            }
          }
        }
      }
    } catch (_) {
      // Игнорируем ошибки
    }
  }

  void _showRepsWeightPicker(int setIndex, int maxReps, bool withWeight) async {
    final initialValues = _getInitialValues(setIndex);
    int initialReps = initialValues['reps'] as int;
    double initialWeight = initialValues['weight'] as double;

    await RepsWeightPickerModal.show(
      context: context,
      initialReps: initialReps,
      initialWeight: initialWeight,
      maxReps: maxReps,
      withWeight: withWeight,
      onSave: (reps, weight) {
        if (!mounted) return;
        setState(() {
          _rows[setIndex] = UserExerciseRow(
            userExerciseUuid: _rows[setIndex].userExerciseUuid,
            reps: reps,
            weight: weight,
            status: _rows[setIndex].status,
            lastResult: _rows[setIndex].lastResult,
          );
        });
        widget.onRowsChanged?.call(_rows);
      },
    );
  }

  Future<void> _onSetCompleted(int setIdx, {bool? value}) async {
    final row = _rows[setIdx];
    final userUuid = widget.userUuid ?? '';
    final trainingDate = widget.trainingDate ?? '';
    final programUuid = widget.programUuid;
    final trainingUuid = widget.trainingUuid ?? '';
    final exerciseUuid = widget.exercise.uuid;

    if (value == false && row.userExerciseUuid != null) {
      await ApiService.delete('/user_exercises/delete/${row.userExerciseUuid}');

      // Для программ и тренировок (не свободных) отменяем таймер при снятии галочки
      if (!widget.isFreeWorkout && userUuid.isNotEmpty) {
        await FCMService.cancelTimerOnBackend(userUuid: userUuid);
      }

      if (widget.isFreeWorkout) {
        // Для свободных тренировок перезагружаем все подходы
        await _loadAllUserExercises();
      } else {
        await _loadUserExercise(setIdx);
      }
      return;
    }

    final body = <String, dynamic>{
      'user_uuid': userUuid,
      'exercise_uuid': exerciseUuid,
      'status': 'active',
      'set_number': setIdx + 1,
      'reps': row.reps,
    };

    // Для свободных тренировок используем текущую дату и training_uuid
    if (widget.isFreeWorkout) {
      body['training_uuid'] = trainingUuid;
      body['training_date'] = DateTime.now().toIso8601String().split('T')[0];
      // Добавляем weight только если он не 0
      if (row.weight != 0) {
        body['weight'] = row.weight;
      }
    } else {
      // Для программ и обычных тренировок
      body['training_uuid'] = trainingUuid;
      body['training_date'] = trainingDate;
      body['weight'] = row.weight;

      // Для программ добавляем program_uuid, для тренировок - нет
      if (widget.isProgram && programUuid != null) {
        body['program_uuid'] = programUuid;
      }
    }

    await ApiService.post('/user_exercises/add/', body: body);

    if (widget.isFreeWorkout) {
      // Для свободных тренировок перезагружаем все подходы
      await _loadAllUserExercises();
    } else {
      await _loadUserExercise(setIdx);
    }

    if (value == true && widget.exercise.restTime > 0) {
      final timerProvider = Provider.of<TimerOverlayProvider>(
        context,
        listen: false,
      );
      final userUuid = widget.userUuid ?? '';
      timerProvider.show(
        widget.exercise.restTime,
        userUuid: userUuid.isNotEmpty ? userUuid : null,
        exerciseUuid: widget.exercise.uuid,
        exerciseName: widget.exercise.caption,
      );
    }
  }

  Future<void> _addSet() async {
    if (!mounted) return;

    setState(() {
      _rows.add(UserExerciseRow());
    });
    widget.onRowsChanged?.call(_rows);

    final newSetIndex = _rows.length - 1;

    // Для свободных тренировок загружаем предыдущий результат
    if (widget.isFreeWorkout && widget.onLoadLastResult != null) {
      await widget.onLoadLastResult!(newSetIndex);
    } else if (!widget.isFreeWorkout && widget.onLoadLastResult != null) {
      await widget.onLoadLastResult!(newSetIndex);
    }
  }

  /// Загружает все user_exercises для свободных тренировок
  Future<void> _loadAllUserExercises() async {
    if (!widget.isFreeWorkout) return;

    final exerciseUuid = widget.exercise.uuid;

    try {
      final resp = await ApiService.get(
        '/user_exercises/',
        queryParams: {'exercise_uuid': exerciseUuid},
      );

      if (resp.statusCode == 200 && mounted) {
        final data = ApiService.decodeJson(resp.body);
        if (data is List) {
          // Сортируем по set_number
          final sorted = List<Map<String, dynamic>>.from(data);
          sorted.sort((a, b) {
            final setA = a['set_number'] ?? 0;
            final setB = b['set_number'] ?? 0;
            return setA.compareTo(setB);
          });

          // Обновляем строки, которые есть в данных
          setState(() {
            for (int i = 0; i < sorted.length && i < _rows.length; i++) {
              final row = sorted[i];
              _rows[i] = UserExerciseRow(
                userExerciseUuid: row['uuid'],
                reps: row['reps'] ?? 0,
                weight: (row['weight'] ?? 0).toDouble(),
                status: row['status'] ?? 'active',
                lastResult: _rows[i].lastResult,
              );
            }
          });
          widget.onRowsChanged?.call(_rows);
        }
      }
    } catch (_) {
      // Игнорируем ошибки
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Три серых квадрата (только для не свободных тренировок)
        if (!widget.isFreeWorkout) ...[
          Row(
            children: [
              Expanded(
                child: MetalButton(
                  label:
                      '${_rows.length} подход${_ending(_rows.length, "а", "ов", "")}',
                  onPressed: null,
                  height: 60,
                  fontSize: 16,
                  position: MetalButtonPosition.first,
                  forceOpaqueText: true,
                ),
              ),
              Expanded(
                child: MetalButton(
                  label:
                      '${widget.exercise.repsCount} повторени${_ending(widget.exercise.repsCount, "е", "й", "я")}',
                  onPressed: null,
                  height: 60,
                  fontSize: 16,
                  position: MetalButtonPosition.middle,
                  forceOpaqueText: true,
                ),
              ),
              Expanded(
                child: MetalButton(
                  label: '${widget.exercise.restTime} сек отдых',
                  onPressed: null,
                  height: 60,
                  fontSize: 16,
                  position: MetalButtonPosition.last,
                  forceOpaqueText: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        // Таблица
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: MetalTable(
            headers: [
              'Предыдущий результат',
              widget.exercise.withWeight ? 'Повторения и вес' : 'Повторения',
              'Выполнено',
            ],
            widgetRows: List.generate(
              _rows.length,
              (setIdx) => [
                // Предыдущий результат
                Text(
                  _rows[setIdx].lastResult,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 14,
                  ),
                ),
                // Повторения и вес
                GestureDetector(
                  onTap: _rows[setIdx].status == 'passed'
                      ? null
                      : () => _showRepsWeightPicker(
                          setIdx,
                          100,
                          widget.exercise.withWeight,
                        ),
                  child: Center(
                    child: widget.exercise.withWeight
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_rows[setIdx].reps}',
                                style: const TextStyle(
                                  color: Color(0xFFEDEDED),
                                  fontSize: 14,
                                ),
                              ),
                              const Text(
                                ' x ',
                                style: TextStyle(
                                  color: Color(0xFFEDEDED),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${_rows[setIdx].weight.toStringAsFixed(2)} кг',
                                style: const TextStyle(
                                  color: Color(0xFFEDEDED),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            '${_rows[setIdx].reps}',
                            style: const TextStyle(
                              color: Color(0xFFEDEDED),
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                // Выполнено
                Center(
                  child: _RoundCheckbox(
                    value: _rows[setIdx].userExerciseUuid != null,
                    status: _rows[setIdx].status,
                    onChanged: (val) {
                      _onSetCompleted(setIdx, value: val);
                    },
                  ),
                ),
              ],
            ),
            cellHeight: 60,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        // Кнопка "Добавить подход"
        MetalButton(
          label: 'Добавить подход',
          icon: Icons.add,
          onPressed: _addSet,
          height: 56,
          fontSize: 16,
        ),
      ],
    );
  }
}

class _RoundCheckbox extends StatelessWidget {
  final bool value;
  final String status;
  final ValueChanged<bool?>? onChanged;

  const _RoundCheckbox({
    required this.value,
    required this.status,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isPassed = status == 'passed';
    final showCheckmark = value;
    final isGreen = isPassed && value;

    return IgnorePointer(
      ignoring: isPassed,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFC5D09D).withOpacity(0.8),
              width: 2.0,
            ),
            color: const Color(0xFF2B2B2B),
          ),
          child: showCheckmark
              ? Center(
                  child: Container(
                    decoration: isGreen
                        ? BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 3,
                                spreadRadius: 0.5,
                              ),
                            ],
                          )
                        : null,
                    child: Icon(
                      Icons.check,
                      size: 18,
                      color: isGreen
                          ? Colors.green
                          : const Color(0xFFC5D09D).withOpacity(0.6),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
