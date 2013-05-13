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
    opts.on('-d', 'Attempt to remove directories as well as other types of files.') do
      options[:directory] = true
    end
    opts.on('-R', 'Attempt to remove the file hierarchy rooted in each file argument. ' <<
                  'The -R option implies the -d option. If the -i option is specified, ' <<
                  'the user is prompted for confirmation before each directory\'s contents are processed ' <<
                  '(as well as before the attempt is made to remove the directory). ' <<
                  'If the user does not respond affirmatively, the file hierarchy rooted in that directory is skipped.') do
      options[:recursion] = true
    end
    opts.on('-r', 'Equivalent to -R.') do
      options[:recursion] = true
    end
  end.parse!
  options
end

def do_rm! files = [], options = {}
  files_to_delete = []
  files_to_output = []
  files.each do |file|
    abs_file = File.expand_path(file)

    if File.exists?(abs_file) || File.symlink?(abs_file)
      if file.end_with?('/')
        if File.symlink?(abs_file)
          abs_file = File.expand_path(File.readlink(abs_file.chomp('/')))
        elsif !File.directory?(abs_file)
          $stderr.puts "rm: #{file}: Not a directory"
          $retval = 1
          next
        end
      end

      if File.exists?(abs_file) || File.symlink?(abs_file)
        if File.directory?(abs_file)
          if options[:recursion]
            files_to_delete << abs_file
            files_to_output.concat Dir[file + '{/**/**,}'].traverse_files_recursively
          elsif options[:directory]
            if Dir[abs_file + '/*'].empty?
              files_to_delete << abs_file
              files_to_output << file
            else
              $stderr.puts "rm: #{file}: Directory not empty"
              $retval = 1
            end
          else
            $stderr.puts "rm: #{file}: is a directory"
            $retval = 1
          end
        else
          files_to_delete << abs_file
          files_to_output << file
        end
      else
        $stderr.puts "rm: #{file}: No such file or directory"
        $retval = 1
      end
    else
      $stderr.puts "rm: #{file}: No such file or directory"
      $retval = 1
    end
  end

  rm_all(files_to_delete)
  files_to_output.each {|file| puts file} if options[:verbose]
end

# To call AppleScript to delete a list of file
# file param must be absolute path
def rm_all files
  return if files.empty?
  do_error_handling do
    cmd = <<-CMD
      osascript -e '
        tell app "Finder"
          #{files.map {|file| "delete POSIX file \"#{file}\"" }.join("\n")}
        end tell
      '
    CMD
    _, _, err = Open3.popen3 cmd
    if error = err.gets
      $retval = 1
      $stderr.puts unexpected_error_message("#{error} from `#{cmd}'")
    end
  end
end

def do_error_handling *args
  begin
    yield(*args)
  rescue
    $stderr.puts unexpected_error_message("#{$!}\n#{$@.join("\n")}")
  end
end

def unexpected_error_message output = nil
  """
Error: #{"Output: #{output.strip}" if output}
Global Variables: #{ PP.pp(global_variables.inject({}) {|h, gb| h[gb] = eval(gb.to_s); h}, '').strip }
Instance Variables: #{ PP.pp(instance_variables.inject({}) {|h, ib| h[ib] = instance_variable_get(ib.to_s); h}, '').strip }
It should be a bug, please report this problem to bachue.shu@gmail.com!
  """
end

class Array
  def traverse_files_recursively
    sort { |f1, f2|
      case
      when f1.start_with?(f2); -1
      when f2.start_with?(f1); 1
      else f1 <=> f2
      end
    }
  end
end

do_error_handling do
  options = parse_options!
  do_rm! ARGV, options
end

exit $retval