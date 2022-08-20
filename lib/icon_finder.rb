def magick_installed?
  return system('which convert > /dev/null 2>&1')
end

def img_size (icon, w_only: false) # return size of the icon
  if w_only then format = '%w' else format = '%wx%h' end
  return `identify -format '#{format}' #{icon}`.chomp
end

def convert_img (icon, size = '512x512') # convert icon to .png format
  basename = File.basename(icon, '.*')
  output = "#{ICONDIR}/#{basename}.png"

  if icon =~ /512x512/
    FileUtils.cp icon, output
  else
    system 'convert', '-resize', size, icon, output, exception: true
  end
  return output, size, 'image/png'
rescue
  # conversion failed. try to make it work with png
  Verbose.puts "image conversion failed. defaulting to the original icon"
  return icon, size, 'image/png'
end

module IconFinder
  def self.find(pkgName, iconName) # find an icon from paths in package's filelist
    # TODO: support non-chromebrew apps
    fileList = File.readlines("#{CREW_PREFIX}/etc/crew/meta/#{pkgName}.filelist", chomp: true)
    svg = fileList.grep(/#{iconName}\.svg$/)[0]
    xpm = fileList.grep(/#{iconName}\.xpm$/)[0]
    png = ''
    fileList.grep(/#{iconName}\.png$/).each do |path|
      if path =~ /512x512/
        png = path
        break
      end
    end
    unless png =~ /512x512/
      png = fileList.grep(/#{iconName}\.png$/).sort_by do |path|
        # TODO: always use theme if available
        # get the highest resolution file
        path[/\d+x/].to_i
      end[-1]
    end

    # priority: 'app.svg' > 'app.png' > 'app.xpm' > Chromebrew Icon
    if svg
      iconPath, iconSize, iconMime = svg, '512x512', 'image/svg+xml'
    elsif magick_installed? and png and img_size(png, w_only: true).to_i >= 144
      # use the png if it meets the minimum requirement of PWA (must be >= 144x144px)
      pngSize = img_size(png)
      iconPath, iconSize, iconMime = png, pngSize, 'image/png'
    elsif png
      # if size < 144x144px, resize it
      iconPath, iconSize, iconMime = convert_img(png)
    elsif magick_installed? and xpm
      # convert the .xpm file to .png as .xpm is not supported by chrome
      iconPath, iconSize, iconMime = convert_img(xpm)
    else
      error 'Unable to find an icon :/'
      iconPath, iconSize, iconMime = CREWICON, '546x546', 'image/png'
    end

    # remove duplicate slash in path
    iconPath.squeeze!('/')

    Verbose.puts "Icon found: #{iconPath}" unless iconPath == CREWICON
    return iconPath, iconSize, iconMime
  end
end
