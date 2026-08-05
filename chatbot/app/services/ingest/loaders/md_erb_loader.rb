require "digest"

module Ingest
  module Loaders
    # Files like source/documentation/set_up.html.md.erb — ERB embedded in
    # Markdown. Strip ERB tags first, then treat as Markdown.
    class MdErbLoader
      def initialize(path)
        @path = path.to_s
      end

      def call
        raw          = File.read(@path)
        markdown     = ErbStripper.strip(raw)
        attrs, body  = FrontMatter.split(markdown)

        LoadedDocument.new(
          title:            attrs["title"] || extract_title(body) || default_title,
          text:             body.strip,
          raw_content_hash: Digest::SHA256.hexdigest(raw)
        )
      end

      private

      def extract_title(body)
        body.each_line do |line|
          return Regexp.last_match(1).strip if line =~ /\A#\s+(.+)/
        end
        nil
      end

      def default_title
        File.basename(@path, ".*").sub(/\.html\.md\z/, "").tr("_-", " ").capitalize
      end
    end
  end
end
