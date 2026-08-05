require "rails_helper"

RSpec.describe Answering::AnswerService do
  let(:llm_client) { class_double(Llm::Client) }
  let(:retriever)  { instance_double(Retrieval::Retriever) }

  subject(:service) { described_class.new(llm_client: llm_client, retriever: retriever) }

  def build_result(source_type: "product-page", path: "source/get-started.html.erb")
    doc = build(:document, source_type: source_type, relative_path: path)
    chunk = build(:chunk, document: doc, content: "Sign up steps.")
    Retrieval::Retriever::Result.new(chunk: chunk, similarity: 0.9, score: 0.9 * 1.15)
  end

  before do
    allow(llm_client).to receive(:embed).and_return([[0.0] * 1536])
  end

  describe "#call (non-streaming)" do
    it "returns the unknown-answer response and does not call the LLM when retrieval is empty" do
      allow(retriever).to receive(:call).and_return([])
      expect(llm_client).not_to receive(:chat)

      result = service.call(question: "What time is it?")

      expect(result.answer).to eq(Answering::PromptBuilder::UNKNOWN_ANSWER)
      expect(result.citations).to be_empty
      expect(result.tokens_in).to eq(0)
    end

    it "calls the LLM with a prompt built from retrieved chunks and returns citations + tokens" do
      allow(retriever).to receive(:call).and_return([build_result])
      allow(llm_client).to receive(:chat).and_return(
        content: "Visit www.wifi.service.gov.uk and follow the steps.",
        usage:   { input_tokens: 1200, output_tokens: 30 }
      )

      result = service.call(question: "How do I sign up?")

      expect(result.answer).to include("wifi.service.gov.uk")
      expect(result.citations.first[:source_type]).to eq("product-page")
      expect(result.tokens_in).to eq(1200)
      expect(result.tokens_out).to eq(30)
    end

    it "dedupes citations by (source_type, path)" do
      doc = build(:document, source_type: "product-page", relative_path: "source/x.html.erb")
      chunk_a = build(:chunk, document: doc, position: 0, content: "A")
      chunk_b = build(:chunk, document: doc, position: 1, content: "B")
      results = [
        Retrieval::Retriever::Result.new(chunk: chunk_a, similarity: 0.9, score: 0.9),
        Retrieval::Retriever::Result.new(chunk: chunk_b, similarity: 0.8, score: 0.8)
      ]
      allow(retriever).to receive(:call).and_return(results)
      allow(llm_client).to receive(:chat).and_return(content: "ok", usage: { input_tokens: 1, output_tokens: 1 })

      result = service.call(question: "Q?")

      expect(result.citations.size).to eq(1)
    end
  end

  describe "#stream" do
    it "yields Token / Citations / Done in that order on the happy path" do
      allow(retriever).to receive(:call).and_return([build_result])
      allow(llm_client).to receive(:stream_chat) do |messages:, &block|
        block.call("Sign ")
        block.call("up now.")
        { content: "Sign up now.", usage: { input_tokens: 100, output_tokens: 3 } }
      end

      events = []
      service.stream(question: "How?") { |e| events << e }

      types = events.map { |e| e.class.name.split("::").last }
      expect(types).to eq(%w[Token Token Citations Done])
      expect(events[0].delta).to eq("Sign ")
      expect(events[2].list.first[:source_type]).to eq("product-page")
      expect(events[3].tokens_out).to eq(3)
    end

    it "yields the unknown-answer token, empty citations, and done when retrieval is empty" do
      allow(retriever).to receive(:call).and_return([])
      expect(llm_client).not_to receive(:stream_chat)

      events = []
      service.stream(question: "Out-of-scope question?") { |e| events << e }

      expect(events.first.delta).to eq(Answering::PromptBuilder::UNKNOWN_ANSWER)
      expect(events[1].list).to be_empty
      expect(events.last).to be_a(Answering::AnswerService::Events::Done)
    end
  end
end
