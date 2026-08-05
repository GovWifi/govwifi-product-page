require "rails_helper"

RSpec.describe Chunk, type: :model do
  describe "validations" do
    subject { build(:chunk) }

    it { is_expected.to be_valid }

    it "requires content" do
      subject.content = nil
      expect(subject).not_to be_valid
    end

    it "requires position unique per document" do
      chunk = create(:chunk, position: 3)
      dup = build(:chunk, document: chunk.document, position: 3)
      expect(dup).not_to be_valid
    end
  end

  describe "#citation" do
    it "returns source_type, path, title, url, and heading" do
      doc = create(:document, source_type: "product-page",
                              relative_path: "source/get-started.html.erb",
                              title: "Get started",
                              url: "https://www.wifi.service.gov.uk/get-started/")
      chunk = create(:chunk, document: doc, heading_chain: "Get started > Sign up")

      expect(chunk.citation).to eq(
        source_type: "product-page",
        path:        "source/get-started.html.erb",
        title:       "Get started",
        url:         "https://www.wifi.service.gov.uk/get-started/",
        heading:     "Get started > Sign up"
      )
    end
  end
end
