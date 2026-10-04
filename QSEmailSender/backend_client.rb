# frozen_string_literal: true

require 'addressable/idna'
require 'grpc'
require_relative 'Protos/BackendEmailSender_pb'
require_relative 'Protos/BackendEmailSender_services_pb'

module QSEmailSender
  # Отправка писем через службу QS.Cloud.Email (gRPC, авторизация по backend-токену).
  class BackendClient
    SERVICE_ADDRESS = 'emailsender.cloud.qsolution.ru:443'

    # @param token [String] backend-токен, выдаётся в QS: Инсайдер (диалог продукта, вкладка «Email токены»)
    # @param stub [Object] подмена gRPC-клиента для тестов
    def initialize(token, stub: nil)
      raise ArgumentError, 'Не задан backend-токен' if token.to_s.strip.empty?

      @token = token
      @stub = stub || QS::Cloud::Email::BackendEmailSender::Stub.new(
        SERVICE_ADDRESS, GRPC::Core::ChannelCredentials.new
      )
    end

    # Отправляет одно письмо. Бросает исключение, если письмо не отправлено.
    # @param to [String] адрес получателя (кириллический домен допустим)
    # @param title [String] тема
    # @param text [String] текст
    def send_email(to, title, text)
      message = QS::Cloud::Email::OutgoingEmail.new(email_address: ascii_address(to), title: title, text: text)
      request = QS::Cloud::Email::SendEmailBackendRequest.new(messages: [message])
      response = @stub.send_email(request, metadata: { 'authorization' => "Bearer #{@token}" })
      raise "Почтовая служба вернула ошибку: #{response.results}" unless response.results.to_s.empty?
    end

    private

    # Кириллический домен передаём в виде punycode, чтобы почтовый сервер его принял.
    def ascii_address(address)
      local, domain = address.split('@', 2)
      "#{local}@#{Addressable::IDNA.to_ascii(domain)}"
    end
  end
end
