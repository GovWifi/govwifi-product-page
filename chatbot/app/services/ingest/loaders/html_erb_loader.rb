require "digest"

module Ingest
  module Loaders
    # Files like source/get-started.html.erb — ERB embedded in HTML.
    # We strip ERB tags first, then treat the residue as HTML.
    class HtmlErbLoader
      def initialize(path)
        @path = path.to_s
      end

      def call
        raw     = File.read(@path)
        html    = ErbStripper.strip(raw)
        text, title = HtmlLoader.extract_from(html)

        LoadedDocument.new(
          title:            title || default_title,
          text:             text,
          raw_content_hash: Digest::SHA256.hexdigest(raw)
        )
      end

      private

      def default_title
        File.basename(@path, ".*").sub(/\.html\z/, "").tr("_-", " ").capitalize
      end
    end
  end
end
