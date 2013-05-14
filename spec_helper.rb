require 'rubygems'
require 'bundler'
require 'bundler/setup'
require 'tmpdir'
require 'open3'
require 'highline/import'

Bundler.require :test
HighLine.color_scheme = HighLine::SampleColorScheme.new

def rm *args
  rm = File.expand_path(File.dirname(__FILE__) + '/rm.rb')
  _, stdout, stderr = Open3.popen3 [rm, *args].join(' ')
  [stdout.gets(nil), stderr.gets(nil)]
end

RSpec::Matchers.define :be_existed do
  match do |actual|
    File.exists? actual
  end
end

RSpec.configure do |config|
  config.before(:each) do
    @tmpdirs = []
  end

  config.after(:each) do
    FileUtils.rm_rf @tmpdirs
  end
end

at_exit {
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
}


class Array
  def disorder
    sort {rand * 2 - 1}
  end
end

def create_files root = Dir.mktmpdir
  @tmpdirs << root
  @files = (1..5).map {|i|
    file = "#{root}/file_#{i}"
    FileUtils.touch file
  }.flatten
end

def create_empty_dirs root = Dir.mktmpdir
  @tmpdirs << root
  @empty_dirs = ('a'..'e').map {|i|
    dir = "#{root}/empty_dir_#{i}"
    FileUtils.mkdir dir
  }.flatten
end

def create_non_empty_dirs root = Dir.mktmpdir
  @tmpdirs << root
  @all_files_in_non_empty_dirs = []
  @non_empty_dirs = ('a'..'e').map {|i|
    dir = "#{root}/non_empty_dir_#{i}"
    FileUtils.mkdir(dir).tap {|dirs|
      @all_files_in_non_empty_dirs.concat FileUtils.touch "#{dirs.first}/file"
    }
  }.flatten
end

def create_hierarchical_dirs root = Dir.mktmpdir
  @tmpdirs << root
  @hierachical_files, @all_files_in_hierachical_files = [], []
  ('a'..'e').each {|i0|
    dir = "#{root}/hierachical_dir_#{i0}"
    FileUtils.mkdir(dir).tap {|dirs1|
      ('a'..'e').each {|i1|
        @all_files_in_hierachical_files.concat FileUtils.mkdir("#{dirs1.first}/dir_#{i1}").tap { |dirs2|
          ('a'..'e').each {|i2|
            @all_files_in_hierachical_files.concat FileUtils.mkdir("#{dirs2.first}/dir_#{i2}").tap { |dirs3|
              ('a'..'e').each {|i3|
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