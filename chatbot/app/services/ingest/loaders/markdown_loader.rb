require "digest"

module Ingest
  module Loaders
    class MarkdownLoader
      def initialize(path)
        @path = path.to_s
      end

      def call
        raw = File.read(@path)
        attrs, body = FrontMatter.split(raw)

        LoadedDocument.new(
          title:            attrs["title"] || extract_title(body) || default_title,
          text:             body.strip,
          raw_content_hash: Digest::SHA256.hexdigest(raw)
        )
      end

      private

      def extract_title(body)
        body.each_line do |line|
          if line =~ /\A#\s+(.+)/
            return Regexp.last_match(1).strip
          end
        end
        nil
      end

      def default_title
        File.basename(@path, ".*").tr("_-", " ").capitalize
      end
    end
  end
end
