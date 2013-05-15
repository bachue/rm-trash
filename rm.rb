#!/usr/bin/env ruby
$: << File.expand_path(File.dirname(__FILE__) + '/lib')

require 'optparse'
require 'pp'
require 'open3'
require 'option_parser'
require 'interaction'
require 'array_tree_order'

$retval = 0

def rm! files = []
  files_to_rm, deleted_file_list = [], []
  files.each do |file|
    abs_file = File.expand_path(file)

    if File.exists?(abs_file) || File.symlink?(abs_file)
      if file.end_with?('/')
        if File.symlink?(abs_file)
          abs_file = File.expand_path(File.readlink(abs_file.chomp('/')))
        else
          check_if_not_dir(abs_file) do
            next
          end
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
  deleted_file_list.each {|file| puts file} if verbose?
end

def ready_to_rm abs_file, origin
  files_to_rm, deleted_file_list = [], []
  if File.directory?(abs_file)
    if rm_r?
      files_to_rm << abs_file
      deleted_file_list.concat Dir[origin + '{/**/**,}'].tree_order
    elsif rm_d?
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
    if rm_r?
      ignored_dir = nil
      origin_files.tree_order(true).each {|origin_file|
        abs_file = File.expand_path origin_file
        next if abs_file.start_with? ignored_dir
        if File.directory?(abs_file)
          ask_for_examine origin_file do |to_examine|
            if to_examine
              files_to_confirm << origin_file
            else
              ignored_dir = abs_file
            end
          end
        else
          ask_for_remove origin_file do
            rm_one! abs_file
          end
        end
      }
    else
      files_to_confirm = origin_files
    end

    files_to_confirm.tree_order.each do |origin_file|
      ask_for_remove origin_file do
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
  run <<-CMD
    osascript -e '
      tell app "Finder"
        #{files.map {|file| "delete POSIX file \"#{file}\"" }.join("\n")}
      end tell
    '
  CMD
end

# To call AppleScript to delete one file
# file param must be absolute path
def rm_one! file
  run "osascript -e 'tell app \"Finder\" to delete POSIX file \"#{file}\"'"
end

def run cmd
  do_error_handling do
    _, _, err = Open3.popen3 cmd
    if error = err.gets(nil)
      $retval = 1
      $stderr.puts unexpected_error_message("#{error} from `#{cmd}'")
    end
  end
end

def do_error_handling *args
  yield(*args)
rescue
  $stderr.puts unexpected_error_message("#{$!}\n#{$@.join("\n")}")
  exit(-256)
end

def unexpected_error_message output = nil
  """
Error: #{"Output: #{output.strip}" if output}
Global Variables: #{ PP.pp(global_variables.inject({}) {|h, gb| h[gb] = eval(gb.to_s); h}, '').strip }
Instance Variables: #{ PP.pp(instance_variables.inject({}) {|h, ib| h[ib] = instance_variable_get(ib.to_s); h}, '').strip }
It should be a bug, please report this problem to bachue.shu@gmail.com!
  """
end

do_error_handling do
  parse_options
  rm! ARGV
end

exit $retval
