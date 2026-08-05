require "rails_helper"

RSpec.describe IndexDocumentJob do
  it "runs the pipeline for the given file attributes" do
    file_args = {
      source_type:   "product-page",
      absolute_path: Rails.root.join("spec/fixtures/sample_docs/get-started.md").to_s,
      relative_path: "get-started.md",
      url:           "https://www.wifi.service.gov.uk/get-started/"
    }

    fake_pipeline = instance_double(Ingest::Pipeline, call: Ingest::Pipeline::Result.new(status: :indexed, document: nil, chunks_added: 3))
    allow(Ingest::Pipeline).to receive(:new).and_return(fake_pipeline)

    described_class.perform_now(**file_args)

    expect(fake_pipeline).to have_received(:call) do |file|
      expect(file.source_type).to eq("product-page")
      expect(file.relative_path).to eq("get-started.md")
    end
  end
end
