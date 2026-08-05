require "digest"
require "pdf/reader"

module Ingest
  module Loaders
    class PdfLoader
      def initialize(path)
        @path = path.to_s
      end

      def call
        raw = File.binread(@path)
        text = PDF::Reader.new(StringIO.new(raw)).pages.map(&:text).join("\n\n").strip

        LoadedDocument.new(
          title:            extract_title(text) || default_title,
          text:             text,
          raw_content_hash: Digest::SHA256.hexdigest(raw)
        )
      end

      private

      def extract_title(text)
        text.each_line { |line| stripped = line.strip; return stripped unless stripped.empty? }
        nil
      end

      def default_title
        File.basename(@path, ".*").tr("_-", " ").capitalize
      end
    end
  end
end
