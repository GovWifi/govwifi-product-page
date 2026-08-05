module Ingest
  module Loaders
    UnsupportedFileType = Class.new(StandardError)

    def self.for(path)
      case path.to_s
      when /\.html\.md\.erb\z/i then MdErbLoader.new(path)
      when /\.html\.erb\z/i     then HtmlErbLoader.new(path)
      when /\.md\z/i            then MarkdownLoader.new(path)
      when /\.html?\z/i         then HtmlLoader.new(path)
      when /\.pdf\z/i           then PdfLoader.new(path)
      when /\.txt\z/i           then TxtLoader.new(path)
      else raise UnsupportedFileType, "Unsupported file type: #{path}"
      end
    end
  end
end
