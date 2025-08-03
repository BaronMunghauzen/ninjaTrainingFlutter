import 'package:flutter/material.dart';
import '../../models/program_model.dart';

class ProgramShortInfo extends StatelessWidget {
  final Program program;
  const ProgramShortInfo({Key? key, required this.program}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (program.imageUuid != null)
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!, width: 1),
              // Здесь можно добавить загрузку изображения по imageUuid
            ),
            child: const Icon(Icons.image, color: Colors.grey, size: 32),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                program.caption,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                program.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Сложность: ${program.difficultyLevel}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
