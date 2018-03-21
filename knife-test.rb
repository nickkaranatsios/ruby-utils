require "open3"
require "chef/knife"
require "pp"

class MyKnife
  class KnifeError < StandardError
    def initialize(message)
      @message = message
    end

    def message
      @message
    end
  end

  class KnifeCommandError < KnifeError
    def initialize(message)
      super(message)
    end
  end

  class KnifeCommandReadError < KnifeError
    def initialize(message)
      super(message)
    end
  end

  def initialize(user='', key='./mykey')
    @user = user
    @key = key
  end

  def run_open3(argv=[])
#    argv << '--no-color'

    Open3.popen3("knife #{argv.join(' ')} 2>&1") do |stdin, stdout, stderr, wait_thr|
puts wait_thr.value.success?
      while line = stdout.gets
puts "line is #{line}"
      end
      #until io.eof?
      #  line = io.gets
        #line = io.gets.gsub(/\e\[(?:(?:[349]|10)[0-7]|[0-9]|[34]8;5;\d{1,3})?m/, '')
        #puts(line.chomp) if line !~ /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}\s*$/ && line !~ /^\s*$/
      # end
    end
  end

  def run_popen(argv=[])
    IO.popen("knife #{argv.join(' ')} 2>&1") do |io|
      until io.eof?
        begin
          line = io.gets.gsub(/\e\[(?:(?:[349]|10)[0-7]|[0-9]|[34]8;5;\d{1,3})?m/, '')
          puts "line is #{line}"
          puts(line.chomp) if line !~ /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}\s*$/ && line !~ /^\s*$/
        rescue
          raise(ArgumentError, "Failed to gsub output of knife #{argv.join(' ')}: #{$!}")
        end
      end
      io.close
      raise(ArgumentError, "knife #{argv.join(' ')}") if $?.to_i != 0
    end
  end
end

kf = MyKnife.new
args = ['client list']
#pp MyKnife.list_commands
cmd_out = kf.run_open3(args)
puts "open3 command"
cmd_out = kf.run_popen(args)
