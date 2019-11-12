# frozen_string_literal: true

require 'fast_jsonapi'

module VAOS
  class ClinicSerializer
    include FastJsonapi::ObjectSerializer

    set_id :site_code
    attributes :site_code,
               :clinic_id,
               :clinic_name,
               :clinic_friendly_location_name
  end
end
