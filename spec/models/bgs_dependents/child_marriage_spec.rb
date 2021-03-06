# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BGSDependents::ChildMarriage do
  let(:child_marriage_info) do
    {
      'date_married' => '1977-02-01',
      'full_name' => { 'first' => 'Billy', 'middle' => 'Yohan', 'last' => 'Johnson', 'suffix' => 'Sr.' }
    }
  end
  let(:formatted_params_result) do
    {
      'event_date' => '1977-02-01',
      'first' => 'Billy',
      'middle' => 'Yohan',
      'last' => 'Johnson',
      'suffix' => 'Sr.'
    }
  end

  describe '#format_info' do
    it 'formats child marriage params for submission' do
      formatted_info = described_class.new(child_marriage_info).format_info

      expect(formatted_info).to eq(formatted_params_result)
    end
  end
end
