# Системные требования приложения NinjaTrainingFlutter

## 1. Общее описание системы

**Название:** NinjaTrainingFlutter  
**Тип:** Мобильное приложение для фитнес-тренировок  
**Платформа:** Flutter (Android, iOS, Web)  
**Архитектура:** MVVM с использованием Provider для управления состоянием  
**Backend API:** REST API на базе Django (http://10.0.2.2:8000)

## 2. Архитектура приложения

### 2.1 Структура проекта
```
lib/
├── constants/          # Константы приложения
├── models/            # Модели данных
├── providers/         # Провайдеры состояния
├── screens/           # Экраны приложения
├── services/          # Сервисы для работы с API
├── utils/             # Утилиты
└── widgets/           # Переиспользуемые виджеты
```

### 2.2 Основные компоненты
- **ApiService** - единый сервис для HTTP запросов
- **AuthProvider** - управление аутентификацией
- **TimerOverlayProvider** - управление таймером тренировок
- **GlobalTickerProvider** - глобальный тикер для анимаций

## 3. Модули и экраны

### 3.1 Главный экран (MainScreen)
**Файл:** `lib/screens/main_screen.dart`

**Описание:** Главная навигация приложения с тремя основными разделами

**Функциональность:**
- Нижняя навигация с тремя вкладками
- Автоматическая загрузка профиля пользователя
- Переключение между основными модулями

**API методы:**
- `AuthProvider.fetchUserProfile()` - загрузка профиля пользователя

### 3.2 Модуль "Тренировки" (TrainingScreen)
**Файл:** `lib/screens/system_program/training_screen.dart`

**Описание:** Главный экран для работы с тренировочными программами

**Функциональность:**
- Отображение списка доступных программ тренировок
- Загрузка изображений программ
- Навигация к активным/неактивным тренировкам
- Доступ к конструктору программ (для админов)
- Доступ к пользовательским тренировкам

**API методы:**
- `ProgramService.getActualPrograms()` - получение актуальных программ
- `ApiService.get('/files/file/$imageUuid')` - загрузка изображений

**Подэкраны:**
- `ActiveTrainingScreen` - активные тренировки
- `InactiveTrainingScreen` - неактивные тренировки
- `SystemTrainingListWidget` - список системных тренировок
- `MyTrainingListWidget` - список пользовательских тренировок

### 3.3 Активная тренировка (ActiveTrainingScreen)
**Файл:** `lib/screens/system_program/active_training_screen.dart`

**Описание:** Экран для выполнения активной тренировки

**Функциональность:**
- Отображение текущей тренировки
- Навигация по неделям и дням
- Загрузка групп упражнений
- Таймер для упражнений
- Отметка выполненных упражнений
- Завершение программы тренировок
- Поздравительный экран при завершении

**API методы:**
- `TrainingService.getExerciseGroups()` - получение групп упражнений
- `TrainingService.finishUserProgram()` - завершение программы
- `TrainingService.getUserTrainings()` - получение тренировок пользователя

**Подэкраны:**
- `WeeksDaysNavigation` - навигация по неделям/дням
- `ExerciseGroupCarouselScreen` - карусель групп упражнений

### 3.4 Группа упражнений (ExerciseGroupCarouselScreen)
**Файл:** `lib/screens/system_program/exercise_group_carousel_screen.dart`

**Описание:** Экран для выполнения группы упражнений

**Функциональность:**
- Карусель упражнений в группе
- Таймер для каждого упражнения
- Отметка выполненных упражнений
- Переход между упражнениями
- Звуковые уведомления

**API методы:**
- `TrainingService.getExerciseGroups()` - получение групп упражнений
- `TrainingService.markExerciseAsCompleted()` - отметка упражнения как выполненного

### 3.5 Детали тренировки (TrainingDetailScreen)
**Файл:** `lib/screens/system_program/training_detail_screen.dart`

**Описание:** Детальная информация о тренировке

**Функциональность:**
- Отображение информации о тренировке
- Список групп упражнений
- Переход к выполнению тренировки

**API методы:**
- `TrainingService.getExerciseGroups()` - получение групп упражнений

### 3.6 Детали группы упражнений (ExerciseGroupDetailScreen)
**Файл:** `lib/screens/system_program/exercise_group_detail_screen.dart`

**Описание:** Детальная информация о группе упражнений

**Функциональность:**
- Отображение информации о группе упражнений
- Список упражнений в группе
- Переход к выполнению группы

### 3.7 Модуль "Достижения" (AchievementsScreen)
**Файл:** `lib/screens/achievements/achievements_screen.dart`

**Описание:** Экран достижений пользователя

**Функциональность:**
- Отображение достижений пользователя
- Прогресс по достижениям
- Статистика тренировок

### 3.8 Модуль "Профиль" (ProfileScreen)
**Файл:** `lib/screens/profile/profile_screen.dart`

**Описание:** Профиль пользователя

**Функциональность:**
- Отображение информации о пользователе
- Загрузка аватара
- Редактирование профиля
- Выход из аккаунта
- Контактная информация

**API методы:**
- `AuthProvider.fetchUserProfile()` - загрузка профиля
- `ApiService.get('/files/file/$avatarUuid')` - загрузка аватара
- `AuthProvider.signOut()` - выход из аккаунта

**Подэкраны:**
- `EditProfileScreen` - редактирование профиля
- `ContactScreen` - контактная информация

### 3.9 Аутентификация (AuthScreen)
**Файл:** `lib/screens/profile/auth_screen.dart`

**Описание:** Экран входа и регистрации

**Функциональность:**
- Переключение между входом и регистрацией
- Валидация форм
- Анимации интерфейса
- Обработка ошибок

**API методы:**
- `AuthProvider.signIn()` - вход в систему
- `AuthProvider.signUp()` - регистрация

### 3.10 Редактирование профиля (EditProfileScreen)
**Файл:** `lib/screens/profile/edit_profile_screen.dart`

**Описание:** Экран редактирования профиля пользователя

**Функциональность:**
- Редактирование личной информации
- Загрузка аватара
- Сохранение изменений

**API методы:**
- `ApiService.multipart()` - загрузка аватара
- `ApiService.put('/auth/update/$uuid')` - обновление профиля

### 3.11 Пользовательские тренировки

#### 3.11.1 Список пользовательских тренировок (UserTrainingListScreen)
**Файл:** `lib/screens/user_training_constructor/user_training_list_screen.dart`

**Описание:** Список пользовательских тренировок

**Функциональность:**
- Отображение пользовательских тренировок
- Создание новых тренировок
- Удаление тренировок

**API методы:**
- `UserTrainingService.getUserTrainings()` - получение пользовательских тренировок
- `UserTrainingService.deleteTraining()` - удаление тренировки

#### 3.11.2 Создание пользовательской тренировки (UserTrainingCreateScreen)
**Файл:** `lib/screens/user_training_constructor/user_training_create_screen.dart`

**Описание:** Создание новой пользовательской тренировки

**Функциональность:**
- Форма создания тренировки
- Валидация данных
- Сохранение тренировки

**API методы:**
- `UserTrainingService.createUserTraining()` - создание тренировки

#### 3.11.3 Детали пользовательской тренировки (UserTrainingDetailScreen)
**Файл:** `lib/screens/user_training_constructor/user_training_detail_screen.dart`

**Описание:** Детальная информация о пользовательской тренировке

**Функциональность:**
- Отображение информации о тренировке
- Список групп упражнений
- Редактирование тренировки

#### 3.11.4 Конструктор пользовательских тренировок (UserTrainingConstructorScreen)
**Файл:** `lib/screens/user_training_constructor/user_training_constructor_screen.dart`

**Описание:** Конструктор для создания пользовательских тренировок

**Функциональность:**
- Создание групп упражнений
- Добавление упражнений
- Настройка параметров

#### 3.11.5 Создание группы упражнений (UserExerciseGroupCreateScreen)
**Файл:** `lib/screens/user_training_constructor/user_exercise_group_create_screen.dart`

**Описание:** Создание группы упражнений для пользовательской тренировки

**Функциональность:**
- Форма создания группы упражнений
- Выбор упражнений
- Настройка параметров

**API методы:**
- `UserTrainingService.createExerciseGroup()` - создание группы упражнений
- `UserTrainingService.getUserExerciseReferences()` - получение упражнений

#### 3.11.6 Справочник упражнений (UserExerciseReferenceListScreen)
**Файл:** `lib/screens/user_training_constructor/user_exercise_reference_list_screen.dart`

**Описание:** Список упражнений в справочнике

**Функциональность:**
- Отображение упражнений
- Создание новых упражнений
- Удаление упражнений

**API методы:**
- `UserTrainingService.getUserExerciseReferences()` - получение упражнений
- `UserTrainingService.deleteExerciseReference()` - удаление упражнения

#### 3.11.7 Создание упражнения (UserExerciseReferenceCreateScreen)
**Файл:** `lib/screens/user_training_constructor/user_exercise_reference_create_screen.dart`

**Описание:** Создание нового упражнения в справочнике

**Функциональность:**
- Форма создания упражнения
- Валидация данных
- Сохранение упражнения

**API методы:**
- `UserTrainingService.createUserExercise()` - создание упражнения

### 3.12 Административные функции

#### 3.12.1 Конструктор программ (ProgramConstructorScreen)
**Файл:** `lib/screens/admin_program_constructor/program_constructor_screen.dart`

**Описание:** Конструктор программ для администраторов

**Функциональность:**
- Создание программ тренировок
- Управление программами
- Настройка расписания

#### 3.12.2 Создание программы (ProgramCreateScreen)
**Файл:** `lib/screens/admin_program_constructor/program_create_screen.dart`

**Описание:** Создание новой программы тренировок

**Функциональность:**
- Форма создания программы
- Загрузка изображений
- Настройка параметров

#### 3.12.3 Детали программы (ProgramAdminDetailScreen)
**Файл:** `lib/screens/admin_program_constructor/program_admin_detail_screen.dart`

**Описание:** Детальная информация о программе для администраторов

**Функциональность:**
- Отображение информации о программе
- Управление тренировками в программе
- Редактирование программы

#### 3.12.4 Конструктор тренировок (AdminTrainingConstructorScreen)
**Файл:** `lib/screens/admin_training_constructor/admin_training_constructor_screen.dart`

**Описание:** Конструктор тренировок для администраторов

**Функциональность:**
- Создание системных тренировок
- Управление группами упражнений
- Настройка упражнений

## 4. API методы и эндпоинты

### 4.1 Аутентификация
- `POST /auth/login` - вход в систему
- `POST /auth/register/` - регистрация
- `GET /auth/me` - получение профиля пользователя
- `PUT /auth/update/{uuid}` - обновление профиля

### 4.2 Файлы
- `GET /files/file/{fileUuid}` - получение файла
- `POST /files/upload/avatar/{userUuid}` - загрузка аватара
- `DELETE /files/file/{fileUuid}` - удаление файла

### 4.3 Программы тренировок
- `GET /programs/` - получение программ
- `GET /programs/{uuid}` - получение программы по ID
- `POST /programs/add/` - создание программы
- `PUT /programs/{uuid}` - обновление программы
- `DELETE /programs/{uuid}` - удаление программы

### 4.4 Пользовательские программы
- `GET /user_programs/` - получение пользовательских программ
- `POST /user_programs/add/` - создание пользовательской программы
- `POST /user_programs/finish/{uuid}` - завершение программы

### 4.5 Тренировки
- `GET /trainings/` - получение тренировок
- `POST /trainings/add/` - создание тренировки
- `PUT /trainings/{uuid}` - обновление тренировки
- `DELETE /trainings/delete/{uuid}` - удаление тренировки

### 4.6 Пользовательские тренировки
- `GET /user_trainings/` - получение пользовательских тренировок
- `POST /user_trainings/add/` - создание пользовательской тренировки

### 4.7 Группы упражнений
- `GET /exercise-groups/` - получение групп упражнений
- `POST /exercise-groups/add/` - создание группы упражнений
- `PUT /exercise-groups/{uuid}` - обновление группы упражнений
- `DELETE /exercise-groups/delete/{uuid}` - удаление группы упражнений

### 4.8 Упражнения
- `POST /exercises/add/` - создание упражнения
- `PUT /exercises/{uuid}` - обновление упражнения
- `DELETE /exercises/delete/{uuid}` - удаление упражнения

### 4.9 Справочник упражнений
- `GET /exercise_reference/` - получение упражнений из справочника
- `POST /exercise_reference/add/` - создание упражнения в справочнике
- `DELETE /exercise_reference/delete/{uuid}` - удаление упражнения из справочника

### 4.10 Утилиты
- `GET /user_exercises/utils/getLastUserExercises` - получение последних упражнений пользователя

## 5. Модели данных

### 5.1 UserModel
```dart
class UserModel {
  final String subscriptionStatus;
  final String uuid;
  final String email;
  final String login;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? phoneNumber;
  final String? gender;
  final String? description;
  final String? avatarUuid;
  final bool isUser;
  final bool isAdmin;
  final DateTime? subscriptionUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

### 5.2 Program
```dart
class Program {
  final String uuid;
  final bool actual;
  final String programType;
  final String caption;
  final String description;
  final int difficultyLevel;
  final int order;
  final String? scheduleType;
  final String? trainingDays;
  final String? imageUuid;
  final Category? category;
}
```

### 5.3 Training
```dart
class Training {
  final String uuid;
  final String trainingType;
  final String caption;
  final String description;
  final int difficultyLevel;
  final String muscleGroup;
  final String userUuid;
  final List<ExerciseGroup> exerciseGroups;
}
```

### 5.4 ExerciseGroup
```dart
class ExerciseGroup {
  final String uuid;
  final String trainingUuid;
  final String caption;
  final String description;
  final String muscleGroup;
  final List<Exercise> exercises;
}
```

### 5.5 Exercise
```dart
class Exercise {
  final String uuid;
  final String exerciseType;
  final String userUuid;
  final String caption;
  final String description;
  final String muscleGroup;
  final int setsCount;
  final int repsCount;
  final int restTime;
  final bool withWeight;
  final double weight;
  final String exerciseReferenceUuid;
}
```

### 5.6 ExerciseReference
```dart
class ExerciseReference {
  final String uuid;
  final String exerciseType;
  final String caption;
  final String description;
  final String muscleGroup;
  final String userUuid;
}
```

## 6. Сервисы

### 6.1 ApiService
Центральный сервис для работы с HTTP запросами:
- Поддержка GET, POST, PUT, DELETE, PATCH запросов
- Поддержка multipart/form-data для загрузки файлов
- Автоматическое добавление токена аутентификации
- Логирование запросов и ответов
- Обработка ошибок

### 6.2 AuthProvider
Провайдер для управления аутентификацией:
- Вход в систему
- Регистрация
- Выход из системы
- Управление профилем пользователя
- Кэширование токена

### 6.3 ProgramService
Сервис для работы с программами тренировок:
- Получение актуальных программ
- Получение программ по ID
- Управление пользовательскими программами

### 6.4 TrainingService
Сервис для работы с тренировками:
- Получение тренировок пользователя
- Получение групп упражнений
- Завершение программ
- Кэширование данных

### 6.5 UserTrainingService
Сервис для работы с пользовательскими тренировками:
- Создание пользовательских тренировок
- Управление упражнениями
- Управление группами упражнений
- Работа со справочником упражнений

### 6.6 TimerOverlayProvider
Провайдер для управления таймером:
- Глобальный таймер для упражнений
- Звуковые уведомления
- Отображение оверлея таймера

## 7. Виджеты

### 7.1 CustomButton
Кастомная кнопка с поддержкой различных стилей

### 7.2 CustomTextField
Кастомное поле ввода с валидацией

### 7.3 CustomSwitch
Кастомный переключатель

### 7.4 LogoWidget
Виджет для отображения логотипа

### 7.5 AvatarModal
Модальное окно для работы с аватаром

### 7.6 GlobalTimerOverlay
Глобальный оверлей таймера

### 7.7 ProgramShortInfo
Краткая информация о программе

## 8. Константы

### 8.1 AppColors
Цветовая схема приложения:
- `background` - основной фон
- `surface` - поверхность элементов
- `textPrimary` - основной текст
- `textSecondary` - вторичный текст
- `error` - цвет ошибок

### 8.2 ApiConstants
Константы для API:
- `baseUrl` - базовый URL API
- Эндпоинты для аутентификации
- Эндпоинты для файлов

## 9. Особенности реализации

### 9.1 Кэширование
- Кэширование токена аутентификации
- Кэширование групп упражнений
- Индексы для быстрого поиска тренировок

### 9.2 Обработка ошибок
- Единообразная обработка ошибок API
- Пользовательские уведомления об ошибках
- Логирование ошибок

### 9.3 Анимации
- Плавные переходы между экранами
- Анимации загрузки
- Анимации интерфейса

### 9.4 Звуковые эффекты
- Звуковые уведомления таймера
- Звуки завершения упражнений

### 9.5 Адаптивность
- Поддержка различных размеров экранов
- Адаптивная верстка
- Поддержка темной темы

## 10. Требования к системе

### 10.1 Минимальные требования
- Android 5.0+ (API 21)
- iOS 11.0+
- Flutter 3.0+
- 2GB RAM
- 100MB свободного места

### 10.2 Рекомендуемые требования
- Android 8.0+ (API 26)
- iOS 13.0+
- 4GB RAM
- 500MB свободного места
- Стабильное интернет-соединение

### 10.3 Зависимости
- `flutter` - основной фреймворк
- `provider` - управление состоянием
- `http` - HTTP клиент
- `shared_preferences` - локальное хранилище
- `http_parser` - парсинг HTTP

## 11. Безопасность

### 11.1 Аутентификация
- Токен-базированная аутентификация
- Автоматическое обновление токенов
- Безопасное хранение токенов

### 11.2 Валидация данных
- Валидация форм на клиенте
- Валидация данных на сервере
- Санитизация пользовательского ввода

### 11.3 Защита данных
- Шифрование чувствительных данных
- Безопасная передача данных
- Защита от XSS и CSRF атак

## 12. Производительность

### 12.1 Оптимизация
- Ленивая загрузка данных
- Кэширование изображений
- Оптимизация списков

### 12.2 Мониторинг
- Логирование производительности
- Отслеживание ошибок
- Метрики использования

## 13. Тестирование

### 13.1 Типы тестов
- Unit тесты для сервисов
- Widget тесты для UI компонентов
- Integration тесты для полных сценариев

### 13.2 Покрытие тестами
- Минимальное покрытие 80%
- Критические пути 100%

## 14. Развертывание

### 14.1 Сборка
- Автоматическая сборка для Android
- Автоматическая сборка для iOS
- CI/CD pipeline

### 14.2 Распространение
- Google Play Store
- Apple App Store
- Внутреннее тестирование

## 15. Документация

### 15.1 Техническая документация
- API документация
- Архитектурная документация
- Руководство разработчика

### 15.2 Пользовательская документация
- Руководство пользователя
- FAQ
- Видео-туториалы

---

*Документ создан на основе анализа кодовой базы проекта NinjaTrainingFlutter*