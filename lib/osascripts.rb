require 'open3'
require 'helper'
require 'interaction'
require 'string_color'

# To call AppleScript to delete a list of file
# file param must be absolute path
def rm_all! files
  run <<-CMD
    osascript -e "
      tell app \\\"Finder\\\"
        #{files.map {|file| "delete POSIX file \\\"#{file.to_s.escape_as_filename}\\\"" }.join("\n")}
      end tell
    "
  CMD
end

def run cmd
  do_error_handling do
    stdin, stdout, stderr = Open3.popen3 cmd
    error = stderr.gets(nil)
    if error
      $retval = 1
      if error.include?('Finder got an error: AppleEvent timed out')
        $stderr.puts 'rm: delete timeout'.red
      else
        message = unexpected_error_message("#{error} from `#{cmd}'")
        $stderr.puts message.red
        send_mail 'Bachue', 'bachue.shu@gmail.com', '[rm-trash] error message', message
      end
    end
    [stdin, stdout, stderr].each(&:close)
  end
end
