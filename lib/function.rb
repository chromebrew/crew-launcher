def error (*msg)
  STDERR.puts *(msg.map(&:lightred))
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
