module DesktopFile
  def self.find(pkg) # find a .desktop file from package's filelist
    abort "Package #{pkg} isn't installed.".lightred unless File.exist?("#{CREW_PREFIX}/etc/crew/meta/#{pkg}.filelist")

    results = `grep -m1 '\\.desktop$' #{CREW_PREFIX}/etc/crew/meta/#{pkg}.filelist`.chomp
    unless results.empty?
      Verbose.puts "Desktop Entry File found: #{results}"
      return results
    else
      abort "Cannot find an `.desktop` file for #{pkg} :/".lightred
    end
  end

  def self.parse(path) # parse .desktop file into hash
    file = File.read(path, encoding: Encoding::UTF_8)

    # split groups
    file.split("\n\n").map do |group|
      group.strip!
      header = group.lines[0][/\[(.+)\]/, 1]
      entries = group.scan(/^(.+)=(.*)/)

      if Locale
        # get all localized entries
        localizedKeys = entries.keys.grep(/\[(#{Locale[:lang]})(_#{Locale[:country]})?(@#{Locale[:modifier]})?\]$/)

        entries.map! do |k, v|
          # replace values with localized one if available
          matchedKey = localizedKeys.grep(/^#{k}/)[0]
          v = entries[matchedKey] if matchedKey

          [ k, v ]
        end
      end

      [ header, entries.to_h ]
    end.to_h
    # return in `{group => {entry}, group => {entry}...}`
  end
end
