require "rails_helper"

RSpec.describe Llm::Client do
  let(:chat_adapter)  { instance_double(Llm::AnthropicAdapter, default_chat_model: "claude-sonnet-4-6") }
  let(:embed_adapter) { instance_double(Llm::OpenAiAdapter,    default_embed_model: "text-embedding-3-small") }
  let(:client)        { described_class.new(chat_adapter: chat_adapter, embed_adapter: embed_adapter) }

  after { described_class.reset! }

  describe "#chat" do
    it "delegates to the chat adapter with the configured model when none is given" do
      allow(chat_adapter).to receive(:chat).and_return(content: "hi", usage: {})

      client.chat(messages: [{ role: "user", content: "hi?" }])

      expect(chat_adapter).to have_received(:chat).with(
        messages:    [{ role: "user", content: "hi?" }],
        model:       "claude-sonnet-4-6",
        temperature: 0.2,
        max_tokens:  1024
      )
    end
  end

  describe "#embed" do
    it "wraps a single string as an array and passes to the embed adapter" do
      allow(embed_adapter).to receive(:embed).and_return([[0.1, 0.2]])

      client.embed(texts: "hello world")

      expect(embed_adapter).to have_received(:embed).with(
        texts: ["hello world"],
        model: "text-embedding-3-small"
      )
    end
  end

  describe ".instance" do
    it "raises UnknownProviderError for an unknown provider" do
      ClimateControl.modify(LLM_CHAT_PROVIDER: "wat") do
        described_class.reset!
        expect { described_class.instance }.to raise_error(Llm::Client::UnknownProviderError)
      end
    rescue NameError
      # ClimateControl not required — inline env fallback
      described_class.reset!
      original = ENV["LLM_CHAT_PROVIDER"]
      begin
        ENV["LLM_CHAT_PROVIDER"] = "wat"
        expect { described_class.instance }.to raise_error(Llm::Client::UnknownProviderError)
      ensure
        ENV["LLM_CHAT_PROVIDER"] = original
      end
    end
  end
end
