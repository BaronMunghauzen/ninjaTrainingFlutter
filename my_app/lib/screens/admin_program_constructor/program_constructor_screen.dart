import 'package:flutter/material.dart';
import '../../models/program_model.dart';
import '../../services/program_service.dart';
import 'program_create_screen.dart';
import 'program_admin_detail_screen.dart';
import '../../services/api_service.dart';

class ProgramConstructorScreen extends StatefulWidget {
  const ProgramConstructorScreen({Key? key}) : super(key: key);

  @override
  State<ProgramConstructorScreen> createState() =>
      _ProgramConstructorScreenState();
}

class _ProgramConstructorScreenState extends State<ProgramConstructorScreen> {
  List<Program> programs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    setState(() {
      isLoading = true;
    });
    try {
      final list = await ProgramService.getPrograms();
      setState(() {
        programs = list;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки программ: $e')));
    }
  }

  Future<ImageProvider?> _loadProgramImage(int? imageUuid) async {
    if (imageUuid == null) return null;
    try {
      final response = await ApiService.get('/files/file/$imageUuid');
      if (response.statusCode == 200) {
        return MemoryImage(response.bodyBytes);
      }
      return null;
    } catch (e) {
      print('[API] exception: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Конструктор программ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить программу',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProgramCreateScreen(),
                ),
              );
              if (result == true) {
                _loadPrograms();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : programs.isEmpty
          ? const Center(child: Text('Нет программ'))
          : RefreshIndicator(
              onRefresh: _loadPrograms,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: programs.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final program = programs[index];
                  return ListTile(
                    title: Row(
                      children: [
                        FutureBuilder<ImageProvider?>(
                          future: _loadProgramImage(program.imageUuid),
                          builder: (context, snapshot) {
                            final image = snapshot.data;
                            return Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[700]!,
                                  width: 1,
                                ),
                                image: image != null
                                    ? DecorationImage(
                                        image: image,
                                        fit: BoxFit.cover,
                                        colorFilter: ColorFilter.mode(
                                          Colors.black.withOpacity(0.5),
                                          BlendMode.darken,
                                        ),
                                      )
                                    : null,
                              ),
                              child: image == null
                                  ? const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 24,
                                    )
                                  : null,
                            );
                          },
                        ),
                        Expanded(child: Text(program.caption)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: program.actual
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            program.actual ? 'Активна' : 'Неактивна',
                            style: TextStyle(
                              fontSize: 12,
                              color: program.actual
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(program.description),
                        const SizedBox(height: 4),
                        Text(
                          'Сложность: ${program.difficultyLevel}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) => ProgramAdminDetailScreen(
                                programUuid: program.uuid,
                              ),
                            ),
                          )
                          .then((result) {
                            if (result == true) {
                              _loadPrograms();
                            }
                          });
                    },
                  );
                },
              ),
            ),
    );
  }
}
