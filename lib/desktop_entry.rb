require_relative 'const'

class DesktopEntry
  def self.search_icon(icon_name)
    return Dir.glob(ICON_SEARCH_PATH.map {|path| "#{path}/**/#{icon_name}.{png,svg}" })
  end

  def self.parse_entry(file)
    parsed = File.readlines(file, chomp: true).reject {|l| l.empty? || l.start_with?('#')} .join("\n").split(/^(?=\[)/).to_h do |group|
      [
        group[/^\[(.+)\]$/, 1], # name of the group
        group.scan(/^(.+?)=(.*)$/).to_h # entries under the group
      ]
    end

    iconName   = parsed['Desktop Entry']['Icon']
    availIcons = DesktopEntry.search_icon(iconName)
    parsed['Desktop Entry']['Icon'] = { name: iconName, available: search_icon(iconName) }

    return parsed
  end

  def self.get_available_apps
    avail_entries = Dir.glob(APP_SEARCH_PATH.map {|path| "#{path}/*.desktop" })
    return avail_entries.map {|entry| DesktopEntry.parse_entry(entry).merge({ 'Path' => entry }) }
  end
end