# 📱 Настройка Universal Links (iOS) и App Links (Android)

Подробная пошаговая инструкция для настройки HTTPS схемы `https://ninjatraining.ru/payment/callback`

---

## 🔧 ЧАСТЬ 1: Подготовка (получаем нужные данные)

### Шаг 1.1: Получаем SHA256 отпечаток для Android

#### Для DEBUG версии (для тестирования):

**Windows:**
```powershell
cd %USERPROFILE%\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**macOS/Linux:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Что искать в выводе:**
```
Certificate fingerprints:
         SHA1: AA:BB:CC:DD:...
         SHA256: 12:34:56:78:90:AB:CD:EF:... <- ВОТ ЭТО НУЖНО СКОПИРОВАТЬ
```

**Скопируйте SHA256** (с двоеточиями) и **СОХРАНИТЕ** в блокнот.

---

#### Для RELEASE версии (для продакшена):

Если у вас уже есть release keystore:
```bash
keytool -list -v -keystore /home/admin/upload-keystore.jks -alias upload
```

Если еще нет release keystore, создайте:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

После выполнения команды `keytool -list -v ...` вы увидите **ТАКОЙ ВЫВОД**:
```
Owner: CN=...
Issuer: CN=...
Serial number: ...
Valid from: ... until: ...
Certificate fingerprints:
         SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD
         SHA256: 12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF
         Signature algorithm name: SHA256withRSA
```

**СКОПИРУЙТЕ** строку **SHA256** (все символы после "SHA256:"):
```
12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF
```

**СОХРАНИТЕ** это в блокнот - понадобится позже!

---

### Шаг 1.2: Получаем Package Name для Android

Откройте файл: `android/app/build.gradle.kts`

Найдите строку:
```kotlin
namespace = "ru.ninjatraining.app"  // <- ВОТ ЭТО ВАШ PACKAGE NAME
```

Или в старых проектах:
```kotlin
applicationId = "ru.ninjatraining.app"
```

**Ваш package name:** `ru.ninjatraining.app`

**Скопируйте и СОХРАНИТЕ** package name.

---

### Шаг 1.3: Получаем Team ID для iOS (если планируете iOS)

**Способ 1 - Через Xcode:**
1. Откройте `ios/Runner.xcworkspace` в Xcode
2. Выберите проект "Runner" слева
3. Вкладка "Signing & Capabilities"
4. Посмотрите на "Team" - там будет ID в скобках, например: `ABC123XYZ`

**Способ 2 - Через Apple Developer:**
1. Зайдите на https://developer.apple.com/account
2. Membership → Team ID

**Скопируйте Team ID** и **СОХРАНИТЕ**.

---

### Шаг 1.4: Получаем Bundle ID для iOS

В том же Xcode:
- "General" → "Bundle Identifier", например: `ru.ninjatraining.app`

Или откройте `ios/Runner/Info.plist` и найдите `CFBundleIdentifier`.

**Скопируйте Bundle ID** и **СОХРАНИТЕ**.

---

## 📝 ЧАСТЬ 2: Создание файлов

### Шаг 2.1: Создаем файл для Android

**Создайте файл локально:**


**macOS/Linux:**
```bash
# Создайте папку
mkdir -p ~/temp/well-known

# Создайте файл
nano ~/temp/well-known/assetlinks.json
```

**Вставьте в файл (ЗАМЕНИТЕ ДАННЫЕ):**
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "ru.ninjatraining.app",
    "sha256_cert_fingerprints": [
      "DFB3F7BEABCD77212FAF085A748E1663E6B94E4A63281935E1FA5E4FE5EDC9E6"
    ]
  }
}]
```

**Пример заполнения для NinjaTraining:**
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "ru.ninjatraining.app",
    "sha256_cert_fingerprints": [
      "ВАШ_SHA256_КОТОРЫЙ_ПОЛУЧИТЕ_ИЗ_KEYTOOL"
    ]
  }
}]
```

**❗ ВАЖНО:** 
- SHA256 должен быть **БЕЗ двоеточий** (замените `12:34:56` на `123456`)
- Или используйте команду для автоматического удаления:

**Windows PowerShell:**
```powershell
$sha256 = "12:34:56:78:90:AB:CD:EF:..."
$sha256 -replace ":", ""
```

**macOS/Linux:**
```bash
echo "12:34:56:78:90:AB:CD:EF:..." | tr -d ':'
```

---

### Шаг 2.2: Создаем файл для iOS

**Создайте файл:**

**Windows:**
```powershell
notepad C:\temp\well-known\apple-app-site-association
```

**macOS/Linux:**
```bash
nano ~/temp/well-known/apple-app-site-association
```

**⚠️ БЕЗ РАСШИРЕНИЯ .json!**

**Вставьте в файл (ЗАМЕНИТЕ ДАННЫЕ):**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "ВАШ_TEAM_ID.ВАШ_BUNDLE_ID",
        "paths": ["/payment/*"]
      }
    ]
  }
}
```

**Пример заполнения:**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "ABC123XYZ.ru.ninjatraining.app",
        "paths": ["/payment/*"]
      }
    ]
  }
}
```

---

## 🚀 ЧАСТЬ 3: Загрузка на сервер

### Шаг 3.1: Проверьте структуру на сервере

На сервере должна быть такая структура:
```
/var/www/ninjatraining.ru/
├── .well-known/
│   ├── assetlinks.json
│   └── apple-app-site-association
```

### Шаг 3.2: Создание файлов на сервере через nano

**Подключитесь к серверу:**
```bash
ssh admin@ninjatraining.ru
```

**Создайте папку .well-known:**
```bash
sudo mkdir -p /var/www/ninjatraining.ru/.well-known
cd /var/www/ninjatraining.ru/.well-known
```

---

**📝 Файл 1 - assetlinks.json**

**Шаг 1:** Откройте nano:
```bash
sudo nano assetlinks.json
```

**Шаг 2:** Вставьте этот текст (замените SHA256 на ваш):
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "ru.ninjatraining.app",
    "sha256_cert_fingerprints": [
      "DFB3F7BEABCD77212FAF085A748E1663E6B94E4A63281935E1FA5E4FE5EDC9E6"
    ]
  }
}]
```

**Шаг 3:** Сохраните и выйдите:
- Нажмите `Ctrl + O` (буква О, не ноль) - для сохранения
- Нажмите `Enter` - подтвердить имя файла
- Нажмите `Ctrl + X` - выход из nano

---

**📱 Файл 2 - apple-app-site-association**

**Шаг 1:** Откройте nano:
```bash
sudo nano apple-app-site-association
```

**⚠️ БЕЗ расширения .json!** Имя файла: `apple-app-site-association`

**Шаг 2:** Вставьте этот текст (замените Team ID и Bundle ID на ваши):
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "ВАШ_TEAM_ID.ВАШ_BUNDLE_ID",
        "paths": ["/payment/*"]
      }
    ]
  }
}
```

**Шаг 3:** Сохраните и выйдите:
- Нажмите `Ctrl + O` - для сохранения
- Нажмите `Enter` - подтвердить имя файла
- Нажмите `Ctrl + X` - выход из nano

---

**🔒 Установите права доступа:**
```bash
sudo chmod 644 assetlinks.json
sudo chmod 644 apple-app-site-association
sudo chown www-data:www-data assetlinks.json
sudo chown www-data:www-data apple-app-site-association
```

**✅ Проверьте, что файлы созданы:**
```bash
ls -la
```

Должны увидеть оба файла с правами `-rw-r--r--`

---

### Шаг 3.3: Загрузка через FTP/SFTP

Если используете FileZilla или WinSCP:

1. Подключитесь к серверу
2. Перейдите в `/var/www/ninjatraining.ru/`
3. Создайте папку `.well-known`
4. Загрузите туда оба файла
5. Установите права 644 на оба файла

---

### Шаг 3.4: Настройка Nginx (если используете)

**Откройте конфиг сайта:**
```bash
sudo nano /etc/nginx/sites-available/ninjatraining.ru
```

**Добавьте в блок `server`:**
```nginx
server {
    ...
    
    # Разрешаем доступ к .well-known
    location ~ /.well-known {
        allow all;
    }
    
    # Устанавливаем правильный Content-Type для файлов
    location = /.well-known/assetlinks.json {
        default_type application/json;
        add_header Access-Control-Allow-Origin *;
    }
    
    location = /.well-known/apple-app-site-association {
        default_type application/json;
        add_header Access-Control-Allow-Origin *;
    }
    
    ...
}
```

**Проверьте конфиг:**
```bash
sudo nginx -t
```

**Перезагрузите Nginx:**
```bash
sudo systemctl reload nginx
```

---

### Шаг 3.5: Настройка Apache (если используете)

**Откройте конфиг сайта:**
```bash
sudo nano /etc/apache2/sites-available/ninjatraining.ru.conf
```

**Добавьте:**
```apache
<VirtualHost *:443>
    ...
    
    <Directory /var/www/ninjatraining.ru/.well-known>
        Options -Indexes
        AllowOverride None
        Require all granted
    </Directory>
    
    <Files "apple-app-site-association">
        Header set Content-Type "application/json"
        Header set Access-Control-Allow-Origin "*"
    </Files>
    
    ...
</VirtualHost>
```

**Перезагрузите Apache:**
```bash
sudo systemctl reload apache2
```

---

## ✅ ЧАСТЬ 4: Проверка

### Шаг 4.1: Проверка доступности файлов

**В браузере откройте:**
- https://ninjatraining.ru/.well-known/assetlinks.json
- https://ninjatraining.ru/.well-known/apple-app-site-association

Должен отобразиться JSON без ошибок.

**Или через curl:**
```bash
curl https://ninjatraining.ru/.well-known/assetlinks.json
curl https://ninjatraining.ru/.well-known/apple-app-site-association
```

---

### Шаг 4.2: Валидация Android App Links

**Онлайн валидатор:**
https://developers.google.com/digital-asset-links/tools/generator

Введите:
- Site domain: `ninjatraining.ru`
- Package name: ваш package name
- SHA-256: ваш SHA-256 (с двоеточиями)

---

### Шаг 4.3: Валидация iOS Universal Links

**Онлайн валидатор:**
https://branch.io/resources/aasa-validator/

Введите: `ninjatraining.ru`

---

### Шаг 4.4: Тестирование на устройстве

**Android:**
```bash
# Установите приложение
flutter build apk --release
flutter install

# Проверьте через adb
adb shell am start -a android.intent.action.VIEW -d "https://ninjatraining.ru/payment/callback"
```

**iOS:**
1. Удалите приложение
2. Установите заново (iOS кеширует App Links при первой установке)
3. Откройте Safari
4. Введите: `ninjatraining.ru/payment/callback`
5. Должно предложить открыть в приложении

---

## 🎯 Быстрый чеклист

- [ ] Получил SHA256 для Android
- [ ] Получил Package Name
- [ ] Получил Team ID для iOS (если нужен iOS)
- [ ] Получил Bundle ID для iOS
- [ ] Создал assetlinks.json с правильными данными
- [ ] Создал apple-app-site-association с правильными данными
- [ ] Загрузил файлы на сервер в папку `.well-known`
- [ ] Настроил Nginx/Apache
- [ ] Проверил доступность по HTTPS
- [ ] Проверил через онлайн валидаторы
- [ ] Протестировал на реальном устройстве

---

## ❓ Частые проблемы

**Проблема:** "Файл не найден 404"
- Проверьте права на папку `.well-known` (должно быть 755)
- Проверьте права на файлы (должно быть 644)
- Проверьте конфигурацию веб-сервера

**Проблема:** "Content-Type неправильный"
- Добавьте настройки в Nginx/Apache как показано выше

**Проблема:** "iOS не открывает приложение"
- Удалите и переустановите приложение
- iOS кеширует Universal Links при установке

**Проблема:** "Android не открывает приложение"
- Проверьте SHA256 (должен быть БЕЗ двоеточий в файле)
- Убедитесь что package name совпадает

---

## 📞 Нужна помощь?

Если что-то не получается:
1. Проверьте все данные еще раз
2. Убедитесь что файлы доступны по HTTPS
3. Попробуйте онлайн валидаторы
4. Проверьте логи сервера на наличие ошибок

Удачи! 🚀
