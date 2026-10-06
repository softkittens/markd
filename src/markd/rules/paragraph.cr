module Markd::Rule
  struct Paragraph
    include Rule

    def match(parser : Parser, container : Node) : MatchValue
      MatchValue::None
    end

    def continue(parser : Parser, container : Node) : ContinueStatus
      parser.blank ? ContinueStatus::Stop : ContinueStatus::Continue
    end

    def token(parser : Parser, container : Node) : Nil
      at = Rule.references(parser, container)
      container.unlink if at > 0 && container.text.each_char.all? &.ascii_whitespace?
    end

    def can_contain?(type)
      false
    end

    def accepts_lines? : Bool
      true
    end
  end
end
