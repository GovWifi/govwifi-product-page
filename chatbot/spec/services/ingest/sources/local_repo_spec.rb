require "rails_helper"

RSpec.describe Ingest::Sources::LocalRepo do
  around do |example|
    Dir.mktmpdir do |root|
      @root = Pathname(root)
      example.run
    end
  end

  def touch(relative, content = "x")
    path = @root.join(relative)
    FileUtils.mkdir_p(path.dirname)
    File.write(path, content)
  end

  def repo(**overrides)
    described_class.new(
      source_type:   "product-page",
      root:          @root.to_s,
      url_prefix:    "https://www.wifi.service.gov.uk",
      skip_patterns: overrides.fetch(:skip_patterns, [])
    )
  end

  describe "#each" do
    it "enumerates supported files, skipping directories" do
      touch("get-started.md")
      touch("connect.html.erb")
      touch("images/logo.png")  # unsupported extension

      files = repo.each.to_a
      expect(files.map(&:relative_path)).to contain_exactly("get-started.md", "connect.html.erb")
    end

    it "applies skip_patterns" do
      touch("get-started.md")
      touch("shared/_nav.html.erb")

      files = repo(skip_patterns: ["**/shared/**"]).each.to_a
      expect(files.map(&:relative_path)).to eq(["get-started.md"])
    end

    it "builds URLs by stripping known extensions and adding a trailing slash" do
      touch("source/get-started.html.erb")

      # Note: with the actual product-page config, root points at source/,
      # so the file's relative_path here starts without source/ prefix.
      # The url_for logic handles both cases.
      repo_at_source = described_class.new(
        source_type: "product-page",
        root: @root.join("source").to_s,
        url_prefix: "https://www.wifi.service.gov.uk"
      )
      file = repo_at_source.each.to_a.first
      expect(file.url).to eq("https://www.wifi.service.gov.uk/get-started/")
    end
  end

  describe ".from_config" do
    it "builds repos from config/ai_sources.yml sources array" do
      config_path = @root.join("ai_sources.yml")
      File.write(config_path, <<~YAML)
        sources:
          - source_type: product-page
            root: "../source"
            url_prefix: "https://www.wifi.service.gov.uk"
        skip_patterns:
          - "_*.erb"
      YAML

      repos = described_class.from_config(config_path: config_path)
      expect(repos.size).to eq(1)
      expect(repos.first).to be_a(described_class)
    end
  end
end
