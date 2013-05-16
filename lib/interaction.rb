require 'string_color'

def warn_if_any_current_or_parent_directory(paths)
  result = []
  err = false
  paths.each do |path|
    subpaths = path.split('/').map(&:strip).reject(&:empty?)
    next if subpaths.empty?
    if ['.', '..'].include?(subpaths.last)
      error path, :current_or_parent_dir unless err
      err = true
    else
      result << path
    end
  end
  result
end

def ask_for_remove(file)
  $stderr.print "remove #{file}? ".bright_yellow
  yield if block_given? && $stdin.gets.downcase.strip.start_with?('y')
end

def ask_for_examine(dir)
  $stderr.print "examine files in directory #{dir}? ".bright_yellow
  yield $stdin.gets.downcase.strip.start_with?('y') if block_given?
end

def assert_existed(file)
  if File.exists?(file) || File.symlink?(file)
    yield if block_given?
  else
    error file, :no_file
  end
end

def do_if_not_dir(dir)
  unless File.directory?(dir)
    error dir, :not_dir
    yield if block_given?
  end
end

def assert_not_recursive(dir)
  if !File.directory?(dir) || Dir[dir + '/*'].empty?
    yield if block_given?
  else
    error dir, :not_empty
  end
end

def error(file, err)
  error = 'rm: ' + {
    :no_file => "#{file}: No such file or directory",
    :not_dir => "#{file}: Not a directory",
    :not_empty => "#{file}: Directory not empty",
    :is_dir => "#{file}: is a directory",
    :current_or_parent_dir => '"." and ".." may not be removed'
  }[err]
  $stderr.puts error.red
  $retval = 1
end

def do_error_handling *args
  yield(*args)
rescue
  $stderr.puts unexpected_error_message("#{$!}\n#{$@.join("\n")}").red
  exit(-256)
end

def unexpected_error_message output = nil
  """
Error: #{"Output: #{output.strip}" if output}
Caller: #{PP.pp(caller, '').strip }
Global Variables: #{ PP.pp(global_variables.inject({}) {|h, gb| h[gb] = eval(gb.to_s); h}, '').strip }
Instance Variables: #{ PP.pp(instance_variables.inject({}) {|h, ib| h[ib] = instance_variable_get(ib.to_s); h}, '').strip }
It should be a bug, please report this problem to bachue.shu@gmail.com!
  """
end