require 'open3'
require 'interaction'
require 'string_color'

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

def run cmd
  do_error_handling do
    stdin, stdout, stderr = Open3.popen3 cmd
    if error = stderr.gets(nil)
      $retval = 1
      $stderr.puts unexpected_error_message("#{error} from `#{cmd}'")
    end
    [stdin, stdout, stderr].each(&:close)
  end
end