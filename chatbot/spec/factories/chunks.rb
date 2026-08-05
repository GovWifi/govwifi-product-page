FactoryBot.define do
  factory :chunk do
    document
    sequence(:position) { |n| n }
    heading_chain { "Get started > Sign up" }
    content { "To sign up for GovWifi, visit www.wifi.service.gov.uk..." }
    embedding { Array.new(1536) { rand(-1.0..1.0) } }
    token_count { 128 }
  end
end
