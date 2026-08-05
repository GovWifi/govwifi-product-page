FactoryBot.define do
  factory :document do
    source_type { "product-page" }
    sequence(:relative_path) { |n| "source/page-#{n}.html.erb" }
    title { "Sample page" }
    url { "https://www.wifi.service.gov.uk/sample/" }
    sequence(:content_hash) { |n| Digest::SHA256.hexdigest("content-#{n}") }
    indexed_at { Time.current }

    trait :tech_docs do
      source_type { "tech-docs" }
      sequence(:relative_path) { |n| "source/documentation/page-#{n}.md" }
    end

    trait :dev_docs do
      source_type { "dev-docs" }
      sequence(:relative_path) { |n| "source/features/page-#{n}.html.md.erb" }
    end
  end
end
