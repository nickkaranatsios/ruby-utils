require "fileutils"

def make_dir path
  FileUtils.mkdir_p path unless File.exists? path
end

scan_dir = ARGV[ 0 ] || "."
output_dir = ARGV[ 1 ] || "."
Dir.glob( "#{ scan_dir }/**/*" ).each do | d |
  movie_file = File.expand_path( d )
  next if movie_file == "." || movie_file == ".."
  next unless movie_file.to_s.upcase.include? ".MOV"
#  FileUtils.cp movie_file, "Movies"
puts "movie file #{ movie_file }"
  quoted = d.gsub( / /, '\ ' )
  encoded_date = `mediainfo #{ quoted } | grep -i 'encoded date' | head -1`
  match = encoded_date[/\d{4}-\d{2}/]
  year, month = match.split( "-" )
  puts "year_month = #{ year } - #{ month }"
  movie_dir_year = output_dir + "/" + "#{ year }"
  make_dir movie_dir_year
  movie_dir_month = output_dir + "/" + "#{ year }" + "/" + "#{ month }"
  make_dir movie_dir_month
  dst_file = movie_dir_month + "/" + File.basename( movie_file )
  if !File.exists? dst_file
    FileUtils.cp movie_file, movie_dir_month
    puts "copying #{ movie_file } to #{ movie_dir_month }" 
  else 
    puts "WARNING #{ movie_file } couldn't copied to #{ movie_dir_month }"
  end
end
