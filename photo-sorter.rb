require "rmagick"
require "fileutils"

def make_dir path
  FileUtils.mkdir_p path unless File.exists? path
end

scan_dir = ARGV[ 0 ] || "."
output_dir = ARGV[ 1 ] || "."

ep = File.expand_path( scan_dir )
#Dir.entries( scan_dir ).each do | d |
Dir.glob( "#{ scan_dir }/**/*" ).each do | d |
  img_file = File.expand_path( d )
  next if img_file == "." || img_file == ".."
  next unless img_file.to_s.upcase.include? ".JPG"
  img = Magick::Image.read( img_file )[ 0 ]
  if img
    #img.get_exif_by_entry("Make")
    date_time = img.get_exif_by_entry( "DateTime" )[ 0 ][ 1 ]
    next if date_time.nil?
    year,month, rest = date_time.split( ":" )
    photo_dir_year = output_dir + "/" + "#{ year }"
    make_dir photo_dir_year
    photo_dir_month = output_dir + "/" + "#{ year }" + "/" + "#{ month }"
    make_dir photo_dir_month
    dst_file = photo_dir_month + "/" + File.basename( img_file )
    if !File.exists? dst_file
      FileUtils.cp img_file, photo_dir_month
      puts "copying #{ img_file } to #{ photo_dir_month }"
    else
      puts "WARNING #{ img_file } couldn't copied to #{ photo_dir_month }"
    end
  end
end
