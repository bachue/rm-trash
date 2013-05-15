def ask_for_remove(file)
  $stderr.print "remove #{file}? "
  yield if block_given? && $stdin.gets.downcase.strip.start_with?('y')
end

def ask_for_examine(dir)
  $stderr.print "examine files in directory #{dir}? "
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
  error = "rm: #{file}: " + {
    :no_file => 'No such file or directory',
    :not_dir => 'Not a directory',
    :not_empty => 'Directory not empty',
    :is_dir => 'is a directory'
  }[err]
  $stderr.puts error
  $retval = 1
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