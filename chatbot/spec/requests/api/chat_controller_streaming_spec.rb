require "rails_helper"

RSpec.describe "POST /api/chat (streaming)", type: :request do
  let(:events_yielded) do
    [
      Answering::AnswerService::Events::Token.new(delta: "Sign "),
      Answering::AnswerService::Events::Token.new(delta: "up now."),
      Answering::AnswerService::Events::Citations.new(list: [{
        source_type: "product-page",
        path:        "source/get-started.html.erb",
        title:       "Get started",
        url:         "https://www.wifi.service.gov.uk/get-started/",
        heading:     nil,
        score:       0.9
      }]),
      Answering::AnswerService::Events::Done.new(latency_ms: 1500, tokens_in: 200, tokens_out: 30)
    ]
  end

  before do
    fake_service = instance_double(Answering::AnswerService)
    allow(Answering::AnswerService).to receive(:new).and_return(fake_service)
    allow(fake_service).to receive(:stream) do |&block|
      events_yielded.each { |e| block.call(e) }
    end
  end

  it "returns text/event-stream and emits token/citations/done events in order" do
    post "/api/chat",
         params: { question: "How do I sign up?" }.to_json,
         headers: {
           "Accept"       => "text/event-stream",
           "Content-Type" => "application/json"
         }

    expect(response.media_type).to eq("text/event-stream")

    body = response.body

    # SSE format: "event: <name>\ndata: <json>\n\n"
    event_order = body.scan(/event: (\w+)/).flatten
    expect(event_order).to eq(%w[token token citations done])

    expect(body).to include("delta")
    expect(body).to include("Sign ")
    expect(body).to include("citations")
    expect(body).to include("product-page")
    expect(body).to include("latency_ms")
  end
end
