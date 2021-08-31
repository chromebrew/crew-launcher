module DesktopFile
  def self.find(app) # find a .desktop file from paths in DesktopSearchGlob
    results = Dir.glob(DesktopSearchGlob.map {|p| p % app })
    if results.any?
      return results[0]
    else
      abort "Cannot find an `.desktop` file for #{app} :/".lightred
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
