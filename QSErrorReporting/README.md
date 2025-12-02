# QS Error Reporting Module

Универсальный модуль для отправки необработанных ошибок на сервер через gRPC.

## Структура

```
QSRuby/QSErrorReporting/
├── Protos/
│   ├── Reception.proto          # Protobuf определение
│   ├── Reception_pb.rb          # Сгенерированный код protobuf
│   └── Reception_services_pb.rb # Сгенерированный gRPC stub
├── error_reporter.rb            # Основной модуль
├── log_buffer.rb                # Буфер для захвата логов
└── example_usage.rb             # Примеры использования
```

## Зависимости

Для работы модуля необходимы следующие gem-пакеты:

```ruby
gem 'grpc'
gem 'google-protobuf'
```

Установка:
```bash
gem install grpc google-protobuf
```

## Настройки соединения

Модуль использует встроенные настройки для подключения к серверу ошибок:
- **Сервер**: fail.cloud.qsolution.ru
- **Порт**: 4202
- **TLS**: Выключен (будет включен при переходе на порт 443)
- **Таймаут**: 10 секунд

Эти параметры зашиты в модуль и не требуют настройки в проектах.

## Использование

### 1. Создание конфигурации

Создайте файл конфигурации для вашего проекта (например, `error_reporter_config.rb`):

```ruby
require_relative './QSRuby/QSErrorReporting/error_reporter'

module ErrorReporterConfig
  def self.create_reporter
    config = {
      product_code: 1001,                     # Уникальный код продукта
      modification: 'YourAppName',            # Название приложения
      version: '1.0.0',                       # Версия приложения
      user_name: 'user',                      # Имя пользователя (опционально)
      user_email: 'user@example.com',         # Email (опционально)
      database_name: 'your_db',               # Имя БД (опционально)
      log_buffer_size: 300,                   # Размер буфера логов (строк)
      auto_capture_logs: true                 # Автозахват STDOUT/STDERR
    }
    
    QSErrorReporting::ErrorReporter.new(config)
  end
end
```

### 2. Инициализация в приложении

```ruby
require './error_reporter_config'

# Создать экземпляр репортера
$error_reporter = ErrorReporterConfig.create_reporter

# Установить глобальный обработчик (автоматически перехватывает необработанные исключения)
$error_reporter.install_global_handler!

# Логи автоматически захватываются, если auto_capture_logs: true в конфигурации
```

### 3. Ручная отправка ошибок

```ruby
begin
  # Ваш код
  risky_operation
rescue StandardError => e
  # Отправить ошибку на сервер (логи добавятся автоматически)
  $error_reporter.report_error(e, report_type: :automatic)
  
  # Можно добавить описание пользователя
  $error_reporter.report_error(
    e, 
    report_type: :user,
    user_description: 'Ошибка при обновлении данных'
  )
  
  # Или передать свои логи вместо автоматических
  $error_reporter.report_error(
    e,
    report_type: :automatic,
    log: 'Свои логи вместо буфера'
  )
end
```

### 4. Управление логами

```ruby
# Получить последние N строк лога
last_100_lines = $error_reporter.get_logs(100)

# Получить все логи из буфера
all_logs = $error_reporter.get_logs

# Очистить буфер логов
$error_reporter.clear_logs

# Остановить захват логов
$error_reporter.stop_log_capture

# Возобновить захват логов
$error_reporter.start_log_capture
```

### 5. Типы отчетов

- `:automatic` - автоматическая отправка необработанных ошибок (с логами)
- `:user` - ошибка, отправленная пользователем с описанием (с логами)
- `:known` - известная ошибка (с логами)

## Изменение настроек соединения

Если требуется изменить сервер или порт подключения, отредактируйте константы в файле `error_reporter.rb`:

```ruby
SERVER_HOST = 'fail.cloud.qsolution.ru'
SERVER_PORT = 4202
USE_TLS = false  # Установите true при переходе на порт 443
```

## Пример интеграции

См. файл `update_from_api.rb` для примера полной интеграции модуля.

## Безопасность

- При переходе на порт 443 будет включено TLS шифрование
- Не храните чувствительные данные (пароли, токены) в описаниях ошибок
- Модуль автоматически собирает только stack trace и сообщения об ошибках

## Как работает захват логов

### Принцип работы

1. **LogBuffer** перехватывает все вызовы `puts`, `print`, `printf` к STDOUT и STDERR
2. Каждая строка сохраняется в кольцевой буфер с временной меткой
3. Буфер хранит только последние N строк (по умолчанию 300)
4. При отправке ошибки, если параметр `log` пуст, автоматически используются логи из буфера
5. Вывод продолжает отображаться в консоли как обычно (прозрачный перехват)

### Формат логов

Каждая строка лога имеет формат:
```
YYYY-MM-DD HH:MM:SS | Текст сообщения
```

Пример:
```
2025-12-02 14:30:15 | Обновление акций для аккаунта 1...
2025-12-02 14:30:16 | Обновление заказов для аккаунта 1...
2025-12-02 14:30:17 | FATAL ERROR: RuntimeError: Something went wrong
```

### Настройка размера буфера

Можно изменить количество сохраняемых строк в конфигурации:

```ruby
config = {
  log_buffer_size: 500,  # Хранить последние 500 строк
  # ...
}
```

### Отключение автозахвата

Если не нужен автоматический захват логов:

```ruby
config = {
  auto_capture_logs: false,  # Отключить автозахват
  # ...
}

# Включить вручную при необходимости
error_reporter.start_log_capture
```

## Регенерация protobuf файлов

Если вы изменили `Reception.proto`, необходимо перегенерировать Ruby код:

```bash
cd QSRuby/QSErrorReporting
protoc --ruby_out=. Protos/Reception.proto
```

## Возможности

- ✅ Автоматическая отправка необработанных исключений
- ✅ Ручная отправка ошибок с дополнительной информацией
- ✅ **Автоматический захват последних 300 строк лога** (STDOUT/STDERR)
- ✅ Логи с временными метками
- ✅ Поддержка gRPC с TLS
- ✅ Настраиваемый таймаут
- ✅ Конфигурируемые параметры для каждого проекта
- ✅ Сбор stack trace и сообщений об ошибках
- ✅ Поддержка информации о пользователе и БД
- ✅ Потокобезопасный буфер логов

## Лицензия

См. LICENSE файл в корне проекта.
