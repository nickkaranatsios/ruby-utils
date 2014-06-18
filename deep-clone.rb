require "git"
dir = ARGV[ 0 ] || "."

ep = File.expand_path( dir )
Dir.entries( dir ).each do | d |
  next if d == "." || d == ".."
  git_dir = ep + "/" + d
  Dir.chdir( git_dir ) do
    g = Git.open( git_dir )
    puts "#{ git_dir }: git pull remote=origin branch=master"
    begin
      g.pull
    rescue Git::GitExecuteError
      puts "failed to clone pull to #{ git_dir }"
    end
  end
end
