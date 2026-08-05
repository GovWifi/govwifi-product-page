require "rails_helper"

RSpec.describe Document, type: :model do
  describe "validations" do
    subject { build(:document) }

    it { is_expected.to be_valid }

    it "requires source_type from the allowed list" do
      subject.source_type = "wikipedia"
      expect(subject).not_to be_valid
      expect(subject.errors[:source_type]).to be_present
    end

    it "requires relative_path unique per source_type" do
      create(:document, source_type: "product-page", relative_path: "source/x.html.erb")
      dup = build(:document, source_type: "product-page", relative_path: "source/x.html.erb")
      expect(dup).not_to be_valid
    end

    it "allows the same relative_path across source_types" do
      create(:document, source_type: "product-page", relative_path: "source/x.html.erb")
      other = build(:document, :tech_docs, relative_path: "source/x.html.erb")
      expect(other).to be_valid
    end
  end

  describe "#source_priority" do
    it "boosts product-page over tech-docs, tech-docs over dev-docs, and demotes zendesk" do
      pp = build(:document, source_type: "product-page")
      td = build(:document, source_type: "tech-docs")
      dd = build(:document, source_type: "dev-docs")
      zd = build(:document, source_type: "zendesk")

      expect(pp.source_priority).to be > td.source_priority
      expect(td.source_priority).to be > dd.source_priority
      expect(dd.source_priority).to be > zd.source_priority
    end
  end

  describe "chunks association" do
    it "destroys dependent chunks" do
      doc = create(:document)
      create(:chunk, document: doc)
      expect { doc.destroy }.to change(Chunk, :count).by(-1)
    end
  end
end
