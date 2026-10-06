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
