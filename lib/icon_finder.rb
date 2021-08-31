def img_size (icon, w_only: false) # return size of the icon
  if w_only then format = '%w' else format = '%wx%h' end
  return `identify -format '#{format}' #{icon}`.chomp
end

def convert_img (icon, size = '512x512') # convert icon to .png format
  basename = File.basename(icon, '.*')
  output = "#{PWAIconPath}/#{basename}.png"

  system 'convert', '-resize', size, icon, output, exception: true
  return output, size, 'image/png'
end

module IconFinder
  def self.find(iconName) # find an icon from paths in IconSearchGlob
    svg = Dir.glob( IconSearchGlob.map {|p| p % "#{iconName}.svg" } )[0]
    xpm = Dir.glob( IconSearchGlob.map {|p| p % "#{iconName}.xpm" } )[0]
    png = Dir.glob( IconSearchGlob.map {|p| p % "#{iconName}.png" } ).sort_by do |path|
      # TODO: always use theme if available
      # get the highest resolution file
      path[/\d+x/].to_i
    end[-1]

    # priority: 'app.svg' > 'app.png' > 'app.xpm' > Chromebrew Icon
    if svg
      iconPath, iconSize, iconMime = svg, '512x512', 'image/svg+xml'
    elsif png and img_size(png, w_only: true).to_i >= 144
      # use the png if it meets the minimum requirement of PWA (must be >= 144x144px)
      pngSize = img_size(png)
      iconPath, iconSize, iconMime = png, pngSize, 'image/png'
    elsif png
      # if size < 144x144px, resize it
      iconPath, iconSize, iconMime = convert_img(png)
    elsif xpm
      # convert the .xpm file to .png as .xpm is not supported by chrome
      iconPath, iconSize, iconMime = convert_img(xpm)
    else
      error 'Unable to find an icon :/'
      iconPath, iconSize, iconMime = CrewIcon, '546x546', 'image/png'
    end
 
    # remove duplicate slash in path
    iconPath.squeeze!('/')

    puts <<~EOT.lightblue
      Icon infomation:

      Name = #{iconName}
      File = #{iconPath}
      Type = #{iconMime}
      Size = #{iconSize}
    EOT

    return iconPath, iconSize, iconMime
  end
end
