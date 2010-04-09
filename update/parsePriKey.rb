
startMark = "-----BEGIN DSA PRIVATE KEY-----"
endMark = "-----END DSA PRIVATE KEY-----"

data = ""

#f = File.open(ARGV[0], "r")

STDIN.each_line do |line|
  data += line
end

startVAl = data.index(startMark)
endVal   = data.index(endMark, startVAl) + endMark.length

flatKey = data[startVAl, endVal-startVAl]
flatKey += "\n"

STDOUT.print flatKey