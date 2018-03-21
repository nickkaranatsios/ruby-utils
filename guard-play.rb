require 'guard'
require 'guard/commander'

guardfile = <<-EOF
guard :shell do
  watch(//) do |modified_files|
    puts "Modified files: #{modified_files}"
    `tail #{modified_files[0]}`
  end
end
EOF

Guard.start(guardfile_contents: guardfile)
