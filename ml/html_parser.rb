require 'nokogiri'
require 'open-uri'

doc = Nokogiri::HTML(open("https://github.com/prawnpdf/prawn"))

doc.children.each do |c|
	puts c.document.text
	c.document.text.split('\n').each do |l|
		puts l.strip if l.match?(/a-z|A-Z/)
	end
end
