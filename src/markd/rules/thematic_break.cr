module Markd::Rule
  struct ThematicBreak
    include Rule

    def match(parser : Parser, container : Node) : MatchValue
      if !parser.indented && thematic_break?(parser)
        parser.close_unmatched_blocks
        parser.add_child(Node::Type::ThematicBreak, parser.next_nonspace)
        parser.advance_offset(parser.line.bytesize - parser.offset, false)
        MatchValue::Leaf
      else
        MatchValue::None
      end
    end

    def continue(parser : Parser, container : Node) : ContinueStatus
      # a thematic break can never container > 1 line, so fail to match:
      ContinueStatus::Stop
    end

    def token(parser : Parser, container : Node) : Nil
      # do nothing
    end

    def can_contain?(type)
      false
    end

    def accepts_lines? : Bool
      false
    end

    # Three or more of one of `*`, `_` and `-`, with spaces and tabs, to the
    # end of the line. Where a scan failed is kept for the line, as cmark
    # keeps it: a scan from an earlier offset fails there again, and each
    # list marker nested on one line would read the rest of it.
    private def thematic_break?(parser : Parser) : Bool
      start = parser.next_nonspace
      return false if parser.thematic_break_kill > start

      char = parser.char_at?(start)
      index = start
      count = 0
      if char.in?('*', '_', '-')
        while (next_char = parser.char_at?(index))
          if next_char == char
            count += 1
          elsif !space_or_tab?(next_char)
            break
          end
          index += 1
        end
        return true if count >= 3 && next_char.nil?
      end

      parser.thematic_break_kill = index
      false
    end
  end
end
