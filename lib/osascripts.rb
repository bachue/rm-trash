require 'open3'
require 'interaction'

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
    stdin, stdout, stderr = Open3.popen3 cmd
    if error = stderr.gets(nil)
      $retval = 1
      $stderr.puts unexpected_error_message("#{error} from `#{cmd}'")
    end
    stdin.close
    stdout.close
    stderr.close
  end
end