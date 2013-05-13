#!/usr/bin/env ruby
require 'optparse'
require 'pp'

retval = 0

def parse_options!
  options = {}
  OptionParser.new do |opts|
    opts.on('-v', nil, 'Be verbose when deleting files, showing them as they are removed.') do
      options[:verbose] = true
    end
  end.parse!
  options
end

def do_rm! to_delete = [], options = {}
  to_delete.each do |file|
    do_error_handling do
      abs_file = File.expand_path(file)
      if File.exists?(abs_file)
        rm(abs_file)
        puts file if options[:verbose]
      else
        $stderr.puts "rm: #{file}: No such file or directory"
        retval = 1
      end
    end
  end
end

# To call AppleScript to delete a file
# file param must be absolute path
def rm file
  do_error_handling do
    `osascript -e 'tell app "Finder" to delete POSIX file "#{file}"'`
  end
end

def do_error_handling *args
  begin
    output = yield(*args)
  rescue
    $stderr.puts "Encounter an error when call AppleScript to delete file `#{file}'"
    $stderr.puts "Output: #{output}"
    $stderr.puts "Error Message: #{$!}\n#{$@.join("\n")}"
    $stderr.puts "Global Variables: #{ pp global_variables.inject({}) {|h, gb| h[gb] = eval(gb); h} }"
    $stderr.puts "Instance Variables: #{ pp instance_variables.inject({}) {|h, ib| h[ib] = instance_variable_get(ib); h} }"
    $stderr.puts "It should be a bug, please report this problem to bachue.shu@gmail.com!"
  end
end

do_error_handling do
  options = parse_options!
  do_rm! ARGV, options
end

exit retval