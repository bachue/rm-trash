def ask_for_remove(file)
  $stderr.print "remove #{file}? "
  yield if block_given? && $stdin.gets.downcase.strip.start_with?('y')
end

def ask_for_examine(dir)
  $stderr.print "examine files in directory #{dir}? "
  yield $stdin.gets.downcase.strip.start_with?('y') if block_given?
end

def check_if_not_dir(dir)
  unless File.directory?(abs_file)
    $stderr.puts "rm: #{file}: Not a directory"
    $retval = 1
    yield if block_given?
  end
end
