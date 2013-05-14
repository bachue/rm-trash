require 'rubygems'
require 'bundler'
require 'bundler/setup'
require 'tmpdir'
require 'open3'

Bundler.require :test

def rm *args
  rm = File.expand_path(File.dirname(__FILE__) + '/rm.rb')
  _, stdout, stderr = Open3.popen3 [rm, *args].join(' ')
  [stdout.gets(nil), stderr.gets(nil)]
end

RSpec::Matchers.define :be_exists do
  match do |actual|
    File.exists? actual
  end
end

class Array
  def disorder
    sort {rand * 2 - 1}
  end
end

def create_files root = Dir.mktmpdir
  @files = (1..5).map {|i|
    file = "#{root}/file_#{i}"
    FileUtils.touch file
  }.flatten
end

def create_empty_dirs root = Dir.mktmpdir
  @empty_dirs = ('a'..'e').map {|i|
    dir = "#{root}/empty_dir_#{i}"
    FileUtils.mkdir dir
  }.flatten
end

def create_non_empty_dirs root = Dir.mktmpdir
  @all_files_in_non_empty_dirs = []
  @non_empty_dirs = ('a'..'e').map {|i|
    dir = "#{root}/non_empty_dir_#{i}"
    FileUtils.mkdir(dir).tap {|dirs|
      @all_files_in_non_empty_dirs.concat FileUtils.touch "#{dirs.first}/file"
    }
  }.flatten
end

def create_hierarchical_dirs root = Dir.mktmpdir
  @hierachical_files, @all_files_in_hierachical_files = [], []
  ('a'..'e').each {|i|
    dir = "#{root}/hierachical_dir_#{i}"
    FileUtils.mkdir(dir).tap {|dirs|
      ('a'..'e').each {|i|
        @all_files_in_hierachical_files.concat FileUtils.mkdir("#{dirs.first}/dir_#{i}").tap { |dirs|
          ('a'..'e').each {|i|
            @all_files_in_hierachical_files.concat FileUtils.mkdir("#{dirs.first}/dir_#{i}").tap { |dirs|
              ('a'..'e').each {|i|
                @all_files_in_hierachical_files.concat FileUtils.touch("#{dirs.first}/file_#{i}")
              }
            }
            @all_files_in_hierachical_files.concat FileUtils.touch("#{dirs.first}/file_#{i}")
          }
        }
        @all_files_in_hierachical_files.concat FileUtils.touch("#{dirs.first}/file_#{i}")
      }
      @hierachical_files.concat dirs
      @all_files_in_hierachical_files.concat dirs
    }
    FileUtils.touch("#{dirs.first}/file_#{i}").tap {|files|
      @hierachical_files.concat files
      @all_files_in_hierachical_files.concat files
    }
  }
end