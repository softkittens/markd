module Markd::Rule
  struct HTMLBlock
    include Rule

    def match(parser : Parser, container : Node) : MatchValue
      if !parser.indented && parser.char_at?(parser.next_nonspace) == '<'
        block_type_size = Rule::HTML_BLOCK_OPEN.size - 1

        Rule::HTML_BLOCK_OPEN.each_with_index do |regex, index|
          if parser.match_at(regex) &&
             (index < block_type_size || !container.type.paragraph?)
            parser.close_unmatched_blocks
            # We don't adjust parser.offset;
            # spaces are part of the HTML block:
            node = parser.add_child(Node::Type::HTMLBlock, parser.offset)
            node.data["html_block_type"] = index

            return MatchValue::Leaf
          end
        end
      end

      MatchValue::None
    end

    def continue(parser : Parser, container : Node) : ContinueStatus
      (parser.blank && {5, 6}.includes?(container.data["html_block_type"])) ? ContinueStatus::Stop : ContinueStatus::Continue
    end

    def token(parser : Parser, container : Node) : Nil
      text = container.text.gsub(/(\n *)+$/, "")

      if parser.tagfilter?
        text = self.class.escape_disallowed_html(text)
      end

      container.text = text
    end

    def can_contain?(type)
      false
    end

    def accepts_lines? : Bool
      true
    end

    DISALLOWED_HTML_TAG = /<(?=\/?\s*(?:#{GFM_DISALLOWED_HTML_TAGS.join('|')})\b)/i

    # `text` with the `<` of each tag GFM's tagfilter disallows as `&lt;`.
    def self.escape_disallowed_html(text : String) : String
      text.gsub(DISALLOWED_HTML_TAG, "&lt;")
    end
  end
end
