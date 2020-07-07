# frozen_string_literal: true

require 'rails_helper'
require 'common/exceptions'
require 'support/mpi/stub_mpi'

describe MPIData, skip_mpi: true do
  let(:user) { build(:user, :loa3) }
  let(:mpi) { MPIData.for_user(user) }
  let(:mpi_profile) { build(:mpi_profile) }
  let(:mpi_codes) do
    {
      birls_id: '111985523',
      participant_id: '32397028'
    }
  end
  let(:profile_response) do
    MPI::Responses::FindProfileResponse.new(
      status: MPI::Responses::FindProfileResponse::RESPONSE_STATUS[:ok],
      profile: mpi_profile
    )
  end
  let(:profile_response_error) { MPI::Responses::FindProfileResponse.with_server_error(server_error_exception) }
  let(:profile_response_not_found) { MPI::Responses::FindProfileResponse.with_not_found(not_found_exception) }
  let(:add_response) do
    MPI::Responses::AddPersonResponse.new(
      status: MPI::Responses::AddPersonResponse::RESPONSE_STATUS[:ok],
      mpi_codes: mpi_codes
    )
  end
  let(:add_response_error) { MPI::Responses::AddPersonResponse.with_server_error(server_error_exception) }
  let(:default_ttl) { REDIS_CONFIG[MPIData::REDIS_CONFIG_KEY.to_s]['each_ttl'] }
  let(:failure_ttl) { REDIS_CONFIG[MPIData::REDIS_CONFIG_KEY.to_s]['failure_ttl'] }

  describe '.new' do
    it 'creates an instance with user attributes' do
      expect(mpi.user).to eq(user)
    end
  end

  describe '#mpi_add_person' do
    context 'with a successful add' do
      it 'returns the successful response' do
        allow_any_instance_of(MPI::Service).to receive(:find_profile).and_return(profile_response)
        allow_any_instance_of(MPI::Service).to receive(:add_person).and_return(add_response)
        expect_any_instance_of(MPIData).to receive(:add_ids).once.and_call_original
        expect_any_instance_of(MPIData).to receive(:cache).once.and_call_original
        response = user.mpi.mpi_add_person
        expect(response.status).to eq('OK')
      end
    end

    context 'with a failed search' do
      it 'returns the failed search response' do
        allow_any_instance_of(MPI::Service).to receive(:find_profile).and_return(profile_response_error)
        response = user.mpi.mpi_add_person
        expect_any_instance_of(MPI::Service).not_to receive(:add_person)
        expect(response.status).to eq('SERVER_ERROR')
      end
    end

    context 'with a failed add' do
      it 'returns the failed add response' do
        allow_any_instance_of(MPI::Service).to receive(:find_profile).and_return(profile_response)
        allow_any_instance_of(MPI::Service).to receive(:add_person).and_return(add_response_error)
        expect_any_instance_of(MPIData).not_to receive(:add_ids)
        expect_any_instance_of(MPIData).not_to receive(:cache)
        response = user.mpi.mpi_add_person
        expect(response.status).to eq('SERVER_ERROR')
      end
    end
  end

  describe '#profile' do
    context 'when the cache is empty' do
      it 'caches and return an :ok response', :aggregate_failures do
        allow_any_instance_of(MPI::Service).to receive(:find_profile).and_return(profile_response)
        expect(mpi).to receive(:save).once
        expect_any_instance_of(MPI::Service).to receive(:find_profile).once
        expect(mpi.status).to eq('OK')
        expect(mpi.send(:record_ttl)).to eq(86_400)
        expect(mpi.error).to be_nil
      end
      it 'returns an :error response but not cache it', :aggregate_failures do
        allow_any_instance_of(MPI::Service).to receive(:find_profile).and_return(profile_response_error)
        expect(mpi).not_to receive(:save)
        expect_any_instance_of(MPI::Service).to receive(:find_profile).once
        expect(mpi.status).to eq('SERVER_ERROR')
        expect(mpi.error).to be_present
        expect(mpi.error.class).to eq Common::Exceptions::BackendServiceException
      end
      it 'returns a :not_found response and cache it for a shorter time', :aggregate_failures do
        allow_any_instance_of(MPI::Service).to receive(:find_profile).and_return(profile_response_not_found)
        expect(mpi).to receive(:save).once
        expect_any_instance_of(MPI::Service).to receive(:find_profile).once
        expect(mpi.status).to eq('NOT_FOUND')
        expect(mpi.send(:record_ttl)).to eq(1800)
        expect(mpi.error).to be_present
        expect(mpi.error.class).to eq Common::Exceptions::BackendServiceException
      end
    end

    context 'when there is cached data' do
      it 'returns the cached data for :ok response', :aggregate_failures do
        mpi.cache(user.uuid, profile_response)
        expect_any_instance_of(MPI::Service).not_to receive(:find_profile)
        expect(mpi.profile).to have_deep_attributes(mpi_profile)
        expect(mpi.error).to be_nil
      end
      it 'returns the cached data for :error response', :aggregate_failures do
        mpi.cache(user.uuid, profile_response_error)
        expect_any_instance_of(MPI::Service).not_to receive(:find_profile)
        expect(mpi.profile).to be_nil
        expect(mpi.error).to be_present
        expect(mpi.error.class).to eq Common::Exceptions::BackendServiceException
      end
      it 'returns the cached data for :not_found response', :aggregate_failures do
        mpi.cache(user.uuid, profile_response_not_found)
        expect_any_instance_of(MPI::Service).not_to receive(:find_profile)
        expect(mpi.profile).to be_nil
        expect(mpi.error).to be_present
        expect(mpi.error.class).to eq Common::Exceptions::BackendServiceException
      end
    end
  end

  describe 'correlation ids' do
    context 'with a successful response' do
      before do
        allow_any_instance_of(MPI::Service).to receive(:find_profile).and_return(profile_response)
      end

      describe '#edipi' do
        it 'matches the response' do
          expect(mpi.edipi).to eq(profile_response.profile.edipi)
        end
      end

      describe '#icn' do
        it 'matches the response' do
          expect(mpi.icn).to eq(profile_response.profile.icn)
        end
      end

      describe '#icn_with_aaid' do
        it 'matches the response' do
          expect(mpi.icn_with_aaid).to eq(profile_response.profile.icn_with_aaid)
        end
      end

      describe '#mhv_correlation_id' do
        it 'matches the response' do
          expect(mpi.mhv_correlation_id).to eq(profile_response.profile.mhv_correlation_id)
        end
      end

      describe '#participant_id' do
        it 'matches the response' do
          expect(mpi.participant_id).to eq(profile_response.profile.participant_id)
        end
      end

      describe '#historical_icns' do
        it 'matches the response' do
          expect(mpi.historical_icns).to eq(profile_response.profile.historical_icns)
        end
      end

      describe '#vet360_id' do
        it 'matches the response' do
          expect(mpi.vet360_id).to eq(profile_response.profile.vet360_id)
        end
      end
    end

    context 'with an error response' do
      before do
        allow_any_instance_of(MPI::Service).to receive(:find_profile).and_return(profile_response_error)
      end

      it 'captures the error in #error' do
        expect(mpi.error).to be_present
      end

      describe '#edipi' do
        it 'is nil' do
          expect(mpi.edipi).to be_nil
        end
      end

      describe '#icn' do
        it 'is nil' do
          expect(mpi.icn).to be_nil
        end
      end

      describe '#icn_with_aaid' do
        it 'is nil' do
          expect(mpi.icn_with_aaid).to be_nil
        end
      end

      describe '#mhv_correlation_id' do
        it 'is nil' do
          expect(mpi.mhv_correlation_id).to be_nil
        end
      end

      describe '#participant_id' do
        it 'is nil' do
          expect(mpi.participant_id).to be_nil
        end
      end
    end
  end

  describe '#add_ids' do
    let(:mpi) { MPIData.for_user(user) }
    let(:response) do
      MPI::Responses::AddPersonResponse.new(
        status: 'OK',
        mpi_codes: {
          birls_id: '1234567890',
          participant_id: '0987654321'
        }
      )
    end

    it 'updates the user profile and updates the cache' do
      allow_any_instance_of(MPI::Service).to receive(:find_profile).and_return(profile_response)
      expect_any_instance_of(MPIData).to receive(:cache).twice.and_call_original
      mpi.send(:add_ids, response)
      expect(user.participant_id).to eq('0987654321')
      expect(user.birls_id).to eq('1234567890')
    end
  end
end
