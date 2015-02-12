# Encoding: UTF-8

$KCODE = 'u' unless RUBY_VERSION.to_f >= 1.9

require 'rubygems'
require 'bundler'
require 'bundler/setup'
require 'fileutils'
require 'tmpdir'
require 'timeout'
require 'open3'
require 'socket'
require 'mkfifo'
require 'highline/import'
require 'set'
require 'pathname'
require 'helper'
require 'alias_method_chain'

ENV['BUNDLE_GEMFILE'] = File.expand_path(File.dirname(__FILE__)) + '/Gemfile'

Bundler.require :test
HighLine.color_scheme = HighLine::SampleColorScheme.new

RM = [File.expand_path(File.dirname(__FILE__) + '/rm.rb'), '--no-color', '--no-bug-report', '--no-auto-update']

def rm *args
  args = RM + args.flatten
  stdin, stdout, stderr = Open3.popen3(*args)
  @io.concat [stdin, stdout, stderr]
  [stdin, stdout, stderr]
end

class IO
  def gets_with_timeout *args
    Timeout::timeout(3) { gets_without_timeout(*args) }
  end

  alias_method_chain :gets, :timeout
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
    if answer && answer.downcase.start_with?('y')
      say '<%= color(\'Yes Sir!\', :debug) %>'
      sleep 1 # to wait for all file descs closed
      exec <<-CMD
        osascript -e 'tell app "Finder"
          empty the trash
          beep
        end tell'
      CMD
    else
      say '<%= color(\'See you :)\', :debug) %>'
    end
  end
}

class Array
  def disorder
    sort {rand * 2 - 1}
  end

  def insert_wherever element
    dup.insert rand(size + 1), element
  end
end

class Object
  def self.redefine_method_within src, dst
    tmp = "#{src}_#{rand 10**10}"
    alias_method tmp, src
    alias_method src, dst
    begin
      yield
    ensure
      alias_method src, tmp
      remove_method tmp
    end
  end
end

def create_files root = @tmpdir
  @tmpdirs << root
  @files = %w(1 2).map {|i|
    file = "#{root}/file_#{i}"
    FileUtils.touch file
  }.flatten
end

def create_files_with_quote root = @tmpdir
  @tmpdirs << root
  @files = ["'", '"', %%'"'%, %%"'"%, %%''%, %%""%, %%'''%, %%"""%].map {|name|
    file = "#{root}/#{name}"
    FileUtils.touch file
  }.flatten
end

def create_files_with_non_ascii_chars root = @tmpdir
  @tmpdirs << root
  @files = ['fi_文件_le', '文件', 'ぶんしょ', 'Документ'].map {|name|
    file = "#{root}/#{name}"
    FileUtils.touch file
  }.flatten
end

def create_files_with_non_ascii_chars_and_quote root = @tmpdir
  @tmpdirs << root
  @files = ['`我的"文档"！{', '!@$%^&*()_+-={}[]\;\':".,<?>`~'].map {|name|
    file = "#{root}/#{name}"
    FileUtils.touch file
  }.flatten
end

def create_files_started_with_wave root = @tmpdir
  @tmpdirs << root
  @files = ['~$商业化运营案例（严禁外发）.xlsx'].map {|name|
    file = "#{root}/#{name}"
    FileUtils.touch file
    name
  }.flatten
end

def create_trashed_files
  @files = %w(1 2).map {|name|
    file = "#{ENV['HOME']}/.Trash/#{name}"
    FileUtils.touch file
  }.flatten
end

def create_special_files root = @tmpdir
  @tmpdirs << root
  filename1 = "#{root}/pipe_file"
  File.mkfifo filename1
  filename2 = "#{root}/socket_file"
  UNIXServer.new filename2
  @files = [filename1, filename2]
end

def create_special_files_in_dir root = @tmpdir
  @tmpdirs << root
  @dir = root + '/dir'
  FileUtils.mkdir_p @dir
  filename1 = "#{@dir}/pipe_file"
  File.mkfifo filename1
  filename2 = "#{@dir}/socket_file"
  UNIXServer.new filename2
  @files = [filename1, filename2]
end

def create_special_files_in_dir_without_write_permission root = @tmpdir
  create_special_files_in_dir
  File.chmod 0555, @dir
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
  @non_empty_dirs = %w(a b).map {|i|
    dir = "#{root}/non_empty_dir_#{i}"
    FileUtils.mkdir(dir).tap {|dirs|
      @all_files_in_non_empty_dirs.concat FileUtils.touch "#{dirs.first}/file"
    }
  }.flatten
end

def create_deep_directory_tree root = @tmpdir
  @tmpdirs << root
  dirs = %w(a b c).to_a
  FileUtils.mkdir_p root + '/' + dirs.join('/')
  @tree_root = root + '/a'
  @all_dirs = Pathname(@tree_root).ascend_tree.map(&:to_s)
end

def create_hierarchical_dirs root = @tmpdir
  @tmpdirs << root
  @hierachical_files, @hierachical_dirs, @all_files_in_hierachical_dirs = [], [], [[], []]
  %w(a b).each_with_index {|i0, i|
    dir = "#{root}/hierachical_dir_#{i0}"
    FileUtils.mkdir(dir).tap {|dirs1|
      %w(a b).each {|i1|
        @all_files_in_hierachical_dirs[i].concat FileUtils.mkdir("#{dirs1.first}/dir_#{i1}").tap { |dirs2|
          %w(a b).each {|i2|
            @all_files_in_hierachical_dirs[i].concat FileUtils.mkdir("#{dirs2.first}/dir_#{i2}").tap { |dirs3|
              %w(a b).each {|i3|
                @all_files_in_hierachical_dirs[i].concat FileUtils.touch("#{dirs3.first}/file_#{i3}")
              }
            }
            @all_files_in_hierachical_dirs[i].concat FileUtils.touch("#{dirs2.first}/file_#{i2}")
          }
        }
        @all_files_in_hierachical_dirs[i].concat FileUtils.touch("#{dirs1.first}/file_#{i1}")
      }
      @hierachical_dirs.concat dirs1
      @all_files_in_hierachical_dirs[i].concat dirs1
    }

    @hierachical_files = FileUtils.touch("#{root}/file_#{i0}")
  }
end

def create_files_with_continuous_names root = @tmpdir
  @tmpdirs << root
  @dir = FileUtils.mkdir("#{root}/dir")[0]
  @files = []
  @files.concat FileUtils.touch("#{@dir}/file_1")
  @files.concat FileUtils.touch("#{@dir}/file_12")
  @files.concat FileUtils.touch("#{@dir}/file_123")
  @files.concat FileUtils.touch("#{@dir}/file_1234")
  @files.tree_order
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
