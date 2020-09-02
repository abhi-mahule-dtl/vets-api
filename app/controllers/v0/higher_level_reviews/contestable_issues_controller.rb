# frozen_string_literal: true

module V0
  module HigherLevelReviews
    class ContestableIssuesController < AppealsBaseController
      def index
        issues = decision_review_service.get_contestable_issues(user: current_user, benefit_type: params[:benefit_type])
        render json: issues.body
      end
    end
  end
end
