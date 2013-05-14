$: << File.expand_path(File.dirname(__FILE__))
require 'spec_helper'

describe 'test `rm`' do
  before(:each) do
    root = Dir.mktmpdir
    @files = (1..5).map {|i|
      file = "#{root}/file_#{i}"
      FileUtils.touch file
    }.flatten
  end

  it 'should delete all files' do
    stdout, stderr = rm(*@files)
    stdout.should be_nil
    stderr.should be_nil
    @files.each {|f| f.should_not be_exists}
  end

  it 'should skip not existed files' do
    @not_existed_files = @files.map {|f| f + '_' }
    @all_files = @files + @not_existed_files
    stdout, stderr = rm(*@all_files)
    stdout.should be_nil
    @not_existed_files.each {|f| stderr.should =~ /rm: #{f}: No such file or directory\n/ }
    @files.each {|f| f.should_not be_exists}
  end
end

describe 'test `rm -v`' do
  before(:each) do
    root = Dir.mktmpdir
    @files = (1..5).map {|i|
      file = "#{root}/file_#{i}"
      FileUtils.touch file
    }.flatten
  end

  it 'should delete all files' do
    stdout, stderr = rm('-v', *@files)
    @files.each {|f| stdout.should =~ /#{f}\n/ }
    stderr.should be_nil
    @files.each {|f| f.should_not be_exists}
  end

  it 'should skip not existed files' do
    @not_existed_files = @files.map {|f| f + '_' }
    @all_files = (@files + @not_existed_files).disorder
    stdout, stderr = rm('-v', *@all_files)
    @files.each {|f| stdout.should =~ /#{f}\n/ }
    @not_existed_files.each {|f| stderr.should =~ /rm: #{f}: No such file or directory\n/ }
    @files.each {|f| f.should_not be_exists}
  end
end

describe 'test `rm -d`' do
  before(:each) do
    root = Dir.mktmpdir
    @files = (1..5).map {|i|
      file = "#{root}/file_#{i}"
      FileUtils.touch file
    }.flatten
    @empty_dirs = ('a'..'e').map {|i|
      dir = "#{root}/empty_dir_#{i}"
      FileUtils.mkdir dir
    }.flatten
    @not_empty_dirs = ('f'..'j').map {|i|
      dir = "#{root}/empty_dir_#{i}"
      FileUtils.mkdir(dir).tap {|tap|
        FileUtils.touch "#{dir}/file"
      }
    }.flatten
  end

  it 'should add -d if try to rm a directory' do
    @dirs = (@empty_dirs + @not_empty_dirs).disorder
    @all_files = (@files + @dirs).disorder
    stdout, stderr = rm(*@all_files)
    stdout.should be_nil
    @dirs.each {|f| stderr.should =~ /rm: #{f}: is a directory\n/ }
    @files.each {|f| f.should_not be_exists}
    @dirs.each {|f| f.should be_exists}
  end

  it 'can\'t rm a directory which is not empty ever add -d' do
    @enable_to_delete = (@files + @empty_dirs).disorder
    @all_files = (@enable_to_delete + @not_empty_dirs).disorder
    stdout, stderr = rm('-d', *@all_files)
    @not_empty_dirs.each {|f| stderr.should =~ /rm: #{f}: Directory not empty\n/ }
    @enable_to_delete.each {|f| f.should_not be_exists}
    @not_empty_dirs.each {|f| f.should be_exists}
  end
end