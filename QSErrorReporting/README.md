# QS Error Reporting Module

Универсальный модуль для отправки необработанных ошибок на сервер через gRPC.

## Структура

```
QSRuby/QSErrorReporting/
├── Protos/
│   ├── Reception.proto          # Protobuf определение
│   ├── Reception_pb.rb          # Сгенерированный код protobuf
│   └── Reception_services_pb.rb # Сгенерированный gRPC stub
└── error_reporter.rb            # Основной модуль
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
      database_name: 'your_db'                # Имя БД (опционально)
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
```

### 3. Ручная отправка ошибок

```ruby
begin
  # Ваш код
  risky_operation
rescue StandardError => e
  # Отправить ошибку на сервер
  $error_reporter.report_error(e, report_type: :automatic)
  
  # Можно добавить описание пользователя и логи
  $error_reporter.report_error(
    e, 
    report_type: :user,
    user_description: 'Ошибка при обновлении данных',
    log: 'Дополнительная информация из логов'
  )
end
```

### 4. Типы отчетов

- `:automatic` - автоматическая отправка необработанных ошибок
- `:user` - ошибка, отправленная пользователем с описанием
- `:known` - известная ошибка

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

## Регенерация protobuf файлов

Если вы изменили `Reception.proto`, необходимо перегенерировать Ruby код:

```bash
cd QSRuby/QSErrorReporting
protoc --ruby_out=. Protos/Reception.proto
```

## Возможности

- ✅ Автоматическая отправка необработанных исключений
- ✅ Ручная отправка ошибок с дополнительной информацией
- ✅ Поддержка gRPC с TLS
- ✅ Настраиваемый таймаут
- ✅ Конфигурируемые параметры для каждого проекта
- ✅ Сбор stack trace и сообщений об ошибках
- ✅ Поддержка информации о пользователе и БД

## Лицензия

См. LICENSE файл в корне проекта.
