module Rack::Insight
  module PathMatchFilters

    def match_path_filters?(path_filters, path)
      to_regex(path_filters).find { |filter| path =~ filter }
    end

    def to_regex(filters)
      (filters || []).map { |str| %r(^#{str}) }
    end

  end
end
