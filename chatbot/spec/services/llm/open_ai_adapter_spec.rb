require "rails_helper"

RSpec.describe Llm::OpenAiAdapter do
  subject(:adapter) { described_class.new(api_key: "test-key") }

  describe "#chat" do
    it "sends a POST to /v1/chat/completions and returns content + usage" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(headers: { "Authorization" => "Bearer test-key" })
        .to_return(
          status:  200,
          body:    {
            choices: [{ message: { role: "assistant", content: "Yes." } }],
            usage:   { prompt_tokens: 10, completion_tokens: 3 }
          }.to_json
        )

      result = adapter.chat(
        messages:    [{ role: "user", content: "Test?" }],
        model:       "gpt-4o-mini",
        temperature: 0.2,
        max_tokens:  100
      )

      expect(result[:content]).to eq("Yes.")
      expect(result[:usage]).to eq(input_tokens: 10, output_tokens: 3)
    end
  end

  describe "#embed" do
    it "posts input as a batch and returns the embedding vectors" do
      stub_request(:post, "https://api.openai.com/v1/embeddings")
        .with(
          headers: { "Authorization" => "Bearer test-key" },
          body:    hash_including("model" => "text-embedding-3-small", "input" => %w[hello world])
        )
        .to_return(
          status:  200,
          body:    {
            data: [
              { embedding: [0.1, 0.2, 0.3] },
              { embedding: [0.4, 0.5, 0.6] }
            ]
          }.to_json
        )

      vectors = adapter.embed(texts: %w[hello world], model: "text-embedding-3-small")

      expect(vectors).to eq([[0.1, 0.2, 0.3], [0.4, 0.5, 0.6]])
    end

    it "batches large inputs into groups of EMBED_BATCH_SIZE" do
      texts = Array.new(150) { |i| "text-#{i}" }

      stub_request(:post, "https://api.openai.com/v1/embeddings")
        .to_return { |req|
          input_size = JSON.parse(req.body).fetch("input").size
          {
            status: 200,
            body:   { data: Array.new(input_size) { { embedding: [0.0] } } }.to_json
          }
        }

      vectors = adapter.embed(texts: texts, model: "text-embedding-3-small")

      expect(vectors.size).to eq(150)
      expect(WebMock).to have_requested(:post, "https://api.openai.com/v1/embeddings").twice
    end
  end
end
