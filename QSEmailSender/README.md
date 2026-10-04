# QS Email Sender Module

Универсальный клиент для отправки писем через службу QS.Cloud.Email (gRPC, backend-токен).
Аналог C#-клиента `QS.Cloud.Email.BackendClient`.

## Структура

```
QSRuby/QSEmailSender/
├── Protos/
│   ├── BackendEmailSender.proto          # Protobuf определение (копия из QS.Cloud.Email)
│   ├── BackendEmailSender_pb.rb          # Сгенерированный код protobuf
│   └── BackendEmailSender_services_pb.rb # gRPC stub
├── spec/
│   └── backend_client_spec.rb            # Тесты (rspec)
└── backend_client.rb                     # Клиент
```

## Зависимости

```ruby
gem 'addressable'
gem 'google-protobuf'
gem 'grpc'
```

## Использование

```ruby
require_relative 'QSRuby/QSEmailSender/backend_client'

client = QSEmailSender::BackendClient.new('backend-token')
client.send_email('user@example.ru', 'Тема', 'Текст письма')
```

Адрес службы (`emailsender.cloud.qsolution.ru:443`) зашит в клиент.
Кириллический домен получателя автоматически переводится в punycode.
При ошибке отправки бросается исключение.

## Получение токена

Токен выдаётся в программе «QS: Инсайдер»: в диалоге продукта на вкладке «Email токены».
Токен — это отдельный отправитель писем. Он привязан к службе (продукту), а на одной службе
может быть много токенов, например по одному на каждый сайт или подразделение.

## Обновление заглушек protobuf

`BackendEmailSender_pb.rb` генерируется из proto, заглушку сервиса пишем вручную (нет grpc_tools):

```bash
protoc --ruby_out=QSRuby/QSEmailSender -I QSRuby/QSEmailSender QSRuby/QSEmailSender/Protos/BackendEmailSender.proto
```

## Тесты

Тесты написаны на rspec и запускаются из проекта, который подключает QSRuby (нужны gem `rspec`):

```bash
bundle exec rspec QSRuby/QSEmailSender/spec
```
