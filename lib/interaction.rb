require 'option_parser'
require 'string_color'
require 'helper'

def warn_if_any_current_or_parent_directory(paths)
  result = []
  err = false
  paths.each do |path|
    subpaths = path.split('/').map(&:strip).reject(&:empty?)
    next if subpaths.empty?
    if ['.', '..'].include?(subpaths.last)
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

def ask_for_remove?(file)
  ask "remove #{file}? "
  $stdin.gets.downcase.strip.start_with?('y')
end

def ask_for_examine?(dir)
  ask "examine files in directory #{dir}? "
  $stdin.gets.downcase.strip.start_with?('y')
end

def ask_for_override?(file)
  ask "override #{File.mode(file)} #{File.owner(file)}/#{File.gowner(file)} for #{file}? "
  $stdin.gets.downcase.strip.start_with?('y')
end

def ask(what)
  $stderr.print what.bright_yellow
end

def assert_existed?(file)
  unless ret = File.exists?(file) || File.symlink?(file)
    error file, :no_file
  end
  ret
end

def assert_not_dir?(dir)
  unless ret = File.directory?(dir)
    error dir, :not_dir
  end
  ret
end

def assert_not_recursive?(dir)
  unless ret = !File.directory?(dir) || Dir.empty?(dir)
    error dir, :not_empty
  end
  ret
end

def assert_same_size?(array1, array2)
  halt <<-MSG unless ret = array1.size == array2.size
2 file lists aren't the same
1: #{PP.pp(array1, '').strip }
2: #{PP.pp(array2, '').strip }
  MSG
  ret
end

def error(file, err)
  return if rm_f?
  error = 'rm: ' + {
    :no_file => "#{file}: No such file or directory",
    :not_dir => "#{file}: Not a directory",
    :not_empty => "#{file}: Directory not empty",
    :is_dir => "#{file}: is a directory"
  }[err]
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