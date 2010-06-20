def get_file_as_string(filename)
  data = ''
  f = File.open(filename, "r") 
  f.each_line do |line|
    data += line
  end
  return data
end

infoplist = get_file_as_string(ARGV[0] + "/Contents/Info.plist")

start_of_key = infoplist.index("CFBundleShortVersionString")
start_of_value = infoplist.index("<string>", start_of_key) + 8
end_of_value = infoplist.index("</string>", start_of_value)
old_value = infoplist[start_of_value, end_of_value - start_of_value]

$stdout << old_value
ENV['MPXVER'] = old_value