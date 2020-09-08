# frozen_string_literal: true

FactoryBot.define do
  factory :va_form, class: 'VaForms::Form' do
    form_name { '526ez' }
    url { 'https://va.gov/va_form/21-526ez.pdf' }
    title { 'Disability Compensation' }
    first_issued_on { Time.zone.today - 1.day }
    last_revision_on { Time.zone.today }
    pages { 2 }
    valid_pdf { true }
    sha256 { 'somelongsha' }

    trait :has_been_deleted do
      deleted_at { '2020-07-16T00:00:00.000Z' }
    end
  end
end
