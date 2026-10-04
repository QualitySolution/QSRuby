# frozen_string_literal: true

require_relative '../backend_client'

describe QSEmailSender::BackendClient do
  let(:stub) { double('stub') }
  let(:sender) { described_class.new('token-1', stub: stub) }

  it 'отправляет письмо с backend-токеном и кириллический домен передаёт как punycode' do
    expect(stub).to receive(:send_email) do |request, metadata:|
      message = request.messages.first
      expect(message.email_address).to eq('valy@xn----7sbbabmkcagl6becj5cfubvdm0a70a.xn--p1ai')
      expect(message.title).to eq('Тема')
      expect(message.text).to eq('Текст')
      expect(metadata).to eq('authorization' => 'Bearer token-1')
      QS::Cloud::Email::SendEmailBackendResponse.new
    end

    sender.send_email('valy@петербургская-сладкоежка.рф', 'Тема', 'Текст')
  end

  it 'бросает исключение, если служба вернула ошибку' do
    allow(stub).to receive(:send_email).and_return(QS::Cloud::Email::SendEmailBackendResponse.new(results: 'ошибка smtp'))

    expect { sender.send_email('a@b.ru', 'Тема', 'Текст') }.to raise_error(/ошибка smtp/)
  end

  it 'не создаётся без токена' do
    expect { described_class.new('', stub: stub) }.to raise_error(ArgumentError)
  end
end
