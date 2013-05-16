$: << File.expand_path(File.dirname(__FILE__))
$: << File.expand_path(File.dirname(__FILE__) + '/lib')
require 'spec_helper'
require 'array_tree_order'

describe 'test `rm`' do
  before(:each) do
    create_files
    create_empty_dirs
  end

  it 'should delete all files' do
    stdout, stderr = rm(*@files)
    stdout.gets.should be_nil
    stderr.gets.should be_nil
    @files.each {|f| f.should_not be_existed }
  end

  it 'should skip not existed files' do
    @not_existed_files = @files.map {|f| f + '_' }
    @all_files = @files + @not_existed_files
    stdout, stderr = rm(*@all_files)
    stdout.gets.should be_nil
    @not_existed_files.each {|f| stderr.gets.should == "rm: #{f}: No such file or directory\n" }
    @files.each {|f| f.should_not be_existed }
  end

  it 'should add -d if try to rm a directory' do
    @dirs = @empty_dirs.disorder
    @all_files = (@files + @dirs).disorder
    stdout, stderr = rm(*@all_files)
    stdout.gets.should be_nil
    stderr = stderr.gets nil
    @dirs.each {|f| stderr.should =~ /rm: #{f}: is a directory\n/ }
    @files.each {|f| f.should_not be_existed }
    @dirs.each {|f| f.should be_existed }
  end
end

describe 'test `rm -v`' do
  before(:each) do
    create_files
  end

  it 'should delete all files' do
    stdout, stderr = rm('-v', *@files)
    @files.each {|f| stdout.gets.should == "#{f}\n" }
    stderr.gets.should be_nil
    @files.each {|f| f.should_not be_existed }
  end

  it 'should skip not existed files' do
    @not_existed_files = @files.map {|f| f + '_' }
    @all_files = (@files + @not_existed_files).disorder
    stdout, stderr = rm('-v', *@all_files)
    stdout = stdout.gets nil
    stderr = stderr.gets nil
    @files.each {|f| stdout.should =~ /#{f}\n/ }
    @not_existed_files.each {|f| stderr.should =~ /rm: #{f}: No such file or directory\n/ }
    @files.each {|f| f.should_not be_existed }
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
    stdout.gets.should be_nil
    stderr.gets.should be_nil
    @all_files.each {|f| f.should_not be_existed }
  end

  it 'can\'t rm a directory which is not empty ever add -d' do
    @enable_to_delete = (@files + @empty_dirs).disorder
    @all_files = (@enable_to_delete + @non_empty_dirs).disorder
    stdout, stderr = rm('-d', *@all_files)
    stdout.gets.should be_nil
    stderr = stderr.gets nil
    @non_empty_dirs.each {|f| stderr.should =~ /rm: #{f}: Directory not empty\n/ }
    @enable_to_delete.each {|f| f.should_not be_existed }
    @non_empty_dirs.each {|f| f.should be_existed }
  end
end

describe 'test `rm -r`' do
  before(:each) do
    create_hierarchical_dirs
  end

  it 'can rm all files in a directory' do
    @all_files = @hierachical_files.disorder
    stdout, stderr = rm('-r', @all_files)
    stdout.gets.should be_nil
    stderr.gets.should be_nil
    @all_files.each {|f| f.should_not be_existed }
  end

  it 'can print each files\' paths when rm all files in a directory' do
    @all_files = @hierachical_files.disorder
    stdout, stderr = rm('-rv', @all_files)
    stderr.gets.should be_nil
    @all_files_in_hierachical_files.each {|f| stdout =~ /#{f}\n/ }
    @all_files.each {|f| f.should_not be_existed }
  end
end

describe 'to delete symbolic links' do
  context 'to delete symbolic links to files' do
    before(:each) do
      create_symbolic_links_to_files
    end

    it 'can rm a symbolic link if the path isn\'t end with "/"' do
      stdout, stderr = rm('-v', *@links_to_files)
      stderr.gets.should be_nil
      @links_to_files.each {|f| stdout.gets.should == "#{f}\n" }
      @links_to_files.each {|f| f.should_not be_existed }
      @files.each {|f| f.should be_existed }
    end

    it 'can follow a symbolic link if the path is end with "/"' do
      @params = @links_to_files.map {|f| f + '/'}
      stdout, stderr = rm('-v', *@params)
      stderr.gets.should be_nil
      @params.each {|f| stdout.gets.should == "#{f}\n" }
      @links_to_files.each {|f| f.should be_existed }
      @files.each {|f| f.should_not be_existed }
    end
  end

  context 'to delete symbolic links to directories' do
    before(:each) do
      create_symbolic_links_to_dirs
    end

    it 'can rm a symbolic link if the path isn\'t end with "/"' do
      stdout, stderr = rm('-vr', *@links_to_dirs)
      stderr.gets.should be_nil
      @links_to_dirs.each {|f| stdout.gets.should == "#{f}\n" }
      @links_to_dirs.each {|f| f.should_not be_existed }
      @all_files_in_non_empty_dirs.each {|f| f.should be_existed }
    end

    it 'can follow a symbolic link if the path is end with "/"' do
      @params = @links_to_dirs.map {|f| f + '/'}
      @output_files = @params.map {|f| Dir[f + '/**/**'] }.flatten
      stdout, stderr = rm('-vr', *@params)
      stderr.gets.should be_nil
      @output_files.each {|f| stdout.gets.should == "#{f}\n" }
      @links_to_dirs.each {|f| f.should be_existed }
      @non_empty_dirs.each {|f| f.should_not be_existed }
    end
  end

  context 'to delete broken symbolic links' do
    before(:each) do
      create_broken_symbolic_links
    end

    it 'can rm a broken symbolic link if the path isn\'t end with "/"' do
      stdout, stderr = rm('-v', *@broken_links)
      stderr.gets.should be_nil
      @broken_links.each {|f| stdout.gets.should == "#{f}\n" }
      @broken_links.each {|f| f.should_not be_existed }
    end

    it 'can\'t find target file if the path isn\'t end with "/"' do
      @params = @broken_links.map {|f| f + '/'}
      stdout, stderr = rm('-v', *@params)
      stdout.gets.should be_nil
      @params.each {|f| stderr.gets.should == "rm: #{f}: No such file or directory\n"}
      @broken_links.each {|f| f.should be_existed }
    end
  end

  context 'to delete ring symbolic links' do
    before(:each) do
      create_ring_symbolic_links
    end

    it 'can rm a broken symbolic link if the path isn\'t end with "/"' do
      stdout, stderr = rm('-v', @ring_links.last)
      stdout.gets.should == @ring_links.last + "\n"
      stderr.gets.should be_nil
      @ring_links.pop.should_not be_existed
      @ring_links.each {|f| f.should be_existed }
    end

    it 'can\'t find target file if the path isn\'t end with "/"' do
      stdout, stderr = rm('-v', @ring_links.first + '/')
      stdout.gets.should == @ring_links.first + "/\n"
      stderr.gets.should be_nil
      @ring_links.pop.should_not be_existed
      @ring_links.each {|f| f.should be_existed }
    end
  end
end

describe 'test `rm -i`' do
  context 'to delete files with confirmation' do
    before(:each) do
      create_files
      create_empty_dirs
    end

    it 'should delete all files' do
      stdin, stdout, stderr = rm_i('-v', *@files)
      @files.each {|f|
        stderr.gets('? ').should == "remove #{f}? "
        stdin.puts 'y'
      }
      @files.each {|f| stdout.gets.should == "#{f}\n" }
      @files.each {|f| f.should_not be_existed }
    end

    it 'should skip not existed files' do
      @not_existed_files = @files.map {|f| f + '_' }
      @all_files = @files + @not_existed_files
      stdin, stdout, stderr = rm_i('-iv', *@all_files)
      @not_existed_files.each {|f| stderr.gets.should == "rm: #{f}: No such file or directory\n" }

      @files.each {|f|
        stderr.gets('? ').should == "remove #{f}? "
        stdin.puts 'y'
      }
      @files.each {|f| stdout.gets.should == "#{f}\n" }
      @files.each {|f| f.should_not be_existed }
    end

    it 'should add -d if try to rm a directory' do
      @all_files = @files + @empty_dirs
      stdin, stdout, stderr = rm_i('-v', *@all_files)
      @empty_dirs.each {|f| stderr.gets.should == "rm: #{f}: is a directory\n" }

      @files.each {|f|
        stderr.gets('? ').should == "remove #{f}? "
        stdin.puts 'y'
      }
      @files.each {|f| stdout.gets.should == "#{f}\n" }
      @files.each {|f| f.should_not be_existed }
      @empty_dirs.each {|f| f.should be_existed }
    end
  end

  context 'to delete empty directories with confirmation' do
    before(:each) do
      create_files
      create_empty_dirs
      create_non_empty_dirs
    end

    it 'should rm empty directories' do
      @all_files = @empty_dirs + @files
      stdin, stdout, stderr = rm_i('-vd', *@all_files)
      @all_files.each { |f|
        stderr.gets('? ').should == "remove #{f}? "
        stdin.puts 'y'
      }
      @all_files.each {|f| stdout.gets.should == "#{f}\n" }
      @all_files.each {|f| f.should_not be_existed }
    end

    it 'shouldn\'t rm anything without confirmation' do
      @all_files = @empty_dirs + @files
      stdin, stdout, stderr = rm_i('-vd', *@all_files)
      @all_files.each { |f|
        stderr.gets('? ').should == "remove #{f}? "
        stdin.puts 'n'
      }
      stdout.gets(nil).should be_nil
      @all_files.each {|f| f.should be_existed }
    end

    it 'can\'t rm a directory which is not empty ever add -d' do
      @enable_to_delete = @empty_dirs + @files
      @all_files = @enable_to_delete + @non_empty_dirs
      stdin, stdout, stderr = rm_i('-vd', *@all_files)
      @non_empty_dirs.each {|f| stderr.gets.should == "rm: #{f}: Directory not empty\n" }
      @enable_to_delete.each { |f|
        stderr.gets('? ').should == "remove #{f}? "
        stdin.puts 'y'
      }
      @enable_to_delete.each {|f| stdout.gets.should == "#{f}\n" }
      @enable_to_delete.each {|f| f.should_not be_existed }
      @non_empty_dirs.each {|f| f.should be_existed }
    end
  end

  context 'to delete hierarchical directories with confirmation' do
    before(:each) do
      create_hierarchical_dirs
    end

    it 'can rm all files in a directory with confirmation' do
      @all_files = @hierachical_files
      @deleted_files = []
      stdin, stdout, stderr = rm_i('-rv', @all_files)
      @all_files_in_hierachical_files.tree_order(true).each {|f|
        stderr.gets('? ').should == if File.directory? f
          "examine files in directory #{f}? "
        else
          @deleted_files << f
          "remove #{f}? "
        end
        stdin.puts 'y'
      }
      @all_files_in_hierachical_files.select {|f| File.directory? f }.tree_order.each {|f|
        @deleted_files << f
        stderr.gets('? ').should == "remove #{f}? "
        stdin.puts 'y'
      }

       @deleted_files.each { |f|
        stdout.gets.should == "#{f}\n"
      }
      @all_files.each {|f| f.should_not be_existed }
    end
  end
end