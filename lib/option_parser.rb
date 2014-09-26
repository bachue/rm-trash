require 'optparse'
require 'string_color'
require 'interaction'
require 'auto_update'

PARAMS = ARGV.dup

def parse_options!
  options = { :confirmation => :default }
  internal_options = ['--no-bug-report', '--no-auto-update'].freeze

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
    opts.on_tail('-h', '--help', 'Display this help.') do
      puts opts.to_s.split("\n").delete_if {|line| line =~ Regexp.union(internal_options) }.join("\n")
      exit 0
    end
    opts.on_tail('--version', 'Show version.') do
      puts CURRENT_VERSION.join('.')
      exit 0
    end
    if rm_path = find_rm_from_path
      opts.on('--rm', "Attempt to remove the files by #{rm_path} instead.") do
        rm_by_binary false
      end
    end
    opts.on('--color', '--colour', 'Colorful output.') do
      String.colorful = true
    end
    opts.on('--no-color', '--no-colour', 'Output only plain text.') do
      String.colorful = false
    end
    opts.on('--no-bug-report', 'Stop report bug to developer via email.') do
      # for internal only
      options[:no_bug_report] = true
    end
    opts.on('--no-auto-update', 'Don\'t check new version.') do
      options[:no_auto_update] = true
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

def no_bug_report?
  options[:no_bug_report]
end

def no_auto_update?
  options[:no_auto_update]
end
