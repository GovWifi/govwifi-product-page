require "rails_helper"

RSpec.describe EvaluationRunJob do
  it "records an EvaluationRun with the AnswerService result" do
    evaluation = create(:evaluation, question: "How do I sign up?")

    fake_result = Answering::AnswerService::Result.new(
      answer:     "Visit the site.",
      citations:  [{ source_type: "product-page", path: "source/get-started.html.erb", url: "https://..." }],
      latency_ms: 987,
      tokens_in:  400,
      tokens_out: 25
    )
    allow(Answering::AnswerService).to receive(:new).and_return(
      instance_double(Answering::AnswerService, call: fake_result)
    )

    expect { described_class.perform_now(evaluation.id) }.to change(EvaluationRun, :count).by(1)

    run = evaluation.evaluation_runs.first
    expect(run.actual_answer).to eq("Visit the site.")
    expect(run.citations.first["path"]).to eq("source/get-started.html.erb")
    expect(run.latency_ms).to eq(987)
    expect(run.tokens_in).to eq(400)
  end
end
