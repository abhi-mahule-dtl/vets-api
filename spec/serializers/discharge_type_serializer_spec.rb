# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DischargeTypeSerializer, type: :serializer do
  subject { serialize(discharge_type, serializer_class: described_class) }

  let(:discharge_type) { build :discharge_type }
  let(:data) { JSON.parse(subject)['data'] }
  let(:attributes) { data['attributes'] }

  it 'includes id' do
    expect(data['id'].to_i).to eq(discharge_type.id)
  end

  it 'includes the discharge_type_id' do
    expect(attributes['discharge_type_id']).to eq(discharge_type.id)
  end

  it 'includes the description' do
    expect(attributes['description']).to eq(discharge_type.description)
  end
end
