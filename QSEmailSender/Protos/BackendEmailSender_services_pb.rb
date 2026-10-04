# frozen_string_literal: true
# gRPC-заглушка для QS.Cloud.Email.BackendEmailSender (по Protos/BackendEmailSender.proto)

require 'grpc'
require_relative 'BackendEmailSender_pb'

module QS
  module Cloud
    module Email
      module BackendEmailSender
        class Service
          include ::GRPC::GenericService

          self.marshal_class_method = :encode
          self.unmarshal_class_method = :decode
          self.service_name = 'QS.Cloud.Email.BackendEmailSender'

          rpc :SendEmail, SendEmailBackendRequest, SendEmailBackendResponse
        end

        Stub = Service.rpc_stub_class
      end
    end
  end
end
