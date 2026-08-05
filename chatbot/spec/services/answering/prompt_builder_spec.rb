require "rails_helper"

RSpec.describe Answering::PromptBuilder do
  subject(:builder) { described_class.new }

  let(:doc) { build(:document, source_type: "product-page", relative_path: "source/get-started.html.erb") }
  let(:chunk) { build(:chunk, document: doc, content: "Steps to sign up.") }
  let(:result) { Retrieval::Retriever::Result.new(chunk: chunk, similarity: 0.9, score: 0.9 * 1.15) }

  it "returns a system prompt followed by history and a final user message" do
    messages = builder.call(question: "How do I sign up?", retrieval_results: [result])
    expect(messages.first[:role]).to eq("system")
    expect(messages.last[:role]).to eq("user")
    expect(messages.last[:content]).to include("Question: How do I sign up?")
  end

  it "wraps each retrieved chunk in a <context> block labelled with source path" do
    messages = builder.call(question: "Q?", retrieval_results: [result])

    user_content = messages.last[:content]
    expect(user_content).to include('<context source="source/get-started.html.erb"')
    expect(user_content).to include("Steps to sign up.")
    expect(user_content).to include("</context>")
  end

  it "trims history to the last 10 turns and drops non-user/assistant roles" do
    long_history = (1..20).flat_map { |i| [{ role: "user", content: "u#{i}" }, { role: "assistant", content: "a#{i}" }] }
    long_history << { role: "system", content: "should be dropped" }

    messages = builder.call(question: "Q?", retrieval_results: [result], history: long_history)

    turns = messages.select { |m| %w[user assistant].include?(m[:role]) && !m[:content].include?("<context") }
    expect(turns.size).to be <= 10
    expect(messages.none? { |m| m[:content] == "should be dropped" }).to be true
  end

  it "instructs the model to decline with the exact unknown-answer phrase" do
    messages = builder.call(question: "Q?", retrieval_results: [result])
    expect(messages.first[:content]).to include(Answering::PromptBuilder::UNKNOWN_ANSWER)
  end
end
