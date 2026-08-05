require "rails_helper"

RSpec.describe Evaluation, type: :model do
  describe "validations" do
    it "requires a question" do
      expect(build(:evaluation, question: nil)).not_to be_valid
    end
  end

  describe "#latest_run" do
    it "returns the most recent run" do
      eval = create(:evaluation)
      _old = create(:evaluation_run, evaluation: eval, ran_at: 1.day.ago)
      newer = create(:evaluation_run, evaluation: eval, ran_at: 1.hour.ago)

      expect(eval.latest_run).to eq(newer)
    end
  end

  describe "#summary_status" do
    it "is :not_run when no runs exist" do
      expect(create(:evaluation).summary_status).to eq(:not_run)
    end

    it "reflects the feedback on the latest run" do
      eval = create(:evaluation)
      create(:evaluation_run, :thumbs_up, evaluation: eval)
      expect(eval.summary_status).to eq(:up)
    end

    it "is :awaiting_rating when there is a run but no feedback" do
      eval = create(:evaluation)
      create(:evaluation_run, evaluation: eval, feedback: nil)
      expect(eval.summary_status).to eq(:awaiting_rating)
    end
  end
end
