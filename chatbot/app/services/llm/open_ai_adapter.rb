require "faraday"
require "faraday/retry"

module Llm
  class OpenAiAdapter
    BASE_URL              = "https://api.openai.com".freeze
    DEFAULT_CHAT_MODEL    = "gpt-4o-mini".freeze
    DEFAULT_EMBED_MODEL   = "text-embedding-3-small".freeze
    EMBED_BATCH_SIZE      = 100

    ApiError = Class.new(StandardError)

    def initialize(api_key: ENV["OPENAI_API_KEY"], base_url: BASE_URL)
      @api_key  = api_key
      @base_url = base_url
    end

    def default_chat_model
      ENV.fetch("OPENAI_CHAT_MODEL", DEFAULT_CHAT_MODEL)
    end

    def default_embed_model
      ENV.fetch("OPENAI_EMBED_MODEL", DEFAULT_EMBED_MODEL)
    end

    def chat(messages:, model:, temperature:, max_tokens:)
      response = connection.post("/v1/chat/completions", {
        model:       model,
        messages:    messages.map { |m| { role: m[:role].to_s, content: m[:content] } },
        temperature: temperature,
        max_tokens:  max_tokens
      }.to_json)

      raise ApiError, "OpenAI returned #{response.status}: #{response.body}" unless response.success?

      body = JSON.parse(response.body)
      {
        content: body.dig("choices", 0, "message", "content"),
        usage: {
          input_tokens:  body.dig("usage", "prompt_tokens"),
          output_tokens: body.dig("usage", "completion_tokens")
        }
      }
    end

    def stream_chat(messages:, model:, temperature:, max_tokens:, &block)
      content = +""
      usage   = { input_tokens: 0, output_tokens: 0 }

      connection.post("/v1/chat/completions") do |req|
        req.headers["Accept"] = "text/event-stream"
        req.body = {
          model:       model,
          messages:    messages.map { |m| { role: m[:role].to_s, content: m[:content] } },
          temperature: temperature,
          max_tokens:  max_tokens,
          stream:      true,
          stream_options: { include_usage: true }
        }.to_json
        req.options.on_data = ->(chunk, _) { handle_stream_chunk(chunk, content, usage, &block) }
      end

      { content: content, usage: usage }
    end

    def embed(texts:, model:)
      Array(texts).each_slice(EMBED_BATCH_SIZE).flat_map do |batch|
        response = connection.post("/v1/embeddings", {
          model: model,
          input: batch
        }.to_json)

        raise ApiError, "OpenAI returned #{response.status}: #{response.body}" unless response.success?

        JSON.parse(response.body).fetch("data").map { |item| item.fetch("embedding") }
      end
    end

    private

    def connection
      @connection ||= Faraday.new(url: @base_url) do |f|
        f.request :retry, max: 3, interval: 0.5, backoff_factor: 2,
                  retry_statuses: [429, 500, 502, 503, 504]
        f.headers["Authorization"] = "Bearer #{@api_key}"
        f.headers["Content-Type"]  = "application/json"
        f.adapter Faraday.default_adapter
      end
    end

    def handle_stream_chunk(chunk, content, usage)
      chunk.to_s.split("\n").each do |line|
        next unless line.start_with?("data: ")
        payload = line.sub("data: ", "").strip
        next if payload.empty? || payload == "[DONE]"

        data = JSON.parse(payload) rescue nil
        next unless data

        delta = data.dig("choices", 0, "delta", "content")
        if delta && !delta.empty?
          content << delta
          yield(delta) if block_given?
        end

        if data["usage"]
          usage[:input_tokens]  = data.dig("usage", "prompt_tokens")     || usage[:input_tokens]
          usage[:output_tokens] = data.dig("usage", "completion_tokens") || usage[:output_tokens]
        end
      end
    end
  end
end
