require 'open3'
require 'helper'
require 'interaction'
require 'string_color'

# To call AppleScript to delete a list of file
# file param must be absolute path
def rm_all files
  run_apple_script <<-SCRIPT unless files.empty?
    tell app "Finder"
      #{files.map {|file|
        %[if exists POSIX file "#{file.to_s.escape_quote}" then delete POSIX file "#{file.to_s.escape_quote}"]
      }.join("\n")}
    end tell
  SCRIPT
end

def rm_all! files
  return if files.empty?
  processes = Math.sqrt(files.size).ceil
  partition = (files.size.to_f / processes).ceil
  tasks = processes.times.map {|i| files[partition*i...partition*(i+1)] }

  mytask = tasks.pop
  tasks.map do |task|
    fork do
      Signal.trap('INT') { exit! } # Kill itself once receives SIGINT
      rm_all task
    end
  end
  rm_all mytask # do this task by itself

  Process.waitall
end

def run_apple_script script
  do_error_handling do
    clear_env!
    Open3.popen3 'osascript', '-e', script do |stdin, stdout, stderr, thread|
      error = stderr.gets nil
      if error
        $retval = 1
        if error.include?('Finder got an error: AppleEvent timed out')
          $stderr.puts 'rm: delete timeout'.red
        else
          error! "#{error} from apple script `#{script}'"
        end
      elsif thread && thread.value.to_i.nonzero?
        error! "unknown error from apple script `#{script}'"
      end
    end
  end
end

def error! message
  message = unexpected_error_message message
  $stderr.puts message.red
  send_mail '[rm-trash] apple script error', message
end

def clear_env!
  to_delete = ENV.reject {|k, _| !k.start_with? 'DYLD_' }.keys
  to_delete.each {|k| ENV.delete k }
end
