require 'optparse'
require 'string_color'

def parse_options!
  options = { :confirmation => :default }
  parser = OptionParser.new do |opts|
    opts.banner = 'Usage: rm [options] file...'

    opts.on('-v', 'Be verbose when deleting files, showing them as they are removed.') do
      options[:verbose] = true
    end
    opts.on('-d', 'Attempt to remove directories as well as other types of files.') do
      options[:directory] = true
    end
    opts.on('-R', 'Attempt to remove the file hierarchy rooted in each file argument.  ' <<
                  'The -R option implies the -d option. If the -i option is specified, ' <<
                  'the user is prompted for confirmation before each directory\'s contents are processed ' <<
                  '(as well as before the attempt is made to remove the directory).  ' <<
                  'If the user does not respond affirmatively, the file hierarchy rooted in that directory is skipped.') do
      options[:recursion] = true
    end
    opts.on('-r', 'Equivalent to -R.') do
      options[:recursion] = true
    end
    opts.on('-i', 'Request confirmation before attempting to remove each file, regardless of the file\'s permissions, or ' <<
                  'whether or not the standard input device is a terminal.  The -i option overrides any previous -f ' <<
                  'options.') do
      options[:confirmation] = :always
    end
    opts.on('-f', 'Attempt to remove the files without prompting for confirmation, regardless of the file\'s permissions.  ' <<
                  'If the file does not exist, do not display a diagnostic message or modify the exit status to ' <<
                  'reflect an error.  The -f option overrides any previous -i options.') do
      options[:confirmation] = :never
    end
    opts.on('--rm', 'Find rm from $PATH and execute it. All parameters after --rm will belong to it') do
      rm = find_rm_from_path
      if rm
        exec [rm, *ARGV].join(' ')
      else
        $stderr.puts <<-EOF
Can't find rm from $PATH
$PATH: #{ENV['PATH'].inspect}
        EOF
        exit(-255)
      end
    end
    opts.on('--color', '--colour', 'Colorful output') do
      String.colorful = true
    end
    opts.on('--no-color', '--no-colour', 'White output') do
      String.colorful = false
    end
  end
  parser.parse! rescue nil # don't raise exception if wrong arg is given
  parser.parse! ['--help'] if ARGV.empty?
  options
end

def options
  @options ||= parse_options!
end
alias :parse_options :options

def forcely?
  options[:confirmation] == :never
end
alias :rm_f? :forcely?

def always_confirm?
  options[:confirmation] == :always
end
alias :rm_i? :always_confirm?

def verbose?
  options[:verbose]
end
alias :rm_v? :verbose?

def recursion?
  options[:recursion]
end
alias :rm_r? :recursion?

def rmdir?
  options[:directory]
end
alias :rm_d? :rmdir?

private
  def find_rm_from_path
    dir = ENV['PATH'].split(':').detect {|path|
      rm = Dir[path + '/rm'].first
      File.executable? rm if rm
    }
    dir + '/rm' if dir
  end
