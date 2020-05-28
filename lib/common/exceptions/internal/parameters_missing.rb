# frozen_string_literal: true

require 'common/exceptions/base_error'
require 'common/exceptions/serializeable_error'

module Common
  module Exceptions::Internal
    # Parameter Missing - required parameter was not provided
    class ParametersMissing < Common::Exceptions::BaseError
      attr_reader :params

      def initialize(params)
        @params = params
      end

      def errors
        @params.map do |param|
          detail = i18n_field(:detail, param: param)
          Common::Exceptions::SerializableError.new(i18n_data.merge(detail: detail))
        end
      end
    end
  end
end
