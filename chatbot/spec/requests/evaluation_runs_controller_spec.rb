require "rails_helper"

RSpec.describe "EvaluationRuns feedback", type: :request do
  let(:run) { create(:evaluation_run) }

  it "sets feedback to 'up' on first click" do
    patch "/evaluation_runs/#{run.id}/feedback", params: { feedback: "up" }

    expect(response).to redirect_to(evaluations_path)
    expect(run.reload.feedback).to eq("up")
  end

  it "toggles off when the currently-active value is re-clicked" do
    run.update!(feedback: "up")
    patch "/evaluation_runs/#{run.id}/feedback", params: { feedback: "up" }

    expect(run.reload.feedback).to be_nil
  end

  it "flips from up to down without needing to clear first" do
    run.update!(feedback: "up")
    patch "/evaluation_runs/#{run.id}/feedback", params: { feedback: "down" }

    expect(run.reload.feedback).to eq("down")
  end

  it "accepts optional feedback_notes" do
    patch "/evaluation_runs/#{run.id}/feedback", params: { feedback: "down", feedback_notes: "cited wrong doc" }
    expect(run.reload.feedback_notes).to eq("cited wrong doc")
  end
end
