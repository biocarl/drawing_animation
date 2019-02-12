#!/usr/bin/ruby
# Small script to encode/decode a large number of assets so I do not have to type all names manually.
i = 0
if(ARGV[0] == "decode")
  f = File.open("files.txt", "r")
  p 'decode'
  f.each_line do |line|
    cols = line.split(/\t/)
    begin
    File.rename(cols[0].strip, cols[1].strip)
    rescue SystemCallError => e
      p 'Already decoded. Encode first'
      f.close unless f.nil?
      exit(0)
    end
  end

else
  f = File.open("files.txt", "w+")
  p 'encode'
  #Encode
  Dir['*.svg'].sort.each do |file|
    next if File.directory? file 
    if(file == "0.svg")
      p 'Already encoded. Decode first'
      exit(0)
    end
    f.write("#{i}.svg\t" + file.gsub(" ","_")+"\n")
    File.rename(file, "#{i}.svg")
    i = i+1
  end
end
f.close unless f.nil?
