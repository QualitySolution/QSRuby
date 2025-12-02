# frozen_string_literal: true
# Generated gRPC service stub for QS.ErrorReporting.Reception

require 'grpc'
require_relative 'Reception_pb'

module QS
  module ErrorReporting
    module Reception
      class Service
        include ::GRPC::GenericService

        self.marshal_class_method = :encode
        self.unmarshal_class_method = :decode
        self.service_name = 'QS.ErrorReporting.Reception'

        # SubmitError RPC method
        rpc :SubmitError, SubmitErrorRequest, SubmitErrorResponse
      end

      Stub = Service.rpc_stub_class
    end
  end
end
