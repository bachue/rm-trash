#!/usr/bin/env ruby
require 'optparse'

retval = 0

def parse_options!
  options = {}
  OptionParser.new do |opts|
  end.parse!
  options
end

def do_rm!
  to_delete = ARGV

  to_delete.each do |file|
    do_error_handling do
      abs_file = File.expand_path(file)
      if File.exists?(abs_file)
        rm(abs_file)
      else
        $stderr.puts "rm: #{file}: No such file or directory"
        retval = 1
      end
    end
  end
end

# To call AppleScript to delete a file
# file param must be absolute path
def rm(file)
  do_error_handling do
    `osascript -e 'tell app "Finder" to delete POSIX file "#{file}"'`
  end
end

def do_error_handling(*args)
  begin
    output = yield(*args)
  rescue
    $stderr.puts "Encounter an error when call AppleScript to delete file `#{file}'"
    $stderr.puts "Output: #{output}"
    $stderr.puts "#{$!}\n#{$@.join("\n")}"
    $stderr.puts "It should be a bug, please report this problem to bachue.shu@gmail.com!"
  end
end

parse_options!
do_rm!

exit retval