FactoryBot.define do
  factory :evaluation_run do
    evaluation
    actual_answer  { "Visit the site to sign up." }
    citations      { [{ "source_type" => "product-page", "path" => "source/get-started.html.erb", "url" => "https://www.wifi.service.gov.uk/get-started/" }] }
    latency_ms     { 1234 }
    tokens_in      { 500 }
    tokens_out     { 40 }
    ran_at         { Time.current }
    feedback       { nil }
    feedback_notes { nil }

    trait :thumbs_up   { feedback { "up" } }
    trait :thumbs_down { feedback { "down" } }
  end
end
