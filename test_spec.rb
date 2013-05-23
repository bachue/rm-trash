$: << File.expand_path(File.dirname(__FILE__))
$: << File.expand_path(File.dirname(__FILE__) + '/lib')
require 'spec_helper'

describe 'test `rm`' do
  before(:each) do
    create_files
    create_empty_dirs
  end

  it 'should delete all files' do
    _, stdout, stderr = rm(*@files)
    stdout.gets.should be_nil
    stderr.gets.should be_nil
    @files.each {|f| f.should_not be_existed }
  end

  it 'should skip not existed files' do
    @not_existed_files = @files.map {|f| f + '_' }
    @all_files = @files + @not_existed_files
    _, stdout, stderr = rm(*@all_files)
    stdout.gets.should be_nil
    @not_existed_files.each {|f| stderr.gets.should == "rm: #{f}: No such file or directory\n" }
    @files.each {|f| f.should_not be_existed }
  end

  it 'should add -d if try to rm a directory' do
    @dirs = @empty_dirs.disorder
    @all_files = (@files + @dirs).disorder
    _, stdout, stderr = rm(*@all_files)
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
    _, stdout, stderr = rm('-v', *@files)
    @files.each {|f| stdout.gets.should == "#{f}\n" }
    stderr.gets.should be_nil
    @files.each {|f| f.should_not be_existed }
  end

  it 'should skip not existed files' do
    @not_existed_files = @files.map {|f| f + '_' }
    @all_files = (@files + @not_existed_files).disorder
    _, stdout, stderr = rm('-v', *@all_files)
    stdout = stdout.gets nil
    stderr = stderr.gets nil
    @files.each {|f| stdout.should =~ /#{f}\n/ }
    @not_existed_files.each {|f| stderr.should =~ /rm: #{f}: No such file or directory\n/ }
    @files.each {|f| f.should_not be_existed }
  end

  it 'cannot delete file if the parameter it end with "/"' do
    @files_with_slash = @files.map {|f| f + '/' }
    _, stdout, stderr = rm('-v', *@files_with_slash)
    stdout.gets.should be_nil
    @files_with_slash.each {|f| stderr.gets.should =~ /rm: #{f}: Not a directory\n/ }
    @files.each {|f| f.should be_existed }
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
    _, stdout, stderr = rm('-d', *@all_files)
    stdout.gets.should be_nil
    stderr.gets.should be_nil
    @all_files.each {|f| f.should_not be_existed }
  end

  it 'can rm empty directories which are end with "/"' do
    @all_files = (@files + @empty_dirs.map {|f| f + '/'}).disorder
    _, stdout, stderr = rm('-d', *@all_files)
    stdout.gets.should be_nil
    stderr.gets.should be_nil
    @all_files.each {|f| f.should_not be_existed }
  end

  it 'can\'t rm a directory which is not empty ever add -d' do
    @enable_to_delete = (@files + @empty_dirs).disorder
    @all_files = (@enable_to_delete + @non_empty_dirs).disorder
    _, stdout, stderr = rm('-d', *@all_files)
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
    _, stdout, stderr = rm('-r', @all_files)
    stdout.gets.should be_nil
    stderr.gets.should be_nil
    @all_files.each {|f| f.should_not be_existed }
  end

  it 'can rm all files in a directory which is end with "/"' do
    @all_files = @hierachical_files.map {|f| File.directory?(f) ? f + '/' : f}.disorder
    _, stdout, stderr = rm('-r', @all_files)
    stdout.gets.should be_nil
    stderr.gets.should be_nil
    @all_files.each {|f| f.should_not be_existed }
  end

  it 'can print each files\' paths when rm all files in a directory' do
    @all_files = @hierachical_files.disorder
    _, stdout, stderr = rm('-rv', @all_files)
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
      _, stdout, stderr = rm('-v', *@links_to_files)
      stderr.gets.should be_nil
      @links_to_files.each {|f| stdout.gets.should == "#{f}\n" }
      @links_to_files.each {|f| f.should_not be_existed }
      @files.each {|f| f.should be_existed }
    end

    it 'can follow a symbolic link if the path is end with "/"' do
      @params = @links_to_files.map {|f| f + '/'}
      _, stdout, stderr = rm('-v', *@params)
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
      _, stdout, stderr = rm('-vr', *@links_to_dirs)
      stderr.gets.should be_nil
      @links_to_dirs.each {|f| stdout.gets.should == "#{f}\n" }
      @links_to_dirs.each {|f| f.should_not be_existed }
      @all_files_in_non_empty_dirs.each {|f| f.should be_existed }
    end

    it 'can follow a symbolic link if the path is end with "/"' do
      @params = @links_to_dirs.map {|f| f + '/'}
      @output_files = @params.map {|f| Pathname(f).descend_tree }.flatten
      _, stdout, stderr = rm('-vr', *@params)
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
      _, stdout, stderr = rm('-v', *@broken_links)
      stderr.gets.should be_nil
      @broken_links.each {|f| stdout.gets.should == "#{f}\n" }
      @broken_links.each {|f| f.should_not be_existed }
    end

    it 'can\'t find target file if the path isn\'t end with "/"' do
      @params = @broken_links.map {|f| f + '/'}
      _, stdout, stderr = rm('-v', *@params)
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
      _, stdout, stderr = rm('-v', @ring_links.last)
      stdout.gets.should == @ring_links.last + "\n"
      stderr.gets.should be_nil
      @ring_links.pop.should_not be_existed
      @ring_links.each {|f| f.should be_existed }
    end

    it 'can\'t find target file if the path isn\'t end with "/"' do
      _, stdout, stderr = rm('-v', @ring_links.first + '/')
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
      stdin, stdout, stderr = rm('-iv', *@files)
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
      stdin, stdout, stderr = rm('-iv', *@all_files)
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
      stdin, stdout, stderr = rm('-iv', *@all_files)
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

  context 'to be rejected to delete file from a deep node' do
    before(:each) do
      create_deep_directory_tree
    end
    it 'should be rejected to delete all its parent nodes' do
      FileUtils.cd @tmpdir do
        stdin, stdout, stderr = rm('-ir', File.basename(@tree_root))
        stderr.gets('? ').should == "examine files in directory a? "
        stdin.puts 'y'
        stderr.gets('? ').should == "examine files in directory a/b? "
        stdin.puts 'y'
        stderr.gets('? ').should == "examine files in directory a/b/c? "
        stdin.puts 'n'
        stderr.gets('? ').should == "remove a/b? "
        stdin.puts 'y'
        stderr.gets.should == "rm: a/b: Directory not empty\n"
        stderr.gets('? ').should == "remove a? "
        stdin.puts 'y'
        stderr.gets.should == "rm: a: Directory not empty\n"
      end
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
      stdin, stdout, stderr = rm('-ivd', *@all_files)
      @all_files.each { |f|
        stderr.gets('? ').should == "remove #{f}? "
        stdin.puts 'y'
      }
      @all_files.each {|f| stdout.gets.should == "#{f}\n" }
      @all_files.each {|f| f.should_not be_existed }
    end

    it 'shouldn\'t rm anything without confirmation' do
      @all_files = @empty_dirs + @files
      stdin, stdout, stderr = rm('-ivd', *@all_files)
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
      stdin, stdout, stderr = rm('-ivd', *@all_files)
      @non_empty_dirs.each {|f| stderr.gets.should == "rm: #{f}: Directory not empty\n" }
      @enable_to_delete.each { |f|
        stderr.gets('? ').should == "remove #{f}? "
        stdin.puts 'y'
      }
      @enable_to_delete.each {|f| stdout.gets.should == "#{f}\n" }
      @enable_to_delete.each {|f| f.should_not be_existed }
      @non_empty_dirs.each {|f| f.should be_existed }
    end

    it 'should examine and then remove directories even it is empty' do
      stdin, stdout, stderr = rm('-irv', @empty_dirs)
      @empty_dirs.each {|f|
        stderr.gets('? ').should == "examine files in directory #{f}? "
        stdin.puts 'y'
      }
      @empty_dirs.each {|f|
        stderr.gets('? ').should == "remove #{f}? "
        stdin.puts 'y'
      }
      @empty_dirs.each {|f|
        stdout.gets.should == "#{f}\n"
      }
    end
  end

  context 'to delete hierarchical directories with confirmation' do
    before(:each) do
      create_hierarchical_dirs
    end

    it 'can rm all files in a directory with confirmation' do
      @all_files = @hierachical_files.tree_order
      @deleted_files = []
      stdin, stdout, stderr = rm('-irv', @all_files)
      @all_files_in_hierachical_files.select {|f| File.directory? f }.tree_order(true).each {|f|
        stderr.gets('? ').should == "examine files in directory #{f}? "
        stdin.puts 'y'
      }
      @all_files_in_hierachical_files.tree_order.each {|f|
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

  context 'won\'t allow user to delete "." or ".."' do
    before(:each) do
      create_files
    end

    it 'should reject to delete "."' do
      FileUtils.cd @tmpdir do
        @params = ['.', '*'].disorder
        _, stdout, stderr = rm('-v', *@params)
        stderr.gets.should == "rm: \".\" and \"..\" may not be removed\n"
        @files.each {|f| stdout.gets.should == "#{File.basename(f)}\n" }
        @files.each {|f| f.should_not be_existed }
      end
    end

    it 'should reject to delete ".."' do
      FileUtils.cd @tmpdir do
        @params = ['..', '*'].disorder
        _, stdout, stderr = rm('-v', *@params)
        stderr.gets.should == "rm: \".\" and \"..\" may not be removed\n"
        @files.each {|f| stdout.gets.should == "#{File.basename(f)}\n" }
        @files.each {|f| f.should_not be_existed }
      end
    end

    it 'should reject to delete "." and ".."' do
      FileUtils.cd @tmpdir do
        @params = ['.', '..', '*'].disorder
        _, stdout, stderr = rm('-v', *@params)
        stderr.gets.should == "rm: \".\" and \"..\" may not be removed\n"
        @files.each {|f| stdout.gets.should == "#{File.basename(f)}\n" }
        @files.each {|f| f.should_not be_existed }
      end
    end

    it 'shouldn\'t ask for delete "." or ".."' do
      FileUtils.cd @tmpdir do
        @params = ['.', '..', '*'].disorder
        stdin, stdout, stderr = rm('-iv', *@params)
        stderr.gets.should == "rm: \".\" and \"..\" may not be removed\n"
        @files.each {|f|
          stderr.gets('? ').should == "remove #{File.basename(f)}? "
          stdin.puts 'y'
        }
        @files.each {|f| stdout.gets.should == "#{File.basename(f)}\n" }
        @files.each {|f| f.should_not be_existed }
      end
    end
  end
end

describe 'test `rm -f`' do
  context 'to delete files without permission and -f' do
    before(:each) do
      create_hierarchical_dirs_without_write_permission
    end

    it 'should ask for your confirmation' do
      stdin, stdout, stderr = rm('-vr', @dir)
      @all_files_without_permission.each {|f|
        err = stderr.gets('? ')
        err.should start_with("override r--r--r--")
        err.should end_with("#{f}? ")
        stdin.puts 'y'
      }
      stderr.gets nil
      @all_files.each {|f| stdout.gets.should == "#{f}\n" }
      @all_files.each {|f| f.should_not be_existed }
    end

    it 'shouldn\'t delete files without your permission' do
      stdin, stdout, stderr = rm('-vr', @dir)
      @all_files_without_permission.each {|f|
        err = stderr.gets('? ')
        err.should start_with("override r--r--r--")
        err.should end_with("#{f}? ")
        if File.basename(f) == '1'
          stdin.puts 'y'
        else
          stdin.puts 'n'
        end
      }
      stderr.gets.should == "rm: #{@subdir}: Directory not empty\n"
      stderr.gets.should == "rm: #{@dir}: Directory not empty\n"
      groups = @all_files_without_permission.group_by {|f| File.basename(f) == '1' }
      groups[true].reverse.each {|f| stdout.gets.should == "#{f}\n" }
      groups[true].each {|f| f.should_not be_existed }
      groups[false].each {|f| f.should be_existed }
    end

    it 'shouldn\'t ask you with `rm -f`' do
      stdin, stdout, stderr = rm('-vrf', @dir)
      stderr.gets.should be_nil
      @all_files.each {|f| stdout.gets.should == "#{f}\n" }
      @all_files.each {|f| f.should_not be_existed }
    end

    it 'shouldn\'t ask you with `rm -f`' do
      unexisted_files = (@all_files_without_permission + [@subdir]).map {|f| f + '_' }
      stdin, stdout, stderr = rm('-vrf', *([@dir] + unexisted_files))
      stderr.gets.should be_nil
      @all_files.each {|f| stdout.gets.should == "#{f}\n" }
      @all_files.each {|f| f.should_not be_existed }
    end
  end
end

describe 'test `rm --rm`' do
  before(:each) do
    create_hierarchical_dirs
  end

  it 'can call rm from $path to delete all files recursively' do
    @all_files = @hierachical_files.disorder
    _, stdout, stderr = rm('--rm', '-rfv', @all_files)
    stderr.gets.should be_nil
    @all_files_in_hierachical_files.each {|f| stdout =~ /#{f}\n/ }
    @all_files.each {|f| f.should_not be_existed }
  end
end
