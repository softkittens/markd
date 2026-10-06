module Markd::Rule
  struct List
    include Rule

    BULLET_LIST_MARKERS  = {'*', '+', '-'}
    ORDERED_LIST_MARKERS = {'.', ')'}

    def match(parser : Parser, container : Node) : MatchValue
      if !parser.indented || container.type.list?
        data = parse_list_marker(parser, container)
        return MatchValue::None if !data || data.empty?

        parser.close_unmatched_blocks
        if !parser.tip.type.list? || !list_match?(container.data, data)
          list_node = parser.add_child(Node::Type::List, parser.next_nonspace)
          list_node.data = data
        end

        item_node = parser.add_child(Node::Type::Item, parser.next_nonspace)
        item_node.data = data

        MatchValue::Container
      else
        MatchValue::None
      end
    end

    def continue(parser : Parser, container : Node) : ContinueStatus
      ContinueStatus::Continue
    end

    def token(parser : Parser, container : Node) : Nil
      item = container.first_child?
      while item
        if ends_with_blankline?(item) && item.next?
          container.data["tight"] = false
          break
        end

        subitem = item.first_child?
        while subitem
          if ends_with_blankline?(subitem) && (item.next? || subitem.next?)
            container.data["tight"] = false
            break
          end

          subitem = subitem.next?
        end

        item = item.next?
      end
    end

    def can_contain?(type)
      type.item?
    end

    def accepts_lines? : Bool
      false
    end

    private def list_match?(list_data, item_data)
      list_data["type"] == item_data["type"] &&
        list_data["delimiter"] == item_data["delimiter"] &&
        list_data["bullet_char"] == item_data["bullet_char"]
    end

    private def parse_list_marker(parser : Parser, container : Node) : Node::DataType
      empty_data = {} of String => Node::DataValue
      if parser.indent >= 4
        return empty_data
      end

      data = {
        "delimiter"     => 0,
        "marker_offset" => parser.indent,
        "bullet_char"   => "",
        "tight"         => true, # lists are tight by default
        "start"         => 1,
      } of String => Node::DataValue

      start = parser.next_nonspace
      marker = parser.char_at?(start)

      if BULLET_LIST_MARKERS.includes?(marker)
        # A task list item's box, after the marker and spaces.
        box = start + 1
        while parser.char_at?(box).try(&.ascii_whitespace?)
          box += 1
        end
        checked = parser.line.byte_slice?(box, 3).try { |text| {"[ ]" => false, "[x]" => true}[text]? }
        if parser.gfm? && !checked.nil?
          data["type"] = "checkbox"
          data["checked"] = checked
          padding_checkbox = box + 2 - start
        else
          data["type"] = "bullet"
        end
        data["bullet_char"] = marker.to_s

        first_match_size = 1
      else
        pos = 0
        while parser.char_at?(start + pos).try &.ascii_number?
          pos += 1
        end

        number = pos >= 1 ? parser.line.byte_slice(start, pos).to_i? : -1
        if number.nil?
          return empty_data
        end

        if pos >= 1 && pos <= 9 && ORDERED_LIST_MARKERS.includes?(parser.char_at?(start + pos)) &&
           (!container.type.paragraph? || number == 1)
          data["type"] = "ordered"
          data["start"] = number
          data["delimiter"] = parser.char_at?(start + pos).to_s
          first_match_size = pos + 1
        else
          return empty_data
        end
      end

      next_char = parser.char_at?(start + first_match_size)
      unless next_char.nil? || space_or_tab?(next_char)
        return empty_data
      end

      if container.type.paragraph? && blank_from?(parser, start + first_match_size)
        return empty_data
      end

      parser.advance_next_nonspace
      parser.advance_offset(first_match_size, true)

      # Skip past the checkbox brackets ([])
      if parser.gfm? && padding_checkbox
        parser.advance_offset(padding_checkbox, true)
      end

      spaces_start_column = parser.column
      spaces_start_offset = parser.offset

      loop do
        parser.advance_offset(1, true)
        next_char = parser.char_at?(parser.offset)

        break unless parser.column - spaces_start_column < 5 && space_or_tab?(next_char)
      end

      blank_item = parser.char_at?(parser.offset).nil?
      spaces_after_marker = parser.column - spaces_start_column
      if spaces_after_marker >= 5 || spaces_after_marker < 1 || blank_item
        data["padding"] = first_match_size + 1
        parser.column = spaces_start_column
        parser.offset = spaces_start_offset

        parser.advance_offset(1, true) if space_or_tab?(parser.char_at?(parser.offset))
      else
        data["padding"] = first_match_size + spaces_after_marker
      end

      data
    end

    # Whether the line holds only whitespace from byte `index`.
    private def blank_from?(parser : Parser, index : Int32) : Bool
      while (char = parser.char_at?(index))
        return false unless char.ascii_whitespace?
        index += 1
      end
      true
    end

    private def ends_with_blankline?(container : Node) : Bool
      while container
        return true if container.last_line_blank?

        break if container.last_line_checked? || !container.type.in?(Node::Type::List, Node::Type::Item)
        container.last_line_checked = true
        container = container.last_child?
      end

      false
    end
  end
end
