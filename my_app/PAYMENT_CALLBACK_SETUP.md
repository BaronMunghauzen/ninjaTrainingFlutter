# 🌐 Инструкция по настройке страницы возврата из оплаты

## 📄 Что это?

Страница `https://ninjatraining.ru/payment/callback` - это fallback на случай, если App Links не сработают.

---

## 🚀 Способ 1: Загрузка через SCP (рекомендуется)

### Шаг 1: Загрузите файлы на сервер

**С вашего компьютера выполните:**

**Windows (через PowerShell или WSL):**
```bash
# Загрузите HTML страницу
scp C:\FlutterProjects\NinjaTrainingFlutter\my_app\payment_callback.html admin@ninjatraining.ru:/tmp/

# Загрузите иконку приложения
scp C:\FlutterProjects\NinjaTrainingFlutter\my_app\assets\images\iconsForApp\icon2.png admin@ninjatraining.ru:/tmp/ninja_icon.png
```

**macOS/Linux:**
```bash
# Загрузите HTML страницу
scp ~/путь/к/проекту/my_app/payment_callback.html admin@ninjatraining.ru:/tmp/

# Загрузите иконку приложения
scp ~/путь/к/проекту/my_app/assets/images/iconsForApp/icon2.png admin@ninjatraining.ru:/tmp/ninja_icon.png
```

### Шаг 2: На сервере переместите файлы

**Подключитесь к серверу:**
```bash
ssh admin@ninjatraining.ru
```

**Выполните команды:**
```bash
# Создайте папку payment
sudo mkdir -p /var/www/html/payment

# Переместите HTML файл
sudo mv /tmp/payment_callback.html /var/www/html/payment/callback

# Переместите иконку
sudo mv /tmp/ninja_icon.png /var/www/html/payment/ninja_icon.png

# Установите права на оба файла
sudo chmod 644 /var/www/html/payment/callback
sudo chmod 644 /var/www/html/payment/ninja_icon.png
sudo chown www-data:www-data /var/www/html/payment/callback
sudo chown www-data:www-data /var/www/html/payment/ninja_icon.png

# Проверьте
ls -la /var/www/html/payment/
```

**Должны увидеть:**
```
-rw-r--r-- 1 www-data www-data [размер] callback
-rw-r--r-- 1 www-data www-data [размер] ninja_icon.png
```

---

## 🚀 Способ 2: Создание прямо на сервере

### Подключитесь к серверу:
```bash
ssh admin@ninjatraining.ru
```

### Создайте HTML файл:
```bash
# Создайте папку
sudo mkdir -p /var/www/html/payment

# Создайте файл
sudo nano /var/www/html/payment/callback
```

### Скопируйте ВЕСЬ код из файла `payment_callback.html`

**Полный путь к файлу на вашем компьютере:**
```
C:\FlutterProjects\NinjaTrainingFlutter\my_app\payment_callback.html
```

1. Откройте этот файл в редакторе
2. Скопируйте ВЕСЬ код (Ctrl+A, Ctrl+C)
3. Вставьте в nano (правый клик мыши или Shift+Insert)
4. Сохраните: `Ctrl+O` → `Enter` → `Ctrl+X`

### Загрузите иконку приложения:

**Способ A - через scp с компьютера:**
```bash
# Выполните на своем компьютере (не на сервере!)
scp C:\FlutterProjects\NinjaTrainingFlutter\my_app\assets\images\iconsForApp\icon2.png admin@ninjatraining.ru:/tmp/ninja_icon.png

# Потом на сервере:
sudo mv /tmp/ninja_icon.png /var/www/html/payment/ninja_icon.png
```

**Способ B - скачать с GitHub (если уже запушили):**
```bash
# На сервере выполните:
sudo wget https://raw.githubusercontent.com/BaronMunghauzen/ninjaTrainingFlutter/master/my_app/assets/images/iconsForApp/icon2.png -O /var/www/html/payment/ninja_icon.png
```

### Установите права:
```bash
sudo chmod 644 /var/www/html/payment/callback
sudo chmod 644 /var/www/html/payment/ninja_icon.png
sudo chown www-data:www-data /var/www/html/payment/callback
sudo chown www-data:www-data /var/www/html/payment/ninja_icon.png
```

---

## ⚙️ Способ 3: Настройка Nginx для правильной отдачи файла

### Откройте конфиг Nginx:
```bash
sudo nano /etc/nginx/sites-available/ninjatraining.ru
```

### Добавьте в блок `server` (внутри server { ... }):
```nginx
# Страница возврата из оплаты
location /payment/ {
    alias /var/www/html/payment/;
    index callback;
    try_files $uri $uri/ =404;
    
    # Для HTML страницы
    location = /payment/callback {
        default_type text/html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # Для иконки
    location = /payment/ninja_icon.png {
        default_type image/png;
        add_header Cache-Control "public, max-age=31536000";
    }
}
```

### Проверьте конфиг:
```bash
sudo nginx -t
```

**Должно показать:**
```
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### Перезагрузите Nginx:
```bash
sudo systemctl reload nginx
```

---

## ✅ Проверка

### Шаг 1: Проверьте через curl
```bash
curl https://ninjatraining.ru/payment/callback
```

**Должен вернуться HTML код** (не 404!)

### Шаг 2: Проверьте в браузере

Откройте на **КОМПЬЮТЕРЕ** (не на телефоне):
```
https://ninjatraining.ru/payment/callback
```

**Должна открыться красивая страница** с логотипом ниндзя и текстом "Возврат в NinjaTraining"

### Шаг 3: Проверьте на телефоне

Откройте на **ТЕЛЕФОНЕ С УСТАНОВЛЕННЫМ ПРИЛОЖЕНИЕМ**:
```
https://ninjatraining.ru/payment/callback
```

**Должно произойти:**
1. Страница откроется на секунду
2. Появится диалог "Открыть в NinjaTraining?"
3. Нажмите "Да"
4. Приложение откроется с экраном проверки платежа

---

## 🎨 Что делает страница:

1. **Красивый дизайн** - градиент, логотип ниндзя, анимации
2. **Автоматический редирект** - 3 попытки открыть приложение
3. **Кнопка fallback** - если автоматически не открылось
4. **Несколько методов**:
   - Custom scheme (`ninjatraining://`)
   - Android Intent scheme (для Android устройств)
5. **Информация** - подсказки если приложение не установлено

---

## 🔧 Альтернативный путь к файлу

Если у вас root директория НЕ `/var/www/html`, а другая (узнайте из конфига Nginx):

```bash
# Найдите root директорию
sudo nginx -T | grep "root"

# Используйте найденную директорию
sudo mkdir -p /ваш_root/payment
sudo mv /tmp/payment_callback.html /ваш_root/payment/callback
```

---

## 📋 Краткая шпаргалка:

```bash
# 1. Подключитесь
ssh admin@ninjatraining.ru

# 2. Создайте папку и файл
sudo mkdir -p /var/www/html/payment
sudo nano /var/www/html/payment/callback

# 3. Вставьте код из payment_callback.html
# (Скопируйте весь файл → вставьте в nano → Ctrl+O → Enter → Ctrl+X)

# 4. Загрузите иконку
sudo wget https://raw.githubusercontent.com/BaronMunghauzen/ninjaTrainingFlutter/master/my_app/assets/images/iconsForApp/icon2.png -O /var/www/html/payment/ninja_icon.png

# ИЛИ используйте scp с вашего компьютера:
# scp C:\FlutterProjects\NinjaTrainingFlutter\my_app\assets\images\iconsForApp\icon2.png admin@ninjatraining.ru:/tmp/ninja_icon.png
# sudo mv /tmp/ninja_icon.png /var/www/html/payment/ninja_icon.png

# 5. Права
sudo chmod 644 /var/www/html/payment/callback
sudo chmod 644 /var/www/html/payment/ninja_icon.png
sudo chown www-data:www-data /var/www/html/payment/callback
sudo chown www-data:www-data /var/www/html/payment/ninja_icon.png

# 6. Настройте Nginx
sudo nano /etc/nginx/sites-available/ninjatraining.ru
# (Добавьте location /payment/ { ... })

# 7. Перезагрузите
sudo nginx -t
sudo systemctl reload nginx

# 8. Проверьте
curl https://ninjatraining.ru/payment/callback
curl https://ninjatraining.ru/payment/ninja_icon.png
```

---

## 🎯 Готово!

После этих шагов:
- ✅ На реальном устройстве App Links будут работать напрямую
- ✅ На эмуляторе/старых устройствах сработает fallback страница
- ✅ Красивый UI во время ожидания
- ✅ 100% надежность

**Выполните инструкцию и протестируйте!** 🚀

---

---

## 🖱️ ДЕТАЛЬНАЯ ИНСТРУКЦИЯ ДЛЯ FILEZILLA

### 📥 Шаг 1: Подключение

1. Откройте **FileZilla**
2. В **верхней панели** заполните поля:
   - **Хост:** `sftp://ninjatraining.ru`
   - **Имя пользователя:** `admin`
   - **Пароль:** [ваш SSH пароль]
   - **Порт:** `22`
3. Нажмите **"Быстрое соединение"**
4. При первом подключении появится запрос сертификата → **"OK"** или **"Всегда доверять"**

### 📂 Шаг 2: Навигация на сервере

В **ПРАВОЙ панели** (удаленный сервер):
1. Найдите папку `/var/www/html/` или `/var/www/ninjatraining.ru/`
2. Двойной клик чтобы открыть

**Совет:** В адресной строке правой панели введите `/var/www/html` и нажмите Enter

### 📁 Шаг 3: Создание папки payment

В правой панели (находясь в корне сайта):
1. **Правый клик** мыши → **"Создать каталог"**
2. В диалоговом окне введите: `payment`
3. Нажмите **"OK"**
4. **Двойной клик** по папке `payment` чтобы войти в неё

Теперь путь: `/var/www/html/payment/`

### 🗂️ Шаг 4: Подготовка на компьютере

В **ЛЕВОЙ панели** (ваш компьютер):
1. Перейдите в папку проекта:
   ```
   C:\FlutterProjects\NinjaTrainingFlutter\my_app\
   ```
2. Вы должны увидеть файл `payment_callback.html`

### 📤 Шаг 5: Загрузка HTML файла

1. В **левой панели** найдите: `payment_callback.html`
2. **Зажмите левую кнопку мыши** на файле
3. **Перетащите** его в **правую панель** (в папку `payment`)
4. Отпустите кнопку мыши
5. Внизу FileZilla появится прогресс загрузки
6. Дождитесь завершения (статус: "Передача завершена")

**Переименование:**
1. В правой панели: **правый клик** на `payment_callback.html`
2. Выберите **"Переименовать"**
3. Удалите расширение `.html`, новое имя: `callback`
4. Нажмите **"OK"**

### 🖼️ Шаг 6: Загрузка иконки

1. В **левой панели** перейдите в:
   ```
   C:\FlutterProjects\NinjaTrainingFlutter\my_app\assets\images\iconsForApp\
   ```
   (Можно ввести путь в адресной строке левой панели)

2. Найдите файл: `icon2.png`

3. **Перетащите** `icon2.png` в **правую панель** (папка `payment`)

4. Дождитесь завершения загрузки

**Переименование:**
1. В правой панели: **правый клик** на `icon2.png`
2. **"Переименовать"**
3. Новое имя: `ninja_icon.png`
4. **"OK"**

### 🔐 Шаг 7: Установка прав доступа

**Для файла callback:**
1. В правой панели: **правый клик** на `callback`
2. Выберите **"Права доступа к файлу..."**
3. В окне вы увидите:
   - Три столбца: Владелец, Группа, Публичный
   - Три строки: Чтение, Запись, Исполнение
4. **Установите галочки:**
   - ☑ Владелец: **Чтение** и **Запись**
   - ☑ Группа: **Чтение**
   - ☑ Публичный: **Чтение**
5. В поле **"Числовое значение"** должно быть: `644`
6. Нажмите **"OK"**

**Для файла ninja_icon.png:**
1. Правый клик на `ninja_icon.png`
2. **"Права доступа к файлу..."**
3. Числовое значение: `644` (или те же галочки)
4. **"OK"**

### ✅ Шаг 8: Проверка

В правой панели FileZilla должны видеть:

```
Имя файла           Размер      Права    Владелец
callback            ~7 KB       644      admin (или www-data)
ninja_icon.png      ~30 KB      644      admin (или www-data)
```

### ⚙️ Шаг 9: Настройка Nginx (через SSH)

FileZilla не может редактировать системные файлы, поэтому:

**Откройте новое окно терминала и подключитесь:**
```bash
ssh admin@ninjatraining.ru
```

**Добавьте конфигурацию в Nginx:**
```bash
sudo nano /etc/nginx/sites-available/ninjatraining.ru
```

**Добавьте внутри блока `server { ... }`:**
```nginx
# Страница возврата из оплаты
location /payment/ {
    alias /var/www/html/payment/;
    index callback;
    
    location = /payment/callback {
        default_type text/html;
        add_header Cache-Control "no-cache";
    }
    
    location = /payment/ninja_icon.png {
        default_type image/png;
    }
}
```

**Сохраните:** `Ctrl+O` → `Enter` → `Ctrl+X`

**Проверьте и перезагрузите:**
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 🧪 Шаг 10: Финальная проверка

**В браузере откройте:**
```
https://ninjatraining.ru/payment/callback
```

**Должна открыться** красивая страница с логотипом ниндзя! 🥷

**Проверьте иконку отдельно:**
```
https://ninjatraining.ru/payment/ninja_icon.png
```

Должна показаться ваша иконка!

---

## 📸 Подсказки по FileZilla:

- **Левая панель** = ваш компьютер (можно просматривать как в проводнике)
- **Правая панель** = сервер (показывает файлы на сервере)
- **Нижняя панель** = очередь загрузок и статус
- **Перетаскивание** = drag & drop файлов между панелями
- **Правый клик** = контекстное меню (переименовать, права, удалить и т.д.)

---

## ✅ Готово!

Теперь у вас на сервере будет красивая страница с **настоящим логотипом ниндзя** из вашего приложения! 🥷✨
