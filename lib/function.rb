# function.rb: functions with frequently used codes

def puts (*msg)
  msg.map {|s| STDOUT.puts(s.to_s.squeeze('/')) }
end

def error (*msg)
  msg.map {|s| STDERR.puts(s.to_s.lightred) }
end

class Verbose
  @verbose = Args['verbose']
  def self.puts (*msg)
    msg.map {|s| STDOUT.puts(s.to_s.squeeze('/').white) } if @verbose
  end

  def self.verbose?
    return @verbose
  end
end
