# frozen_string_literal: true

require 'rails_helper'
RSpec.describe 'health_quest appointments', type: :request, skip_mvi: true do
  include SchemaMatchers

  before do
    Flipper.enable('va_online_scheduling')
    sign_in_as(current_user)
    allow_any_instance_of(HealthQuest::UserService).to receive(:session).and_return('stubbed_token')
  end

  context 'loa1 user' do
    let(:current_user) { build(:user, :loa1) }

    describe 'GET appointments' do
      it 'does not have access' do
        get '/health_quest/v0/appointments'
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['errors'].first['detail'])
          .to eq('You do not have access to online scheduling')
      end
    end
  end

  context 'loa3 user' do
    let(:current_user) { build(:user, :health_quest) }

    describe 'GET appointments' do
      let(:start_date) { Time.zone.parse('2020-06-02T07:00:00Z') }
      let(:end_date) { Time.zone.parse('2020-07-02T08:00:00Z') }
      let(:params) { { type: 'va', start_date: start_date, end_date: end_date } }

      context 'with flipper disabled' do
        it 'does not have access' do
          Flipper.disable('va_online_scheduling')
          get '/health_quest/v0/appointments'
          expect(response).to have_http_status(:forbidden)
          expect(JSON.parse(response.body)['errors'].first['detail'])
            .to eq('You do not have access to online scheduling')
        end
      end

      context 'without icn' do
        before { stub_mvi_not_found }

        let(:current_user) { build(:user, :mhv, mhv_icn: nil) }

        it 'does not have access' do
          get '/health_quest/v0/appointments'
          expect(response).to have_http_status(:forbidden)
          expect(JSON.parse(response.body)['errors'].first['detail'])
            .to eq('No patient ICN found')
        end
      end

      context 'without a type' do
        it 'has a parameter missing exception' do
          get '/health_quest/v0/appointments', params: params.except(:type)
          expect(response).to have_http_status(:bad_request)
          expect(response.body).to be_a(String)
          expect(JSON.parse(response.body)['errors'].first['detail'])
            .to eq('The required parameter "type", is missing')
        end
      end

      context 'without a start_date' do
        it 'has a parameter missing exception' do
          get '/health_quest/v0/appointments', params: params.except(:start_date)
          expect(response).to have_http_status(:bad_request)
          expect(response.body).to be_a(String)
          expect(JSON.parse(response.body)['errors'].first['detail'])
            .to eq('The required parameter "start_date", is missing')
        end
      end

      context 'without an end_date' do
        it 'has a parameter missing exception' do
          get '/health_quest/v0/appointments', params: params.except(:end_date)
          expect(response).to have_http_status(:bad_request)
          expect(response.body).to be_a(String)
          expect(JSON.parse(response.body)['errors'].first['detail'])
            .to eq('The required parameter "end_date", is missing')
        end
      end

      context 'with an invalid type' do
        it 'has an invalid field type exception' do
          get '/health_quest/v0/appointments', params: params.merge(type: 'invalid')
          expect(response).to have_http_status(:bad_request)
          expect(response.body).to be_a(String)
          expect(JSON.parse(response.body)['errors'].first['detail'])
            .to eq('"invalid" is not a valid value for "type"')
        end
      end

      context 'with an invalid start_date' do
        it 'has an invalid field type exception' do
          get '/health_quest/v0/appointments', params: params.merge(start_date: 'invalid')
          expect(response).to have_http_status(:bad_request)
          expect(response.body).to be_a(String)
          expect(JSON.parse(response.body)['errors'].first['detail'])
            .to eq('"invalid" is not a valid value for "start_date"')
        end
      end

      context 'with an invalid end_date' do
        it 'has an invalid field type exception' do
          get '/health_quest/v0/appointments', params: params.merge(end_date: 'invalid')
          expect(response).to have_http_status(:bad_request)
          expect(response.body).to be_a(String)
          expect(JSON.parse(response.body)['errors'].first['detail'])
            .to eq('"invalid" is not a valid value for "end_date"')
        end
      end

      it 'has access and returns va appointments' do
        VCR.use_cassette('health_quest/appointments/get_appointments', match_requests_on: %i[method uri]) do
          get '/health_quest/v0/appointments', params: params

          expect(response).to have_http_status(:success)
          expect(response.body).to be_a(String)
          expect(response).to match_response_schema('health_quest/va_appointments', { strict: false })
        end
      end

      it 'has access and returns cc appointments' do
        VCR.use_cassette('health_quest/appointments/get_cc_appointments', match_requests_on: %i[method uri]) do
          get '/health_quest/v0/appointments', params: params.merge(type: 'cc')
          expect(response).to have_http_status(:success)
          expect(response.body).to be_a(String)
          expect(response).to match_response_schema('health_quest/cc_appointments')
        end
      end

      context 'with no appointments' do
        it 'returns an empty list' do
          VCR.use_cassette('health_quest/appointments/get_appointments_empty', match_requests_on: %i[method uri]) do
            get '/health_quest/v0/appointments', params: params
            expect(response).to have_http_status(:success)
            expect(JSON.parse(response.body)).to eq(
              'data' => [],
              'meta' => {
                'pagination' => {
                  'current_page' => 0,
                  'per_page' => 0,
                  'total_entries' => 0,
                  'total_pages' => 0
                }
              }
            )
            expect(response).to match_response_schema('health_quest/va_appointments')
          end
        end
      end

      context 'with a response that includes blank providers' do
        it 'parses the data and does not throw an undefined method error' do
          VCR.use_cassette('health_quest/appointments/get_appointments_map_error', match_requests_on: %i[method uri]) do
            get '/health_quest/v0/appointments', params: params
            expect(response).to have_http_status(:success)
            expect(response).to match_response_schema('health_quest/va_appointments', { strict: false })
          end
        end
      end
    end
  end
end