import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ExerciseFilterModal extends StatefulWidget {
  final List<String> muscleGroups;
  final List<String> equipmentNames;
  final List<String> initialSelectedMuscleGroups;
  final List<String> initialSelectedEquipmentNames;
  final Function(
    List<String> selectedMuscleGroups,
    List<String> selectedEquipmentNames,
  )
  onApplyFilters;

  const ExerciseFilterModal({
    Key? key,
    required this.muscleGroups,
    required this.equipmentNames,
    this.initialSelectedMuscleGroups = const [],
    this.initialSelectedEquipmentNames = const [],
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  State<ExerciseFilterModal> createState() => _ExerciseFilterModalState();
}

class _ExerciseFilterModalState extends State<ExerciseFilterModal> {
  late Set<String> _selectedMuscleGroups;
  late Set<String> _selectedEquipmentNames;

  @override
  void initState() {
    super.initState();
    _selectedMuscleGroups = widget.initialSelectedMuscleGroups.toSet();
    _selectedEquipmentNames = widget.initialSelectedEquipmentNames.toSet();
    print(
      'DEBUG: Modal - Initialized with muscle groups: $_selectedMuscleGroups',
    );
    print(
      'DEBUG: Modal - Initialized with equipment names: $_selectedEquipmentNames',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Фильтры',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Группы мышц
            const Text(
              'Группы мышц:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.muscleGroups.map((muscleGroup) {
                    final isSelected = _selectedMuscleGroups.contains(
                      muscleGroup,
                    );
                    return FilterChip(
                      label: Text(muscleGroup),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedMuscleGroups.add(muscleGroup);
                          } else {
                            _selectedMuscleGroups.remove(muscleGroup);
                          }
                        });
                      },
                      selectedColor: AppColors.buttonPrimary.withOpacity(0.3),
                      checkmarkColor: AppColors.buttonPrimary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.buttonPrimary
                            : AppColors.inputBorder,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Оборудование
            const Text(
              'Оборудование:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.equipmentNames.map((equipmentName) {
                    final isSelected = _selectedEquipmentNames.contains(
                      equipmentName,
                    );
                    return FilterChip(
                      label: Text(equipmentName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedEquipmentNames.add(equipmentName);
                          } else {
                            _selectedEquipmentNames.remove(equipmentName);
                          }
                        });
                      },
                      selectedColor: AppColors.buttonPrimary.withOpacity(0.3),
                      checkmarkColor: AppColors.buttonPrimary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.buttonPrimary
                            : AppColors.inputBorder,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedMuscleGroups.clear();
                        _selectedEquipmentNames.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.buttonPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Очистить',
                      style: TextStyle(color: AppColors.buttonPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      print('DEBUG: Apply filters pressed');
                      print(
                        'DEBUG: Selected muscle groups: ${_selectedMuscleGroups.toList()}',
                      );
                      print(
                        'DEBUG: Selected equipment names: ${_selectedEquipmentNames.toList()}',
                      );
                      widget.onApplyFilters(
                        _selectedMuscleGroups.toList(),
                        _selectedEquipmentNames.toList(),
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Выбрать',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
