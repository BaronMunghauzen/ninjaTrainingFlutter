import os
import re

# Маппинг для вложенных экранов
IMPORT_MAP = [
    # main_screen.dart
    (r"import 'training_screen\.dart'", "import 'user/training_screen.dart'"),
    (r"import 'achievements_screen\.dart'", "import 'achievements/achievements_screen.dart'"),
    (r"import 'profile_screen\.dart'", "import 'profile/profile_screen.dart'"),

    # user экраны
    (r"import '../services/", "import '../../services/"),
    (r"import '../widgets/", "import '../../widgets/"),
    (r"import '../constants/", "import '../../constants/"),
    (r"import '../models/", "import '../../models/"),
    (r"import '../providers/", "import '../../providers/"),
    (r"import 'program_detail_screen\.dart'", "import '../program_detail_screen.dart"),
    (r"import 'program_constructor_screen\.dart'", "import '../../admin/program_constructor_screen.dart"),

    # admin экраны
    (r"import '../services/", "import '../../services/"),
    (r"import '../widgets/", "import '../../widgets/"),
    (r"import '../constants/", "import '../../constants/"),
    (r"import '../models/", "import '../../models/"),
    (r"import '../providers/", "import '../../providers/"),

    # profile экраны
    (r"import '../services/", "import '../../services/"),
    (r"import '../widgets/", "import '../../widgets/"),
    (r"import '../constants/", "import '../../constants/"),
    (r"import '../models/", "import '../../models/"),
    (r"import '../providers/", "import '../../providers/"),

    # achievements экраны
    (r"import '../services/", "import '../../services/"),
    (r"import '../widgets/", "import '../../widgets/"),
    (r"import '../constants/", "import '../../constants/"),
    (r"import '../models/", "import '../../models/"),
    (r"import '../providers/", "import '../../providers/"),
]


def fix_imports_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content
    for old, new in IMPORT_MAP:
        content = re.sub(old, new, content)
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"[UPDATED] {filepath}")


def walk_and_fix(root):
    for dirpath, _, filenames in os.walk(root):
        for filename in filenames:
            if filename.endswith('.dart'):
                fix_imports_in_file(os.path.join(dirpath, filename))

if __name__ == '__main__':
    walk_and_fix('lib/screens/')
    walk_and_fix('lib/widgets/')
    walk_and_fix('lib/providers/')
    walk_and_fix('lib/services/')
    walk_and_fix('lib/constants/')
    walk_and_fix('lib/models/')
    print('Импорты обновлены!') 