#!/usr/bin/env ruby
require 'optparse'
require 'pp'
require 'open3'

$retval = 0

def parse_options!
  options = {}
  OptionParser.new do |opts|
    opts.on('-v', 'Be verbose when deleting files, showing them as they are removed.') do
      options[:verbose] = true
    end
  end.parse!
  options
end

def do_rm! files = [], options = {}
  abs_files = []
  relative_files = []
  files.each do |file|
    abs_file = File.expand_path(file)
    if File.exists?(abs_file)
      abs_files << abs_file
      relative_files << file
    else
      $stderr.puts "rm: #{file}: No such file or directory"
      $retval = 1
    end
  end

  rm(abs_files)
  relative_files.each {|file| puts file} if options[:verbose]
end

# To call AppleScript to delete a list of file
# file param must be absolute path
def rm files
  return if files.empty?
  do_error_handling do
    _, _, err = Open3.popen3 <<-CMD
      osascript -e '
        tell app "Finder"
          #{files.map {|file| "delete POSIX file \"#{file}\"" }.join("\n")}
        end tell
      '
    CMD
    if error = err.gets
      $retval = 1
      $stderr.puts error_message(error)
    end
  end
end

def do_error_handling *args
  begin
    yield(*args)
  rescue
    $stderr.puts error_message
  end
end

def error_message output = nil
  """
Error: #{"Output: #{output.strip}" if output}
Error Message: #{$! ? "#{$!}\n#{$@.join("\n")}" : 'no exception thrown'}
Global Variables: #{ PP.pp(global_variables.inject({}) {|h, gb| h[gb] = eval(gb); h}, '').strip }
Instance Variables: #{ PP.pp(instance_variables.inject({}) {|h, ib| h[ib] = instance_variable_get(ib); h}, '').strip }
It should be a bug, please report this problem to bachue.shu@gmail.com!
  """
end

do_error_handling do
  options = parse_options!
  do_rm! ARGV, options
end

exit $retval