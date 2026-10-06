require "spec"
require "../src/markd"

private def safe(source)
  Markd.to_html(source, Markd::Options.new(safe: true))
end

describe "safe: true" do
  it "keeps the alt text of an image whose destination it drops inside the attribute" do
    safe("![a onerror=alert(1)](javascript:x)").should eq(%(<p><img src="" alt="a onerror=alert(1)" /></p>\n))
    safe(%(![a" onerror="alert(1)](javascript:x "t")))
      .should eq(%(<p><img src="" alt="a&quot; onerror=&quot;alert(1)" title="t" /></p>\n))
  end

  it "writes raw HTML inside alt text as text" do
    safe("![<b>a</b>](/i.png)").should eq(%(<p><img src="/i.png" alt="&lt;b&gt;a&lt;/b&gt;" /></p>\n))
  end
end

describe "safe: true destinations" do
  it "drops a javascript:, vbscript:, file: or non-image data: destination, and keeps one that only contains them" do
    safe("[a](JavaScript:x) [b](vbscript:x) [c](file:///x) [d](data:text/html,x) [e](data:image/png;base64,x)")
      .should eq(%(<p><a>a</a> <a>b</a> <a>c</a> <a>d</a> <a href="data:image/png;base64,x">e</a></p>\n))
    safe("[a](https://x.test/?to=vbscript:x) [b](/data:x)")
      .should eq(%(<p><a href="https://x.test/?to=vbscript:x">a</a> <a href="/data:x">b</a></p>\n))
  end
end

describe "Markd.to_html" do
  it "reads a byte that is not UTF-8 as U+FFFD" do
    Markd.to_html("a\xFFb *c*").should eq("<p>a�b <em>c</em></p>\n")
  end
end
