class ActionTextParser
  def self.parse(rich_text)
    elements = []

    rich_text.scan(/\[(.*?)\](.*?)\[\/\1\]/m) do |tag, content|
      case tag
      when /^header level="(h[1-6])"$/
        elements << { type: "header", level: $1, content: content.strip }
      when "paragraph"
        elements << { type: "paragraph", content: content.strip }
      when "bold"
        elements << { type: "bold", content: content.strip }
      when "italic"
        elements << { type: "italic", content: content.strip }
      when /^link href="(.+)"$/
        elements << { type: "link", content: content.strip, href: $1 }
      when /^image src="(.+)"$/
        elements << { type: "image", src: $1.strip }
      when "unordered-list"
        items = content.strip.split("\n").map { |line| line.gsub(/^- /, '').strip }
        elements << { type: "unordered_list", items: items }
      end
    end

    elements
  end
end