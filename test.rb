$: << File.expand_path(File.dirname(__FILE__))
require 'spec_helper'

describe 'test `rm`' do
  before(:each) do
    create_files
    create_empty_dirs
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

  it 'should add -d if try to rm a directory' do
    @dirs = @empty_dirs.disorder
    @all_files = (@files + @dirs).disorder
    stdout, stderr = rm(*@all_files)
    stdout.should be_nil
    @dirs.each {|f| stderr.should =~ /rm: #{f}: is a directory\n/ }
    @files.each {|f| f.should_not be_exists}
    @dirs.each {|f| f.should be_exists}
  end
end

describe 'test `rm -v`' do
  before(:each) do
    create_files
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
    create_files
    create_empty_dirs
    create_non_empty_dirs
  end

  it 'can rm empty directories' do
    @all_files = (@files + @empty_dirs).disorder
    stdout, stderr = rm('-d', *@all_files)
    stdout.should be_nil
    stderr.should be_nil
    @all_files.each {|f| f.should_not be_exists}
  end

  it 'can\'t rm a directory which is not empty ever add -d' do
    @enable_to_delete = (@files + @empty_dirs).disorder
    @all_files = (@enable_to_delete + @non_empty_dirs).disorder
    stdout, stderr = rm('-d', *@all_files)
    @non_empty_dirs.each {|f| stderr.should =~ /rm: #{f}: Directory not empty\n/ }
    @enable_to_delete.each {|f| f.should_not be_exists}
    @non_empty_dirs.each {|f| f.should be_exists}
  end
end