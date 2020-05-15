# frozen_string_literal: true
require_relative 'value_objects/vnp_person_address_phone'

module BGS
  class VnpVeteran < Base
    def initialize(proc_id:, payload:, user:)
      @proc_id = proc_id
      @veteran_info = formatted_params(payload)

      super(user) # is this cool? Might be smelly. Might indicate a new class/object 🤔
    end

    def create
      participant = create_participant(@proc_id, nil)
      # claim_type_end_product = find_benefit_claim_type_increment # we will be using this once we figure it out
      person = create_person(@proc_id, participant[:vnp_ptcpnt_id], @veteran_info)
      phone = create_phone(@proc_id, participant[:vnp_ptcpnt_id], @veteran_info)
      address = create_address(@proc_id, participant[:vnp_ptcpnt_id], @veteran_info)

      ::ValueObjects::VnpPersonAddressPhone.new(
        vnp_proc_id: @proc_id,
        vnp_participant_id: participant[:vnp_ptcpnt_id],
        vnp_participant_address_id: address[:vnp_ptcpnt_addrs_id],
        participant_relationship_type_name: 'Veteran',
        family_relationship_type_name: 'Veteran',
        first_name: person[:first_nm],
        middle_name: person[:first_nm],
        last_name: person[:last_nm],
        suffix_name: person[:suffix_nm],
        birth_date: person[:brthdy_dt],
        birth_state_code: person[:birth_state_cd],
        birth_city_name: person[:birth_city_nm],
        file_number: person[:file_nbr],
        ssn_number: person[:ssn_nbr],
        phone_number: phone[:phone_nbr],
        address_line_one: address[:addrs_one_txt],
        address_line_two: address[:addrs_two_txt],
        address_line_three: address[:addrs_three_txt],
        address_country: address[:cntry_nm],
        address_state_code: address[:postal_cd],
        address_city: address[:city_nm],
        address_zip_code: address[:zip_prefix_nbr],
        email_address: address[:email_addrs_txt],
        type: 'veteran',
        living_expenses_paid_amount: nil,
        benefit_claim_type_end_product: '', # Temporarily empty until we figure out the increment call
        death_date: nil, # Setting to nil to satisfy struct these are dependent values
        begin_date: nil, # Setting to nil to satisfy struct these are dependent values
        end_date: nil, # Setting to nil to satisfy struct these are dependent values
        event_date: nil,
        ever_married_indicator: nil, # Setting to nil to satisfy struct these are dependent values
        marriage_state: nil, # Setting to nil to satisfy struct these are dependent values
        marriage_city: nil, # Setting to nil to satisfy struct these are dependent values
        divorce_state: nil, # Setting to nil to satisfy struct these are dependent values
        divorce_city: nil, # Setting to nil to satisfy struct these are dependent values
        marriage_termination_type_code: nil # Setting to nil to satisfy struct these are dependent values
      )
    end

    private

    def formatted_params(payload)
      dependents_application = payload['dependents_application']
      vet_info = [
        *payload['veteran_information'],
        *payload.dig('veteran_information', 'full_name'),
        *dependents_application.dig('veteran_contact_information'),
        *dependents_application.dig('veteran_contact_information', 'veteran_address'),
        ['vet_ind', 'Y']
      ]

      if dependents_application['current_marriage_information']
        vet_info << ['martl_status_type_cd', dependents_application['current_marriage_information']['type']]
      end

      vet_info.to_h
    end
  end
end