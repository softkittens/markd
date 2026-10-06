require "spec"
require "../src/markd"

describe Markd::Options do
  describe "#base_url" do
    it "it disabled by default" do
      options = Markd::Options.new
      Markd.to_html("[foo](bar)", options).should eq %(<p><a href="bar">foo</a></p>\n)
      Markd.to_html("![](bar)", options).should eq %(<p><img src="bar" alt="" /></p>\n)
    end

    it "absolutizes relative urls" do
      options = Markd::Options.new
      options.base_url = URI.parse("http://example.com")
      Markd.to_html("[foo](bar)", options).should eq %(<p><a href="http://example.com/bar">foo</a></p>\n)
      Markd.to_html("[foo](https://example.com/baz)", options).should eq %(<p><a href="https://example.com/baz">foo</a></p>\n)
      Markd.to_html("![](bar)", options).should eq %(<p><img src="http://example.com/bar" alt="" /></p>\n)
      Markd.to_html("![](https://example.com/baz)", options).should eq %(<p><img src="https://example.com/baz" alt="" /></p>\n)
    end
  end
end

describe Markd::Options do
  describe "#toc" do
    it "writes no anchor for an empty heading" do
      Markd.to_html("#\n# a", Markd::Options.new(toc: true))
        .should eq(%(<h1></h1>\n<h1><a id="anchor-a" class="anchor" href="#anchor-a"></a>a</h1>\n))
    end
  end
end

describe Markd::Options do
  describe "#heading_ids" do
    it "gives each heading an id from its text as GitHub makes it, and lists them" do
      options = Markd::Options.new(heading_ids: true)
      renderer = Markd::HTMLRenderer.new(options)
      renderer.render(Markd::Parser.parse("# The guide\n## Install *it* & `run`!\n## Again\n## Again\n## Čaj, <b>ćao</b>\n##", options))
        .should eq(<<-HTML)
          <h1 id="the-guide">The guide</h1>
          <h2 id="install-it--run">Install <em>it</em> &amp; <code>run</code>!</h2>
          <h2 id="again">Again</h2>
          <h2 id="again-1">Again</h2>
          <h2 id="čaj-ćao">Čaj, <b>ćao</b></h2>
          <h2 id="heading-1"></h2>\n
          HTML
      renderer.headings.map { |h| {h.level, h.id, h.text} }.should eq([
        {1, "the-guide", "The guide"}, {2, "install-it--run", "Install it & run!"}, {2, "again", "Again"},
        {2, "again-1", "Again"}, {2, "čaj-ćao", "Čaj, ćao"}, {2, "heading-1", ""},
      ])
    end
  end
end
