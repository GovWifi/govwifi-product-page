FactoryBot.define do
  factory :evaluation do
    sequence(:question) { |n| "How do I do thing ##{n}?" }
    expected_answer     { "You do it by visiting www.wifi.service.gov.uk..." }
    expected_sources    { ["source/get-started.html.erb"] }
    notes               { "" }
  end
end
