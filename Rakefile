require 'yaml'
require 'corundum'
require 'corundum/tasklibs'

module Corundum
  tk = Toolkit.new do |tk|
  end

  tk.in_namespace do
    sanity = GemspecSanity.new(tk)
    rspec = RSpec.new(tk)
    cov = SimpleCov.new(tk, rspec) do |cov|
      cov.threshold = 90
    end
    gem = GemBuilding.new(tk)
    cutter = GemCutter.new(tk,gem)
    email = Email.new(tk)
    vc = Git.new(tk) do |vc|
      vc.branch = "master"
    end
    task tk.finished_files.build => vc["is_checked_in"]
    yd = YARDoc.new(tk) do |yd|
      yd.options = %w[--exclude lib/insight/views --exclude lib/insight/public]
    end
    all_docs = DocumentationAssembly.new(tk, yd, rspec, cov) do |da|
      da.external_docs["The Wiki"] = "https://github.com/LRDesign/logical-insight/wiki"
    end
    pages = GithubPages.new(all_docs)
  end
end
