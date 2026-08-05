require "rails_helper"

RSpec.describe "POST /api/chat", type: :request do
  before do
    fake_service = instance_double(Answering::AnswerService)
    allow(Answering::AnswerService).to receive(:new).and_return(fake_service)
    allow(fake_service).to receive(:call).and_return(fake_result)
  end

  let(:fake_result) do
    Answering::AnswerService::Result.new(
      answer:     "Visit www.wifi.service.gov.uk to sign up.",
      citations:  [{
        source_type: "product-page",
        path:        "source/get-started.html.erb",
        title:       "Get started",
        url:         "https://www.wifi.service.gov.uk/get-started/",
        heading:     "Get started > Sign up",
        score:       0.87
      }],
      latency_ms: 1234,
      tokens_in:  200,
      tokens_out: 25
    )
  end

  it "returns a JSON body containing answer, citations, latency, and tokens" do
    post "/api/chat", params: { question: "How do I sign up?" }, as: :json

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["answer"]).to include("www.wifi.service.gov.uk")
    expect(body["citations"].first["source_type"]).to eq("product-page")
    expect(body["latency_ms"]).to eq(1234)
    expect(body["tokens"]).to eq("input" => 200, "output" => 25)
  end

  it "returns 400 with a helpful error when the question is missing" do
    post "/api/chat", params: {}, as: :json

    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)["error"]).to eq("missing_parameter")
  end

  it "returns the unknown-answer body when the service returns UNKNOWN_ANSWER" do
    unknown = Answering::AnswerService::Result.new(
      answer:     Answering::PromptBuilder::UNKNOWN_ANSWER,
      citations:  [],
      latency_ms: 40,
      tokens_in:  0,
      tokens_out: 0
    )
    allow(Answering::AnswerService).to receive(:new).and_return(instance_double(Answering::AnswerService, call: unknown))

    post "/api/chat", params: { question: "weather?" }, as: :json

    body = JSON.parse(response.body)
    expect(body["answer"]).to eq(Answering::PromptBuilder::UNKNOWN_ANSWER)
    expect(body["citations"]).to be_empty
  end
end
