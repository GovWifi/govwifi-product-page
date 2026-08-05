require "rails_helper"

RSpec.describe EvaluationRun, type: :model do
  describe "validations" do
    it "rejects invalid feedback values" do
      expect(build(:evaluation_run, feedback: "meh")).not_to be_valid
    end

    it "accepts up, down, or nil feedback" do
      %w[up down].each { |v| expect(build(:evaluation_run, feedback: v)).to be_valid }
      expect(build(:evaluation_run, feedback: nil)).to be_valid
    end
  end

  describe "#citation_paths" do
    it "extracts the path field from citations regardless of key type" do
      run = build(:evaluation_run, citations: [
        { "path" => "a.md" },
        { path:   "b.md" },
        { "path" => "a.md" }  # dupe
      ])
      expect(run.citation_paths).to eq(%w[a.md b.md])
    end
  end

  describe "#presumed_correct?" do
    let(:eval) { create(:evaluation, expected_sources: ["source/get-started.html.erb"]) }

    it "is false when the human thumbed down" do
      run = build(:evaluation_run, :thumbs_down, evaluation: eval)
      expect(run.presumed_correct?).to be false
    end

    it "is true when the human thumbed up" do
      run = build(:evaluation_run, :thumbs_up, evaluation: eval, citations: [])
      expect(run.presumed_correct?).to be true
    end

    it "is true when unlabelled and at least one expected source was retrieved" do
      run = build(:evaluation_run, evaluation: eval, citations: [
        { "path" => "source/get-started.html.erb" }
      ])
      expect(run.presumed_correct?).to be true
    end

    it "is false when unlabelled and no expected source was retrieved" do
      run = build(:evaluation_run, evaluation: eval, citations: [
        { "path" => "source/other.html.erb" }
      ])
      expect(run.presumed_correct?).to be false
    end

    it "defaults to true when the evaluation lists no expected sources" do
      eval.update!(expected_sources: [])
      run = build(:evaluation_run, evaluation: eval)
      expect(run.presumed_correct?).to be true
    end
  end
end
