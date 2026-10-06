module Markd::Rule
  struct Heading
    include Rule

    ATX_HEADING_MARKER    = /\#{1,6}(?:[ \t]+|$)/
    SETEXT_HEADING_MARKER = /(?:=+|-+)[ \t]*$/

    def match(parser : Parser, container : Node) : MatchValue
      if (match = match?(parser, ATX_HEADING_MARKER))
        # ATX Heading matched
        parser.advance_next_nonspace
        parser.advance_offset(match[0].size, false)
        parser.close_unmatched_blocks

        container = parser.add_child(Node::Type::Heading, parser.next_nonspace)
        container.data["level"] = match[0].strip.size
        container.text = without_closing_sequence(parser.line.byte_slice(parser.offset))

        parser.advance_offset(parser.line.bytesize - parser.offset)

        MatchValue::Leaf
      elsif (match = match?(parser, SETEXT_HEADING_MARKER)) &&
            container.type.paragraph? && (parent = container.parent?) &&
            !parent.type.block_quote?
        # Setext Heading matched
        parser.close_unmatched_blocks

        Rule.references(parser, container)
        return MatchValue::None if container.text.empty?

        heading = Node.new(Node::Type::Heading)
        heading.source_pos = container.source_pos
        heading.data["level"] = match[0][0] == '=' ? 1 : 2
        heading.text = container.text

        container.insert_after(heading)
        container.unlink

        parser.tip = heading
        parser.advance_offset(parser.line.bytesize - parser.offset, false)

        MatchValue::Leaf
      else
        MatchValue::None
      end
    end

    def token(parser : Parser, container : Node) : Nil
      # do nothing
    end

    def continue(parser : Parser, container : Node) : ContinueStatus
      # a heading can never container > 1 line, so fail to match
      ContinueStatus::Stop
    end

    def can_contain?(type)
      false
    end

    def accepts_lines? : Bool
      false
    end

    private def match?(parser : Parser, regex : Regex) : Regex::MatchData?
      parser.match_at(regex) unless parser.indented
    end

    # An ATX heading's text without its closing sequence: `#`s at the end,
    # after a space or a tab or alone, with the spaces and tabs around them.
    private def without_closing_sequence(text : String) : String
      stop = text.bytesize
      while stop > 0 && space_or_tab?(text.byte_at(stop - 1).unsafe_chr)
        stop -= 1
      end
      hashes = stop
      while hashes > 0 && text.byte_at(hashes - 1) == '#'.ord
        hashes -= 1
      end
      if hashes < stop && (hashes == 0 || space_or_tab?(text.byte_at(hashes - 1).unsafe_chr))
        stop = hashes
        while stop > 0 && space_or_tab?(text.byte_at(stop - 1).unsafe_chr)
          stop -= 1
        end
      end
      text.byte_slice(0, stop)
    end
  end
end
