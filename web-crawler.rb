require 'mechanize'


# https://mimibukuro.ddo.jp/img/201710/plala2017-055.jpg
agent = Mechanize.new
page = nil
begin
	page = agent.get('https://mimibukuro.ddo.jp/index.php')
	puts "links"
	puts page.search('//script').length
	exit
	page.search('//script').each do |script|
		puts "script: #{script.text}"
	end	
	exit
	page.links.each do |link|
		puts "Text: #{link.text}"
		puts "Href: #{link.href}"
	end
rescue Timeout::Error
	puts "timeout"
	retry
end

if page
	page.images.each do |img|
		puts "saving"
		puts img.src
		puts agent.resolve(img.src)
		begin
			download_img = page.uri.merge(img.src).to_s 
			agent.get(download_img).save "./temp/#{File.basename(img.src)}"
		rescue Mechanize::ResponseCodeError => e
			case e.response_code
				when "404"
				puts "got timeout"
				next
			end
		end
	end
end
