# frozen_string_literal: true

require 'rails_helper'
require 'central_mail/service'

RSpec.describe CentralMail::Service do
  let(:service) { described_class.new }

  describe '#status' do
    context 'with one uuid' do
      it 'retrieves the status' do
        VCR.use_cassette(
          'central_mail/status_one_uuid',
          match_requests_on: %i[body method uri]
        ) do
          response = described_class.new.status('34656d73-7c31-456d-9c49-2024fff1cd47')
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body).length).to eq(1)
        end
      end
    end

    context 'with multiple uuids' do
      it 'retrieves the statuses' do
        VCR.use_cassette(
          'central_mail/status_multiple_uuids',
          match_requests_on: %i[body method uri]
        ) do
          response = described_class.new.status(
            %w[
              34656d73-7c31-456d-9c49-2024fff1cd47
              4a25588c-9200-4405-a2fd-97f0b0fdf790
              f7725cce-a76e-4d80-ab20-01c63acfcb87
            ]
          )
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body).length).to eq(3)
        end
      end
    end
  end

  describe '#upload' do
    context 'with an bad response status' do
      it 'increments statsd' do
        expect(service).to receive(:request).and_return(
          OpenStruct.new(
            success?: false
          )
        )

        expect { service.upload('metadata' => nil) }.to trigger_statsd_increment(
          'api.central_mail.upload.fail'
        )
      end
    end

    it 'uploads a file' do
      multipart_request_matcher = lambda do |r1, r2|
        [r1, r2].each { |r| normalized_multipart_request(r) }
        expect(r1.headers).to eq(r2.headers)
      end

      VCR.use_cassette(
        'central_mail/upload',
        match_requests_on: [multipart_request_matcher, :method, :uri]
      ) do
        response = described_class.new.upload(
          metadata: get_fixture('pension/metadata').to_json,
          document: Faraday::UploadIO.new(
            'spec/fixtures/pension/form.pdf',
            Mime[:pdf].to_s
          ),
          attachment1: Faraday::UploadIO.new(
            'spec/fixtures/pension/attachment.pdf',
            Mime[:pdf].to_s
          )
        )
        body = response.body
        expect(body).to eq('Request was received successfully  [uuid: bd71f985-9bad-45c2-8b63-d052f544c27d] ')

        expect(response.status).to eq(200)
      end
    end
  end
end
