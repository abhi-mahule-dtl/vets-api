# frozen_string_literal: true

module V0
  class MviUsersController < ApplicationController
    before_action { authorize :mvi, :access_add_person? }

    def submit
      # Caller must be using proxy add in order to complete Intent to File or Disability Compensation forms
      form_id = params[:id]
      if ['21-0966', VA526ez::FORM_ID].exclude?(form_id)
        raise Common::Exceptions::Internal::Forbidden.new(
          detail: "Action is prohibited with id parameter #{form_id}",
          source: 'MviUsersController'
        )
      end

      # Scenario indicates serious problems with user data
      if @current_user.birls_id.nil? && @current_user.participant_id.present?
        raise Common::Exceptions::External::UnprocessableEntity.new(
          detail: 'No birls_id while participant_id present',
          source: 'MviUsersController'
        )
      end

      # Make request to MVI to gather and update user ids
      add_response = @current_user.mvi.mvi_add_person
      raise add_response.error unless add_response.ok?

      render json: { "message": 'Success' }
    end
  end
end
