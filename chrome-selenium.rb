require 'selenium-webdriver'
require 'open-uri'

options = Selenium::WebDriver::Chrome::Options.new(args: ['headless'])

driver = Selenium::WebDriver.for(:chrome, options: options)

driver.get('https://mimibukuro.ddo.jp/index.php')

puts driver.title
scripts = driver.find_elements(:xpath, '//script')
scripts.each do |script|
	puts script.attribute('outerHTML')
end
# Syntax = //tagname[@attribute=’Value‘]
# Example = //input[@id=’user-messa
# drvier.find_elements(tag_name: 'img')
driver.find_elements(:xpath, '//img').each do |img|
	src =  img.attribute('src')
	puts src
	# File.open("./temp/#{File.basename(src)}", 'wb') do |fp|
	#	fp.write open(src).read
	# end
end
driver.quit

