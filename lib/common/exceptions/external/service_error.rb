# frozen_string_literal: true

require 'common/exceptions/base_error'

module Common
  module Exceptions::External
    class ServiceError < Common::Exceptions::BaseError
      attr_writer :source

      def initialize(options = {})
        @detail = options[:detail]
        @source = options[:source]
      end

      def errors
        Array(Common::Exceptions::SerializableError.new(i18n_data.merge(detail: @detail, source: @source)))
      end
    end
  end
end
