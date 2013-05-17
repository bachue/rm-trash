require 'rubygems'
require 'bundler'
require 'bundler/setup'
require 'fileutils'
require 'tmpdir'
require 'timeout'
require 'open3'
require 'highline/import'
require 'set'

ENV['BUNDLE_GEMFILE'] = File.expand_path(File.dirname(__FILE__)) + '/Gemfile'

Bundler.require :test
HighLine.color_scheme = HighLine::SampleColorScheme.new

RM = File.expand_path(File.dirname(__FILE__) + '/rm.rb --no-color')

def rm *args
  stdin, stdout, stderr = Open3.popen3 [RM, *args].join(' ')
  @io.concat [stdin, stdout, stderr]
  [stdin, stdout, stderr]
end

class IO
  def gets_with_timeout *args
    Timeout::timeout(3) { gets_without_timeout(*args) }
  end

  alias_method :gets_without_timeout, :gets
  alias_method :gets, :gets_with_timeout
end

RSpec::Matchers.define :be_existed do
  match do |actual|
    File.exists?(actual) || File.symlink?(actual)
  end
end

RSpec.configure do |config|
  config.before(:each) do
    @tmpdir = Dir.mktmpdir
    @tmpdirs = Set.new [@tmpdir]
    @io = []
  end

  config.after(:each) do
    FileUtils.rm_rf @tmpdirs.to_a
    @io.each(&:close)
  end
end

at_exit {
  if $stdin.tty?
    answer = ask <<-ASK
<%= color('Are you sure you want to permanently erase the items in the Trash? [', :notice) %><%= color('y', :error) %><%= color('/', :notice) %><%= color('N', :debug) %><%= color(']', :notice) %>
    ASK
    if answer.downcase.start_with? 'y'
      say '<%= color(\'Yes Sir!\', :debug) %>'
      `osascript -e 'tell app "Finder"
        empty the trash
        beep
      end tell'`
    else
      say '<%= color(\'See you :)\', :debug) %>'
    end
  end
}

class Array
  def disorder
    sort {rand * 2 - 1}
  end
end

def create_files root = @tmpdir
  @tmpdirs << root
  @files = (1..2).map {|i|
    file = "#{root}/file_#{i}"
    FileUtils.touch file
  }.flatten
end

def create_empty_dirs root = @tmpdir
  @tmpdirs << root
  @empty_dirs = ('a'..'b').map {|i|
    dir = "#{root}/empty_dir_#{i}"
    FileUtils.mkdir dir
  }.flatten
end

def create_non_empty_dirs root = @tmpdir
  @tmpdirs << root
  @all_files_in_non_empty_dirs = []
  @non_empty_dirs = ('a'..'b').map {|i|
    dir = "#{root}/non_empty_dir_#{i}"
    FileUtils.mkdir(dir).tap {|dirs|
      @all_files_in_non_empty_dirs.concat FileUtils.touch "#{dirs.first}/file"
    }
  }.flatten
end

def create_hierarchical_dirs root = @tmpdir
  @tmpdirs << root
  @hierachical_files, @all_files_in_hierachical_files = [], []
  ('a'..'b').each {|i0|
    dir = "#{root}/hierachical_dir_#{i0}"
    FileUtils.mkdir(dir).tap {|dirs1|
      ('a'..'b').each {|i1|
        @all_files_in_hierachical_files.concat FileUtils.mkdir("#{dirs1.first}/dir_#{i1}").tap { |dirs2|
          ('a'..'b').each {|i2|
            @all_files_in_hierachical_files.concat FileUtils.mkdir("#{dirs2.first}/dir_#{i2}").tap { |dirs3|
              ('a'..'b').each {|i3|
                @all_files_in_hierachical_files.concat FileUtils.touch("#{dirs3.first}/file_#{i3}")
              }
            }
            @all_files_in_hierachical_files.concat FileUtils.touch("#{dirs2.first}/file_#{i2}")
          }
        }
        @all_files_in_hierachical_files.concat FileUtils.touch("#{dirs1.first}/file_#{i1}")
      }
      @hierachical_files.concat dirs1
      @all_files_in_hierachical_files.concat dirs1
    }

    FileUtils.touch("#{root}/file_#{i0}").tap {|files|
      @hierachical_files.concat files
      @all_files_in_hierachical_files.concat files
    }
  }
end

def create_symbolic_links_to_files root = @tmpdir
  @tmpdirs << root
  create_files root
  @links_to_files = @files.map { |f|
    links = f + '_link'
    FileUtils.ln_s f, links
    links
  }
end

def create_symbolic_links_to_dirs root = @tmpdir
  @tmpdirs << root
  create_non_empty_dirs root
  @links_to_dirs = @non_empty_dirs.map { |f|
    links = f + '_link'
    FileUtils.ln_s f, links
    links
  }
end

def create_broken_symbolic_links root = @tmpdir
  @tmpdirs << root
  @broken_links = (1..2).map {|i|
    links = "#{root}/link_#{i}"
    FileUtils.ln_sf "#{root}/file_#{i}", links
    links
  }
end

def create_ring_symbolic_links root = @tmpdir
  @tmpdirs << root
  @ring_links = (1..2).map {|i| "#{root}/links_#{i}" }
  @ring_links.each_with_index { |f, i|
    FileUtils.ln_sf f, @ring_links[i + 1] || @ring_links[0]
  }
end

def create_hierarchical_dirs_without_write_permission root = @tmpdir
  @tmpdirs << root
  @dir = "#{root}/dir"
  FileUtils.mkdir @dir
  @all_files_without_permission = (1..2).map {|i|
    file = "#{@dir}/#{i}"
    FileUtils.touch file
    File.chmod 0444, file
    file
  }
  @subdir = "#{@dir}/dir"
  FileUtils.mkdir @subdir
  @all_files_without_permission += (1..2).map { |i|
    file = "#{@subdir}/#{i}"
    FileUtils.touch file
    File.chmod 0444, file
    file
  }
  @all_files = @all_files_without_permission + [@subdir, @dir]
end