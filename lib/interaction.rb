require 'option_parser'
require 'string_color'
require 'helper'

def warn_if_any_current_or_parent_directory paths
  result = []
  err = false
  paths.each do |path|
    if /(^|\/)\.{1,2}$/ =~ path
      unless err
        $stderr.puts 'rm: "." and ".." may not be removed'
        $retval = 1
      end
      err = true
    else
      result << path
    end
  end
  result
end

def ask_for_remove? file
  ask "remove #{file}? "
  $stdin.gets.downcase.strip.start_with?('y')
end

def ask_for_examine? dir
  ask "examine files in directory #{dir}? "
  $stdin.gets.downcase.strip.start_with?('y')
end

def ask_for_override? file
  ask "override #{file.permissions} #{file.owner}/#{file.gowner} for #{file}? "
  $stdin.gets.downcase.strip.start_with?('y')
end

def ask what
  $stderr.print what.bright_yellow
end

def assert_existed? file
  unless ret = file.follow_symlink? ? file.exists? : file.exists_or_symlink?
    error file, Errno::ENOENT unless rm_f?
  end
  ret
end

def assert_dir? dir
  unless ret = dir.directory?
    error dir, Errno::ENOTDIR
  end
  ret
end

def assert_no_children? dir
  if ret = dir.directory? && dir.has_children?
    error dir, Errno::ENOTEMPTY
  end
  !ret
end

def assert_valid? file
  if ret = /(^|\/)\.\// =~ file
    error file, Errno::EINVAL
  end
  !ret
end

def error file, errno
  error = "rm: #{file}: #{errno.new.message}"
  $stderr.puts error.red
  $retval = 1
end

def do_error_handling *args
  yield(*args)
rescue
  halt "#{$!}\n#{$@.join("\n")}"
end

def halt message
  $stderr.puts unexpected_error_message(message)
  exit(-256)
end

def unexpected_error_message output = nil
  """
Error: #{"Output: #{output.strip}" if output}
Caller: #{PP.pp(caller, '').strip }
Global Variables: #{ PP.pp(global_variables.inject({}) {|h, gb| h[gb] = eval(gb.to_s); h}, '').strip }
Instance Variables: #{ PP.pp(instance_variables.inject({}) {|h, ib| h[ib] = instance_variable_get(ib.to_s); h}, '').strip }
It should be a bug, please report this problem to bachue.shu@gmail.com!
  """.red
end