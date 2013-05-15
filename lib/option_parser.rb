def parse_options!
  options = {}
  OptionParser.new do |opts|
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
      options[:confirmation] = true
    end
    opts.on('-f', 'Attempt to remove the files without prompting for confirmation, regardless of the file\'s permissions.  ' <<
                  'If the file does not exist, do not display a diagnostic message or modify the exit status to ' <<
                  'reflect an error.  The -f option overrides any previous -i options.') do
      options[:force] = true
    end
  end.parse!
  options
end

def options
  @options ||= parse_options!
end
alias :parse_options :options

def forcely?
  !options[:confirmation] || options[:force]
end

def always_confirm?
  !forcely?
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