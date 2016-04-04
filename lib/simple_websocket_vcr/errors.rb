module WebSocketVCR
  module Errors
    class VCRError < StandardError; end
    class OperationMismatchError < VCRError; end
    class DataMismatchError < VCRError; end
    class NoCassetteError < VCRError; end
    class NoMoreSessionsError < VCRError; end
  end
end
