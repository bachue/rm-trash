def ask_for_remove(file)
  $stderr.print "remove #{file}? "
  yield if block_given? && $stdin.gets.downcase.strip.start_with?('y')
end

def ask_for_examine(dir)
  $stderr.print "examine files in directory #{dir}? "
  yield $stdin.gets.downcase.strip.start_with?('y') if block_given?
end

def yield_if_existed(file)
  if File.exists?(file) || File.symlink?(file)
    yield if block_given?
  else
    $stderr.puts "rm: #{file}: No such file or directory"
    $retval = 1
  end
end

def yield_if_dir(dir)
  if File.directory?(dir)
    $stderr.puts "rm: #{dir}: is a directory"
    $retval = 1
    yield if block_given?
  end
end

def yield_if_not_dir(dir)
  unless File.directory?(dir)
    $stderr.puts "rm: #{dir}: Not a directory"
    $retval = 1
    yield if block_given?
  end
end

def yield_if_can_rm_d(dir)
  if !File.directory?(dir) || Dir[dir + '/*'].empty?
    yield if block_given?
  else
    $stderr.puts "rm: #{dir}: Directory not empty"
    $retval = 1
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