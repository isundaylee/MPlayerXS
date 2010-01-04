tm = File.ctime(ARGV[0])
puts tm.strftime('%a, %d %b %Y %H:%M:%S') + " +0900"