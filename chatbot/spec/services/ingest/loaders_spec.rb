require "rails_helper"

RSpec.describe Ingest::Loaders do
  describe ".for" do
    it "dispatches .md to MarkdownLoader" do
      expect(described_class.for("x.md")).to be_a(Ingest::Loaders::MarkdownLoader)
    end

    it "dispatches .html.erb to HtmlErbLoader" do
      expect(described_class.for("x.html.erb")).to be_a(Ingest::Loaders::HtmlErbLoader)
    end

    it "dispatches .html.md.erb to MdErbLoader (before .erb / .md match)" do
      expect(described_class.for("x.html.md.erb")).to be_a(Ingest::Loaders::MdErbLoader)
    end

    it "dispatches .html to HtmlLoader" do
      expect(described_class.for("x.html")).to be_a(Ingest::Loaders::HtmlLoader)
    end

    it "dispatches .pdf to PdfLoader" do
      expect(described_class.for("x.pdf")).to be_a(Ingest::Loaders::PdfLoader)
    end

    it "dispatches .txt to TxtLoader" do
      expect(described_class.for("x.txt")).to be_a(Ingest::Loaders::TxtLoader)
    end

    it "raises UnsupportedFileType for unknown extensions" do
      expect { described_class.for("x.docx") }
        .to raise_error(Ingest::Loaders::UnsupportedFileType, /docx/)
    end
  end
end
