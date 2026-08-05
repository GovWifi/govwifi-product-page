require "rails_helper"

RSpec.describe "Evaluations", type: :request do
  describe "GET /evaluations" do
    it "renders the index with the add-evaluation form" do
      create(:evaluation, question: "How do I sign up?")

      get "/evaluations"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Evaluation Harness")
      expect(response.body).to include("How do I sign up?")
      expect(response.body).to include("Add a new evaluation")
    end
  end

  describe "POST /evaluations" do
    it "creates an evaluation from the form and redirects" do
      expect {
        post "/evaluations", params: {
          evaluation: {
            question:         "How do certificates work?",
            expected_answer:  "Rotate annually.",
            expected_sources: ["source/certificate-rotation.html.md.erb, source/set_up.html.md.erb"],
            notes:            "Priority: high"
          }
        }
      }.to change(Evaluation, :count).by(1)

      follow_redirect!
      expect(response.body).to include("How do certificates work?")

      eval = Evaluation.last
      expect(eval.expected_sources).to eq([
        "source/certificate-rotation.html.md.erb",
        "source/set_up.html.md.erb"
      ])
    end

    it "re-renders the form on validation failure" do
      expect {
        post "/evaluations", params: { evaluation: { question: "" } }
      }.not_to change(Evaluation, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /evaluations/:id/run" do
    it "invokes EvaluationRunJob synchronously and redirects" do
      eval = create(:evaluation)
      allow(EvaluationRunJob).to receive(:perform_now)

      post "/evaluations/#{eval.id}/run"

      expect(EvaluationRunJob).to have_received(:perform_now).with(eval.id)
      expect(response).to redirect_to(evaluations_path)
    end
  end
end
