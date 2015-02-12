require 'option_parser'
require 'string_color'
require 'helper'

def warn_if_any_current_or_parent_directory paths
  result = []
  err = false
  paths.each do |path|
    if path == '.' || path.end_with?('/.') ||
       path == '..' || path.end_with?('/..')
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

def ask_for_fallback? file
  ask "cannot move #{file.ftype} file #{file} to trash, delete it directly? "
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
  if ret = file.to_s == './' || file.end_with?('/./')
    error file, Errno::EINVAL
  end
  !ret
end

def error file, error
  error = error.new.message if error.is_a?(Class)
  error = "rm: #{file}: #{error}"
  $stderr.puts error.red
  $retval = 1
end

def do_error_handling *args
  yield(*args)
rescue
  halt "#{$!}\n#{$@.join("\n")}"
end

def halt message
  message = unexpected_error_message(message)
  $stderr.puts message.red
  send_mail '[rm-trash] error message', message
  exit(-256)
end

def unexpected_error_message output = nil
  """
Error: #{"Output: #{output.strip}" if output}
Caller: #{PP.pp(caller, '').strip }
Arguments: #{PARAMS.inspect}
Command: #{PARAMS.join(' ')}
Ruby: #{RUBY_DESCRIPTION}
OSX: #{`sw_vers -productVersion`.strip}
Machine: #{`uname -a`.strip}
Instance Variables: #{ PP.pp(instance_variables.inject({}) {|h, ib| h[ib] = instance_variable_get(ib.to_s); h}, '').strip }
It should be a bug, please report this problem to bachue.shu@gmail.com!
We may take 1 or 2 days to fix that, you could use #{find_rm_from_path} or \\rm to remove your files!
  """
end

MAIL_ADDR = 'bachue.shu@gmail.com'
def send_mail subject, content
  return if no_bug_report?
  Open3.popen3 'mail', '-s', subject, MAIL_ADDR do |stdin, _, _|
    stdin.puts content
  end
end

def rm_by_binary fork = true
  rm = find_rm_from_path
  if rm && fork
    system 'rm', *ARGV
  elsif rm
    exec 'rm', *ARGV
  else
    $stderr.puts <<-EOF
Can't find rm from $PATH
$PATH: #{ENV['PATH'].inspect}
    EOF
    exit(-255) unless fork
  end
end

def find_rm_from_path
  path = `which rm`
  return nil if path.empty?

  # Reject the possibility if the found rm is a link or rm-trash self
  return nil if path.include?('rm: aliased to')
  return nil if path.include?('rm-trash')

  path.strip
end
