def puts (*msg)
  msg.map {|s| s.squeeze('/') }
end

def error (*msg)
  msg.map {|s| s.to_s.lightred }
end

class Verbose
  @verbose = Args['--verbose']
  def self.puts (*msg)
    STDOUT.puts *(msg.map(&:white)) if @verbose
  end

  def self.verbose?
    return @verbose
  end
end
