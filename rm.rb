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
    opts.on('-R', 'Attempt to remove the file hierarchy rooted in each file argument.  ' <<
                  'The -R option implies the -d option. If the -i option is specified, ' <<
                  'the user is prompted for confirmation before each directory\'s contents are processed ' <<
                  '(as well as before the attempt is made to remove the directory).  ' <<
                  'If the user does not respond affirmatively, the file hierarchy rooted in that directory is skipped.') do
      options[:recursion] = true
    end
    opts.on('-r', 'Equivalent to -R.') do
      options[:recursion] = true
    end
    opts.on('-i', 'Request confirmation before attempting to remove each file, regardless of the file\'s permissions, or ' <<
                  'whether or not the standard input device is a terminal.  The -i option overrides any previous -f ' <<
                  'options.') do
      options[:confirmation] = true
    end
    opts.on('-f', 'Attempt to remove the files without prompting for confirmation, regardless of the file\'s permissions.  ' <<
                  'If the file does not exist, do not display a diagnostic message or modify the exit status to ' <<
                  'reflect an error.  The -f option overrides any previous -i options.') do
      options[:force] = true
    end
  end.parse!
  options
end

def options
  @options ||= parse_options!
end
alias :parse_options :options

def rm! files = []
  files_to_rm, deleted_file_list = [], []
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
        _files_to_rm, _deleted_file_list = ready_to_rm(abs_file, file)
        files_to_rm.concat _files_to_rm
        deleted_file_list.concat _deleted_file_list
      else
        $stderr.puts "rm: #{file}: No such file or directory"
        $retval = 1
      end
    else
      $stderr.puts "rm: #{file}: No such file or directory"
      $retval = 1
    end
  end

  do_rm!(files_to_rm, deleted_file_list)
  deleted_file_list.each {|file| puts file} if options[:verbose]
end

def ready_to_rm abs_file, origin
  files_to_rm, deleted_file_list = [], []
  if File.directory?(abs_file)
    if options[:recursion]
      files_to_rm << abs_file
      deleted_file_list.concat Dir[origin + '{/**/**,}'].tree_order
    elsif options[:directory]
      if Dir[abs_file + '/*'].empty?
        files_to_rm << abs_file
        deleted_file_list << origin
      else
        $stderr.puts "rm: #{origin}: Directory not empty"
        $retval = 1
      end
    else
      $stderr.puts "rm: #{origin}: is a directory"
      $retval = 1
    end
  else
    files_to_rm << abs_file
    deleted_file_list << origin
  end
  [files_to_rm, deleted_file_list]
end

def do_rm! files, origin_files
  return if files.empty?
  if forcely?
    do_rm_forcely!(files)
  else # if always_confirm?
    do_rm_with_confirmation(origin_files)
  end
end

def do_rm_forcely! files
  rm_all! files
end

def do_rm_with_confirmation origin_files
  do_error_handling do

    files_to_confirm = []
    ignored_dir = nil
    origin_files.tree_order(true).each {|origin_file|
      abs_file = File.expand_path origin_file
      next if abs_file.start_with? ignored_dir
      if File.directory?(abs_file)
        $stderr.print "examine files in directory #{origin_file}? "
        if $stdin.gets.downcase.strip.start_with? 'y'
          files_to_confirm << origin_file
        else
          ignored_dir = abs_file
        end
      else
        $stderr.print "remove #{origin_file}? "
        if $stdin.gets.downcase.strip.start_with? 'y'
          rm_one! abs_file
        end
      end
    }

    files_to_confirm.tree_order.each do |origin_file|
      $stderr.print "remove #{origin_file}? "
      if $stdin.gets.downcase.strip.start_with? 'y'
        abs_file = File.expand_path origin_file
        if File.directory?(abs_file) && !Dir[abs_file + '/*'].empty?
          $stderr.puts "rm: #{origin_file}: Directory not empty"
          $retval = 1
        else
          rm_one! abs_file
        end
      end
    end
  end
end

# To call AppleScript to delete a list of file
# file param must be absolute path
def rm_all! files
  do_error_handling do
    cmd = <<-CMD
      osascript -e '
        tell app "Finder"
          #{files.map {|file| "delete POSIX file \"#{file}\"" }.join("\n")}
        end tell
      '
    CMD
    _, _, err = Open3.popen3 cmd
    if error = err.gets(nil)
      $retval = 1
      $stderr.puts unexpected_error_message("#{error} from `#{cmd}'")
    end
  end
end

# To call AppleScript to delete one file
# file param must be absolute path
def rm_one! file
  do_error_handling do
    cmd = "osascript -e 'tell app \"Finder\" to delete POSIX file \"#{file}\"'"
    _, _, err = Open3.popen3 cmd
    if error = err.gets(nil)
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
    exit(-256)
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

def forcely?
  !options[:confirmation] || options[:force]
end

def always_confirm?
  !forcely?
end

class Array
  def tree_order(preorder = false)
    mag_num = preorder ? -1 : 1
    sort { |f1, f2|
      case
      when f1.start_with?(f2); -mag_num
      when f2.start_with?(f1); mag_num
      else f1 <=> f2
      end
    }
  end
end

do_error_handling do
  parse_options
  rm! ARGV
end

exit $retval
