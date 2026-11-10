require_relative '../log_buffer'

describe QSErrorReporting::LogBuffer do
  it 'combines UTF-8 and binary output into valid UTF-8' do
    buffer = described_class.new
    buffer.add_line('Ошибка')
    buffer.add_line("Текст".b)
    buffer.add_line("\xFF".b)

    log = buffer.get_last_lines
    expect(log).to be_valid_encoding
    expect(log).to include('Ошибка', 'Текст', "\uFFFD")
  end
end
