require "rails_helper"

RSpec.describe Ingest::Embedder do
  let(:llm_client) { class_double(Llm::Client) }
  subject(:embedder) { described_class.new(llm_client: llm_client) }

  it "returns [] for empty input without calling the LLM" do
    expect(llm_client).not_to receive(:embed)
    expect(embedder.call([])).to eq([])
  end

  it "delegates to LlmClient.embed with the given texts" do
    allow(llm_client).to receive(:embed).and_return([[0.1, 0.2]])

    result = embedder.call(["a chunk"])

    expect(llm_client).to have_received(:embed).with(texts: ["a chunk"])
    expect(result).to eq([[0.1, 0.2]])
  end
end
