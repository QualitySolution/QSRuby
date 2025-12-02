# frozen_string_literal: true

# Пример использования модуля QSErrorReporting в других проектах
#
# Этот файл демонстрирует различные способы использования модуля
# для отчетов об ошибках

require_relative './error_reporter_config'

# 1. Инициализация репортера
puts "=== Инициализация Error Reporter ==="
puts "Подключение к серверу: fail.cloud.qsolution.ru:4202"
puts "TLS шифрование: Выключено (будет включено при переходе на порт 443)"
begin
  error_reporter = ErrorReporterConfig.create_reporter
  puts "✓ Error reporter успешно создан"
rescue StandardError => e
  puts "✗ Ошибка при создании error reporter: #{e.message}"
  exit 1
end

# 2. Установка глобального обработчика
puts "\n=== Установка глобального обработчика ==="
error_reporter.install_global_handler!
puts "✓ Глобальный обработчик установлен"

# 3. Пример автоматической отправки ошибки
puts "\n=== Пример 1: Автоматическая отправка ошибки ==="
begin
  # Симуляция ошибки
  10 / 0
rescue StandardError => e
  puts "Поймана ошибка: #{e.message}"
  if error_reporter.report_error(e, report_type: :automatic)
    puts "✓ Ошибка отправлена на сервер (автоматический отчет)"
  else
    puts "✗ Не удалось отправить ошибку"
  end
end

# 4. Пример отправки ошибки с описанием пользователя
puts "\n=== Пример 2: Отправка с описанием пользователя ==="
begin
  # Симуляция ошибки
  data = nil
  data.fetch('key')
rescue StandardError => e
  puts "Поймана ошибка: #{e.message}"
  if error_reporter.report_error(
    e,
    report_type: :user,
    user_description: 'Пользователь пытался получить доступ к данным, но произошла ошибка',
    log: 'Additional context: User was trying to access critical data'
  )
    puts "✓ Ошибка с описанием отправлена на сервер"
  else
    puts "✗ Не удалось отправить ошибку"
  end
end

# 5. Пример известной ошибки
puts "\n=== Пример 3: Отправка известной ошибки ==="
begin
  # Симуляция известной проблемы
  raise ArgumentError, "Известная проблема: недостаточно параметров"
rescue StandardError => e
  puts "Поймана известная ошибка: #{e.message}"
  if error_reporter.report_error(e, report_type: :known)
    puts "✓ Известная ошибка отправлена на сервер"
  else
    puts "✗ Не удалось отправить ошибку"
  end
end

# 6. Пример необработанной ошибки (будет поймана глобальным обработчиком)
puts "\n=== Пример 4: Необработанная ошибка ==="
puts "Внимание: следующая ошибка будет необработанной и перехвачена глобальным обработчиком"
puts "Раскомментируйте следующую строку для проверки:"
# raise RuntimeError, "Это необработанная ошибка для демонстрации глобального обработчика"

puts "\n=== Примеры завершены ==="
puts "Все примеры выполнены. Проверьте сервер отчетов об ошибках для просмотра отправленных данных."
