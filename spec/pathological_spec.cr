require "spec"
require "../src/markd"

# Text whose time grew faster than its length: cmark's pathological inputs,
# and what a fuzzer found. Each renders four times the text in less than
# eight times the time; time growing with the square of the length takes
# sixteen.
PATHOLOGICAL = {
  "nested strong emphasis"              => ->(n : Int32) { "*a **a " * n + "b" + " a** a*" * n },
  "emphasis closers without openers"    => ->(n : Int32) { "a_ " * n },
  "emphasis openers without closers"    => ->(n : Int32) { "_a " * n },
  "openers and closers multiple of 3"   => ->(n : Int32) { "a**b" + "c* " * n },
  "mismatched openers and closers"      => ->(n : Int32) { "*a_ " * n },
  "link openers and emphasis closers"   => ->(n : Int32) { "[ a_" * n },
  "link closers without openers"        => ->(n : Int32) { "a]" * n },
  "link openers without closers"        => ->(n : Int32) { "[a" * n },
  "[ (]( repeated"                      => ->(n : Int32) { "[ (](" * n },
  "![[]() repeated"                     => ->(n : Int32) { "![[]()" * n },
  "nested brackets"                     => ->(n : Int32) { "[" * n + "a" + "]" * n },
  "unclosed links"                      => ->(n : Int32) { "[a](b" * n },
  "unclosed link destinations"          => ->(n : Int32) { "[a](<b" * n },
  "unclosed code spans"                 => ->(n : Int32) { "\\``:" * n },
  "unended entities"                    => ->(n : Int32) { "&a" * n },
  "runs of <"                           => ->(n : Int32) { "<" * n },
  "unclosed comments"                   => ->(n : Int32) { "</" + "<!--" * n },
  "unclosed processing instructions"    => ->(n : Int32) { "<?" * n },
  "unclosed CDATA sections"             => ->(n : Int32) { "<![CDATA[" * n },
  "titles of escapes"                   => ->(n : Int32) { "[a](x \"" + "\\\\!" * n },
  "list markers nested on one line"     => ->(n : Int32) { "- " * n + "a" },
  "block quotes nested on one line"     => ->(n : Int32) { "> " * n + "a" },
  "deeply indented lines"               => ->(n : Int32) { ("  " * (n // 8) + "* a\n") * 8 },
  "lines of one paragraph"              => ->(n : Int32) { "ab\n" * n },
  "reference definitions"               => ->(n : Int32) { "[a]: b\n" * n + "===\n" },
  "a delimiter row that is not one"     => ->(n : Int32) { "|a|b|\n|" + "- " * n + "x\n" },
  "two runs of underscores"             => ->(n : Int32) { "_" * n + "*" + "_" * n },
  "smart quotes"                        => ->(n : Int32) { "\"'" * n },
  "strikethrough of mismatched lengths" => ->(n : Int32) { "[)~~~" * n },
  "hosts of many segments"              => ->(n : Int32) { "http://" + "a." * n + "ab" },
  "blank lines in an HTML block"        => ->(n : Int32) { "<!--\n" + "\n" * n },
}

describe "Markd.to_html" do
  options = Markd::Options.new(gfm: true, autolink: true, smart: true, tagfilter: true)
  PATHOLOGICAL.each do |name, text|
    it "renders #{name} in time growing with its length" do
      small, large = text.call(2_000), text.call(8_000)
      Markd.to_html(small, options)
      small_time = Time.measure { Markd.to_html(small, options) }
      large_time = Time.measure { Markd.to_html(large, options) }
      large_time.should be < small_time * 8 + 20.milliseconds
    end
  end
end
