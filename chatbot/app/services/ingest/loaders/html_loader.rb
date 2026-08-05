require "digest"
require "nokogiri"

module Ingest
  module Loaders
    class HtmlLoader
      REMOVE_SELECTORS = %w[script style nav footer aside .govuk-cookie-banner].freeze

      def initialize(path)
        @path = path.to_s
      end

      def call
        raw = File.read(@path)
        text, title = extract(raw)

        LoadedDocument.new(
          title:            title || default_title,
          text:             text,
          raw_content_hash: Digest::SHA256.hexdigest(raw)
        )
      end

      def self.extract_from(html)
        new(nil).__send__(:extract, html)
      end

      private

      def extract(html)
        doc = Nokogiri::HTML(html)
        doc.search(*REMOVE_SELECTORS).each(&:unlink)

        title = doc.at_css("title")&.text&.strip
        title ||= doc.at_css("h1")&.text&.strip

        body = doc.at_css("main") || doc.at_css("#content") || doc.at_css("article") || doc.at_css("body") || doc
        text = body.text.gsub(/[ \t]+/, " ").gsub(/\n{3,}/, "\n\n").strip

        [text, title]
      end

      def default_title
        return "Untitled" if @path.nil?
        File.basename(@path, ".*").tr("_-", " ").capitalize
      end
    end
  end
end
