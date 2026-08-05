module Ingest
  module Loaders
    module ErbStripper
      def self.strip(source)
        source
          .gsub(/<%#.*?%>/m, "")   # <%# comment %>
          .gsub(/<%=.*?%>/m, "")   # <%= expression %>
          .gsub(/<%.*?%>/m, "")    # <% ruby %>
      end
    end
  end
end
