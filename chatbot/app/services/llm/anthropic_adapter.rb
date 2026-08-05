require "faraday"
require "faraday/retry"

module Llm
  class AnthropicAdapter
    BASE_URL       = "https://api.anthropic.com".freeze
    API_VERSION    = "2023-06-01".freeze
    DEFAULT_MODEL  = "claude-sonnet-4-6".freeze

    ApiError = Class.new(StandardError)

    def initialize(api_key: ENV["ANTHROPIC_API_KEY"], base_url: BASE_URL)
      @api_key  = api_key
      @base_url = base_url
    end

    def default_chat_model
      ENV.fetch("ANTHROPIC_CHAT_MODEL", DEFAULT_MODEL)
    end

    def chat(messages:, model:, temperature:, max_tokens:)
      body = payload(messages, model, temperature, max_tokens)
      response = connection.post("/v1/messages", body.to_json)
      raise ApiError, "Anthropic returned #{response.status}: #{response.body}" unless response.success?

      parsed = JSON.parse(response.body)
      {
        content: parsed.dig("content", 0, "text"),
        usage: {
          input_tokens:  parsed.dig("usage", "input_tokens"),
          output_tokens: parsed.dig("usage", "output_tokens")
        }
      }
    end

    def stream_chat(messages:, model:, temperature:, max_tokens:, &block)
      body    = payload(messages, model, temperature, max_tokens).merge(stream: true)
      content = +""
      usage   = { input_tokens: 0, output_tokens: 0 }

      connection.post("/v1/messages") do |req|
        req.headers["Accept"] = "text/event-stream"
        req.body = body.to_json
        req.options.on_data = ->(chunk, _) { handle_stream_chunk(chunk, content, usage, &block) }
      end

      { content: content, usage: usage }
    end

    def embed(**)
      raise NotImplementedError, "Anthropic has no first-party embedding endpoint (ADR-006). Use OpenAiAdapter."
    end

    private

    def connection
      @connection ||= Faraday.new(url: @base_url) do |f|
        f.request :retry, max: 3, interval: 0.5, backoff_factor: 2,
                  retry_statuses: [429, 500, 502, 503, 504]
        f.headers["x-api-key"]         = @api_key.to_s
        f.headers["anthropic-version"] = API_VERSION
        f.headers["Content-Type"]      = "application/json"
        f.adapter Faraday.default_adapter
      end
    end

    def payload(messages, model, temperature, max_tokens)
      {
        model:       model,
        messages:    chat_messages(messages),
        system:      system_prompt(messages),
        temperature: temperature,
        max_tokens:  max_tokens
      }.compact
    end

    def chat_messages(messages)
      messages.reject { |m| m[:role].to_s == "system" }
              .map    { |m| { role: m[:role].to_s, content: m[:content] } }
    end

    def system_prompt(messages)
      messages.find { |m| m[:role].to_s == "system" }&.dig(:content)
    end

    def handle_stream_chunk(chunk, content, usage)
      chunk.to_s.split("\n\n").each do |event_block|
        event = nil
        data  = nil
        event_block.each_line do |line|
          event = line.sub("event: ", "").strip if line.start_with?("event: ")
          if line.start_with?("data: ")
            raw = line.sub("data: ", "").strip
            data = JSON.parse(raw) rescue nil
          end
        end
        next unless data

        case event
        when "content_block_delta"
          delta = data.dig("delta", "text")
          if delta && !delta.empty?
            content << delta
            yield(delta) if block_given?
          end
        when "message_delta"
          usage[:output_tokens] = data.dig("usage", "output_tokens") if data["usage"]
        when "message_start"
          usage[:input_tokens] = data.dig("message", "usage", "input_tokens") || usage[:input_tokens]
        end
      end
    end
  end
end
