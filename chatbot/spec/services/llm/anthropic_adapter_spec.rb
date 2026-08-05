require "rails_helper"

RSpec.describe Llm::AnthropicAdapter do
  subject(:adapter) { described_class.new(api_key: "test-key") }

  describe "#chat" do
    it "sends a POST to /v1/messages and returns content + usage" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .with(
          headers: {
            "x-api-key"         => "test-key",
            "anthropic-version" => "2023-06-01"
          }
        )
        .to_return(
          status:  200,
          body:    {
            content: [{ text: "GovWifi is a free Wi-Fi service." }],
            usage:   { input_tokens: 42, output_tokens: 8 }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = adapter.chat(
        messages:    [{ role: "user", content: "What is GovWifi?" }],
        model:       "claude-sonnet-4-6",
        temperature: 0.2,
        max_tokens:  256
      )

      expect(result[:content]).to eq("GovWifi is a free Wi-Fi service.")
      expect(result[:usage]).to eq(input_tokens: 42, output_tokens: 8)
    end

    it "extracts the system prompt from the messages and passes it as a top-level field" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .with { |req|
          body = JSON.parse(req.body)
          body["system"] == "You are a helpful assistant." &&
            body["messages"] == [{ "role" => "user", "content" => "hi" }]
        }
        .to_return(status: 200, body: { content: [{ text: "hi" }], usage: {} }.to_json)

      adapter.chat(
        messages: [
          { role: "system", content: "You are a helpful assistant." },
          { role: "user",   content: "hi" }
        ],
        model: "claude-sonnet-4-6", temperature: 0.2, max_tokens: 128
      )
    end

    it "raises ApiError on non-2xx responses" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 400, body: "bad request")

      expect {
        adapter.chat(
          messages: [{ role: "user", content: "x" }],
          model: "claude-sonnet-4-6", temperature: 0.2, max_tokens: 64
        )
      }.to raise_error(Llm::AnthropicAdapter::ApiError, /400/)
    end
  end

  describe "#embed" do
    it "raises NotImplementedError (Anthropic has no first-party embedding endpoint)" do
      expect { adapter.embed(texts: ["x"], model: "n/a") }
        .to raise_error(NotImplementedError, /ADR-006/)
    end
  end
end
