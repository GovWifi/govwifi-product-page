module Llm
  # Facade over chat and embedding providers. See docs/decisions.md ADR-002/006.
  #
  # Usage:
  #   Llm::Client.chat(messages: [{ role: "user", content: "Hello" }])
  #   Llm::Client.embed(texts: ["some text", "more text"])
  #
  # For tests, inject a fake:
  #   Llm::Client.instance = FakeClient.new
  #   # ... after test:
  #   Llm::Client.reset!
  class Client
    UnknownProviderError = Class.new(StandardError)

    class << self
      attr_writer :instance

      def instance
        @instance ||= build_default
      end

      def reset!
        @instance = nil
      end

      def chat(**)       = instance.chat(**)
      def stream_chat(**, &) = instance.stream_chat(**, &)
      def embed(**)      = instance.embed(**)

      private

      def build_default
        new(
          chat_adapter:  adapter_for(chat_provider),
          embed_adapter: adapter_for(embed_provider)
        )
      end

      def chat_provider
        ENV.fetch("LLM_CHAT_PROVIDER", "anthropic").to_sym
      end

      def embed_provider
        ENV.fetch("LLM_EMBED_PROVIDER", "openai").to_sym
      end

      def adapter_for(provider)
        case provider
        when :anthropic then AnthropicAdapter.new
        when :openai    then OpenAiAdapter.new
        else raise UnknownProviderError, "Unknown LLM provider: #{provider}"
        end
      end
    end

    def initialize(chat_adapter:, embed_adapter:)
      @chat_adapter  = chat_adapter
      @embed_adapter = embed_adapter
    end

    def chat(messages:, model: nil, temperature: 0.2, max_tokens: 1024)
      @chat_adapter.chat(
        messages:    messages,
        model:       model || @chat_adapter.default_chat_model,
        temperature: temperature,
        max_tokens:  max_tokens
      )
    end

    def stream_chat(messages:, model: nil, temperature: 0.2, max_tokens: 1024, &block)
      @chat_adapter.stream_chat(
        messages:    messages,
        model:       model || @chat_adapter.default_chat_model,
        temperature: temperature,
        max_tokens:  max_tokens,
        &block
      )
    end

    def embed(texts:, model: nil)
      @embed_adapter.embed(
        texts: Array(texts),
        model: model || @embed_adapter.default_embed_model
      )
    end
  end
end
