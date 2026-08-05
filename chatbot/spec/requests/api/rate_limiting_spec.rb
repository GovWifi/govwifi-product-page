require "rails_helper"

RSpec.describe "rate limiting on /api/chat", type: :request do
  around do |example|
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
    ClimateControl_stub(CHAT_RATE_LIMIT: "3", CHAT_RATE_PERIOD: "60") do
      example.run
    end
    Rack::Attack.cache.store = original_store
  end

  # Local shim so we don't need the ClimateControl gem. Reloads the
  # rack-attack initializer under the given ENV to pick up the throttle
  # limit for this example.
  def ClimateControl_stub(env)
    originals = env.transform_values { |_| nil }
    env.each { |k, v| originals[k] = ENV[k.to_s]; ENV[k.to_s] = v }
    load Rails.root.join("config/initializers/rack_attack.rb")
    yield
  ensure
    env.each_key { |k| ENV[k.to_s] = originals[k] }
    load Rails.root.join("config/initializers/rack_attack.rb")
  end

  before do
    fake_result = Answering::AnswerService::Result.new(
      answer: "ok", citations: [], latency_ms: 1, tokens_in: 0, tokens_out: 0
    )
    allow(Answering::AnswerService).to receive(:new).and_return(
      instance_double(Answering::AnswerService, call: fake_result)
    )
  end

  it "returns 429 with JSON body once the per-IP limit is exceeded" do
    4.times do |i|
      post "/api/chat", params: { question: "q?" }, as: :json, env: { "REMOTE_ADDR" => "1.2.3.4" }
      if i < 3
        expect(response).to have_http_status(:ok), "request #{i} was throttled early"
      else
        expect(response).to have_http_status(:too_many_requests)
        expect(JSON.parse(response.body)["error"]).to eq("rate_limited")
        expect(response.headers["Retry-After"]).to be_present
      end
    end
  end
end
