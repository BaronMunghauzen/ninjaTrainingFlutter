#!/usr/bin/env python3
"""
Скрипт для исправления неиспользуемых импортов в Flutter проекте
"""

import os
import re
from pathlib import Path

def remove_unused_imports(file_path):
    """Удаляет неиспользуемые импорты из файла"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Список неиспользуемых импортов для удаления
    unused_imports = [
        "import '../../services/program_service.dart';",
        "import 'package:provider/provider.dart';",
        "import 'dart:convert';",
        "import 'dart:math';",
        "import '../constants/api_constants.dart';",
        "import '../models/exercise_model.dart';",
        "import '../models/user_training_model.dart';",
        "import '../../providers/auth_provider.dart';",
        "import '../../services/api_service.dart';",
        "import 'user_training_detail_screen.dart';",
    ]
    
    original_content = content
    for import_line in unused_imports:
        content = content.replace(import_line + '\n', '')
        content = content.replace(import_line, '')
    
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Исправлен файл: {file_path}")

def main():
    """Основная функция"""
    lib_dir = Path("lib")
    
    # Находим все Dart файлы
    dart_files = list(lib_dir.rglob("*.dart"))
    
    print(f"Найдено {len(dart_files)} Dart файлов")
    
    for file_path in dart_files:
        remove_unused_imports(file_path)
    
    print("Исправление импортов завершено!")

if __name__ == "__main__":
    main() 