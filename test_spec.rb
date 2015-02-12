$: << File.expand_path(File.dirname(__FILE__))
$: << File.expand_path(File.dirname(__FILE__) + '/lib')
require 'spec_helper'

describe 'test `rm`' do
  before :each do
    create_files
    create_empty_dirs
  end

  it 'should delete all files' do
    _, stdout, stderr = rm @files
    stdout.gets.should be_nil
    stderr.gets.should be_nil
    @files.each {|f| f.should_not be_existed }
  end

  it 'should skip not existed files' do
    @not_existed_files = @files.map {|f| f + '_' }
    @all_files = @files + @not_existed_files
    _, stdout, stderr = rm @all_files
    stdout.gets.should be_nil
    @not_existed_files.each {|f| stderr.gets.should == "rm: #{f}: No such file or directory\n" }
    @files.each {|f| f.should_not be_existed }
  end

  it 'should add -d if try to rm a directory' do
    @dirs = @empty_dirs.disorder
    @all_files = (@files + @dirs).disorder
    _, stdout, stderr = rm @all_files
    stdout.gets.should be_nil
    stderr = stderr.gets nil
    @dirs.each {|f| stderr.should =~ /rm: #{f}: Is a directory\n/ }
    @files.each {|f| f.should_not be_existed }
    @dirs.each {|f| f.should be_existed }
  end
end

describe 'test `rm` files whose name' do
  context 'include quotes' do
    before :each do
      create_files_with_quote
    end

    it 'shoule delete all files' do
      _, stdout, stderr = rm @files
      stdout.gets.should be_nil
      stderr.gets.should be_nil
      @files.each {|f| f.should_not be_existed }
    end
  end

  context 'include non-ascii chars' do
    before :each do
      create_files_with_non_ascii_chars
    end

    it 'should delete all files' do
      _, stdout, stderr = rm @files
      stdout.gets.should be_nil
      stderr.gets.should be_nil
      @files.each {|f| f.should_not be_existed }
    end
  end

  context 'include non-ascii chars and quotes' do
    before :each do
     create_files_with_non_ascii_chars_and_quote
    end

    it 'should delete all files' do
      _, stdout, stderr = rm @files
      stdout.gets.should be_nil
      stderr.gets.should be_nil
      @files.each {|f| f.should_not be_existed }
    end
  end

  context 'include special files' do
    before :each do
      create_special_files
    end

    it 'should delete all files' do
      _, stdout, stderr = rm '-f', @files
      stdout.gets.should be_nil
      stderr.gets.should be_nil
      @files.each {|f| f.should_not be_existed }
    end

    it 'should delete all files with confirmation' do
      stdin, stdout, stderr = rm @files
      stderr.gets('? ').should == "cannot move fifo file #{@files[0]} to trash, delete it directly? "
      stdin.puts 'y'
      stderr.gets('? ').should == "cannot move socket file #{@files[1]} to trash, delete it directly? "
      stdin.puts 'y'
      stdout.gets.should be_nil
      @files.each {|f| f.should_not be_existed }
    end

    it 'should not delete files without confirmation' do
      stdin, stdout, stderr = rm @files
      stderr.gets('? ').should == "cannot move fifo file #{@files[0]} to trash, delete it directly? "
      stdin.puts 'n'
      stderr.gets('? ').should == "cannot move socket file #{@files[1]} to trash, delete it directly? "
      stdin.puts 'n'
      stdout.gets.should be_nil
      @files.each {|f| f.should be_existed }
    end
  end

  context 'include trashed files' do
    before :each do
      create_trashed_files
    end

    it 'should delete all trashed files' do
      _, stdout, stderr = rm '-f', @files
      stdout.gets.should be_nil
      stderr.gets.should be_nil
      @files.each {|f| f.should_not be_existed }
    end

    it 'should delete all trashed files with confirmation' do
      stdin, stdout, stderr = rm @files
      stderr.gets('? ').should == "cannot move trashed file #{@files[0]} to trash, delete it directly? "
      stdin.puts 'y'
      stderr.gets('? ').should == "cannot move trashed file #{@files[1]} to trash, delete it directly? "
      stdin.puts 'y'
      stdout.gets.should be_nil
      @files.each {|f| f.should_not be_existed }
    end

    it 'should not delete trashed files without confirmation' do
      stdin, stdout, stderr = rm @files
      stderr.gets('? ').should == "cannot move trashed file #{@files[0]} to trash, delete it directly? "
      stdin.puts 'n'
      stderr.gets('? ').should == "cannot move trashed file #{@files[1]} to trash, delete it directly? "
      stdin.puts 'n'
      stdout.gets.should be_nil
      @files.each {|f| f.should be_existed }
    end
  end
end

describe 'test `rm -v`' do
  context 'doesn\'t include special files' do
    before :each do
      create_files
    end

    it 'should delete all files' do
      _, stdout, stderr = rm '-v', @files
      @files.each {|f| stdout.gets.should == "#{f}\n" }
      stderr.gets.should be_nil
      @files.each {|f| f.should_not be_existed }
    end

    it 'should skip not existed files' do
      @not_existed_files = @files.map {|f| f + '_' }
      @all_files = (@files + @not_existed_files).disorder
      _, stdout, stderr = rm '-v', @all_files
      stdout = stdout.gets nil
      stderr = stderr.gets nil
      @files.each {|f| stdout.should =~ /#{f}\n/ }
      @not_existed_files.each {|f| stderr.should =~ /rm: #{f}: No such file or directory\n/ }
      @files.each {|f| f.should_not be_existed }
    end

    it 'cannot delete file if the parameter it end with "/"' do
      @files_with_slash = @files.map {|f| f + '/' }
      _, stdout, stderr = rm '-v', @files_with_slash
      stdout.gets.should be_nil
      @files_with_slash.each {|f| stderr.gets.should =~ /rm: #{f}: Not a directory\n/ }
      @files.each {|f| f.should be_existed }
    end
  end

  context 'include special files' do
    before :each do
      create_special_files
    end

    it 'should delete all files' do
      _, stdout, stderr = rm '-vf', @files
      @files.each {|f| stdout.gets.should == "#{f}\n" }
      stderr.gets.should be_nil
      @files.each {|f| f.should_not be_existed }
    end
  end

  context 'start with ~' do
    before :each do
      create_files_started_with_wave
    end

    it 'should delete all files' do
      _, stdout, stderr = Dir.chdir(@tmpdir) { rm '-v', @files }
      @files.each {|f| stdout.gets.should == "#{f}\n" }
      stderr.gets.should be_nil
      @files.each {|f| f.should_not be_existed }
    end
  end
end

describe 'test `rm -d`' do
  before :each do
    create_files
    create_empty_dirs
    create_non_empty_dirs
  end

  it 'can rm empty directories' do
    @all_files = (@files + @empty_dirs).disorder
    _, stdout, stderr = rm '-d', @all_files
    stdout.gets.should be_nil
    stderr.gets.should be_nil
    @all_files.each {|f| f.should_not be_existed }
  end

  it 'can rm empty directories which are end with "/"' do
    @all_files = (@files + @empty_dirs.map {|f| f + '/'}).disorder
    _, stdout, stderr = rm '-d', @all_files
    stdout.gets.should be_nil
    stderr.gets.should be_nil
    @all_files.each {|f| f.should_not be_existed }
  end

  it 'can\'t rm a directory which is not empty ever add -d' do
    @enable_to_delete = (@files + @empty_dirs).disorder
    @all_files = (@enable_to_delete + @non_empty_dirs).disorder
    _, stdout, stderr = rm '-d', @all_files
    stdout.gets.should be_nil
    stderr = stderr.gets nil
    @non_empty_dirs.each {|f| stderr.should =~ /rm: #{f}: Directory not empty\n/ }
    @enable_to_delete.each {|f| f.should_not be_existed }
    @non_empty_dirs.each {|f| f.should be_existed }
  end
end

describe 'test `rm -r`' do
  context 'doesn\'t include special files' do
    before :each do
      create_hierarchical_dirs
    end

    it 'can rm all files in a directory' do
      @all_files = @hierachical_files.disorder
      _, stdout, stderr = rm '-r', @all_files
      stdout.gets.should be_nil
      stderr.gets.should be_nil
      @all_files.each {|f| f.should_not be_existed }
    end

    it 'can rm all files in a directory which is end with "/"' do
      @all_files = @hierachical_files.map {|f| File.directory?(f) ? f + '/' : f}.disorder
      _, stdout, stderr = rm '-r', @all_files
      stdout.gets.should be_nil
      stderr.gets.should be_nil
      @all_files.each {|f| f.should_not be_existed }
    end

    it 'can print each files\' paths when rm all files in a directory' do
      @all_files = @hierachical_files.disorder
      _, stdout, stderr = rm '-rv', @all_files
      stderr.gets.should be_nil
      @all_files_in_hierachical_dirs.flatten.each {|f| stdout =~ /#{f}\n/ }
      @all_files.each {|f| f.should_not be_existed }
    end
  end

  context 'include special files' do
    before :each do
      create_special_files_in_dir
    end

    it 'can rm all special files in a directory with permission' do
      stdin, stdout, stderr = rm '-r', @dir
      stderr.gets('? ').should == "cannot move fifo file #{@files[0]} to trash, delete it directly? "
      stdin.puts 'y'
      stderr.gets('? ').should == "cannot move socket file #{@files[1]} to trash, delete it directly? "
      stdin.puts 'y'
      stdout.gets.should be_nil
      @dir.should_not be_existed
    end

    it 'can rm all special files in a directory by force' do
      stdin, stdout, stderr = rm '-rf', @dir
      stdout.gets.should be_nil
      stderr.gets.should be_nil
      @dir.should_not be_existed
    end

    it 'cannot rm special files without permission' do
      stdin, stdout, stderr = rm '-r', @dir
      stderr.gets('? ').should == "cannot move fifo file #{@files[0]} to trash, delete it directly? "
      stdin.puts 'n'
      stderr.gets('? ').should == "cannot move socket file #{@files[1]} to trash, delete it directly? "
      stdin.puts 'y'
      stderr.gets.should == "rm: #{@dir}: Directory not empty\n"
      stdout.gets.should be_nil
      @files[0].should be_existed
      @files[1].should_not be_existed
      @dir.should be_existed
    end
  end

  context 'include special files without write permission' do
    before :each do
      create_special_files_in_dir_without_write_permission
    end

    it 'cannot rm special files whatever with or without permission' do
      stdin, stdout, stderr = rm '-r', @dir
      stderr.gets('? ').should == "cannot move fifo file #{@files[0]} to trash, delete it directly? "
      stdin.puts 'n'
      stderr.gets('? ').should == "cannot move socket file #{@files[1]} to trash, delete it directly? "
      stdin.puts 'y'
      stderr.gets.should == "rm: #{@files[1]}: Permission denied\n"
      @files.each {|f| f.should be_existed }
      @dir.should be_existed
    end

    it 'cannot rm special files even by force' do
      stdin, stdout, stderr = rm '-rf', @dir
      @files.each {|f| stderr.gets.should == "rm: #{f}: Permission denied\n" }
      @files.each {|f| f.should be_existed }
      @dir.should be_existed
    end
  end
end

describe 'to delete symbolic links' do
  context 'to delete symbolic links to files' do
    before :each do
      create_symbolic_links_to_files
    end

    it 'can rm a symbolic link if the path isn\'t end with "/"' do
      _, stdout, stderr = rm '-v', @links_to_files
      stderr.gets.should be_nil
      @links_to_files.each {|f| stdout.gets.should == "#{f}\n" }
      @links_to_files.each {|f| f.should_not be_existed }
      @files.each {|f| f.should be_existed }
    end

    it 'can follow a symbolic link if the path is end with "/"' do
      @params = @links_to_files.map {|f| f + '/'}
      _, stdout, stderr = rm '-v', @params
      stderr.gets.should be_nil
      @params.each {|f| stdout.gets.should == "#{f}\n" }
      @links_to_files.each {|f| f.should be_existed }
      @files.each {|f| f.should_not be_existed }
    end
  end

  context 'to delete symbolic links to directories' do
    before :each do
      create_symbolic_links_to_dirs
    end

    it 'can rm a symbolic link if the path isn\'t end with "/"' do
      _, stdout, stderr = rm '-vr', @links_to_dirs
      stderr.gets.should be_nil
      @links_to_dirs.each {|f| stdout.gets.should == "#{f}\n" }
      @links_to_dirs.each {|f| f.should_not be_existed }
      @all_files_in_non_empty_dirs.each {|f| f.should be_existed }
    end

    it 'can follow a symbolic link if the path is end with "/"' do
      @params = @links_to_dirs.map {|f| f + '/'}
      @output_files = @params.map {|f| Pathname(f).descend_tree.map(&:to_s) }.flatten
      _, stdout, stderr = rm '-vr', @params
      stderr.gets.should be_nil
      @output_files.each {|f| stdout.gets.should == "#{f}\n" }
      @links_to_dirs.each {|f| f.should be_existed }
      @non_empty_dirs.each {|f| f.should_not be_existed }
    end

    it 'can delete a symbolic link and subfiles in the directories the links point to' do
      @params = @links_to_dirs.map {|f| f + '/'}
      @output_files = @params.map {|f| Pathname(f).descend_tree.map(&:to_s) }.flatten
      _, stdout, stderr = rm '-vr', [@params + @non_empty_dirs + @all_files_in_non_empty_dirs]
      stderr.gets.should be_nil
      @output_files.each {|f| stdout.gets.should == "#{f}\n" }
      @links_to_dirs.each {|f| f.should be_existed }
      @non_empty_dirs.each {|f| f.should_not be_existed }
      @all_files_in_non_empty_dirs.each {|f| f.should_not be_existed }
    end
  end

  context 'to delete broken symbolic links' do
    before :each do
      create_broken_symbolic_links
    end

    it 'can rm a broken symbolic link if the path isn\'t end with "/"' do
      _, stdout, stderr = rm '-v', @broken_links
      stderr.gets.should be_nil
      @broken_links.each {|f| stdout.gets.should == "#{f}\n" }
      @broken_links.each {|f| f.should_not be_existed }
    end

    it 'can\'t find target file if the path isn\'t end with "/"' do
      @params = @broken_links.map {|f| f + '/'}
      _, stdout, stderr = rm '-v', @params
      stdout.gets.should be_nil
      @params.each {|f| stderr.gets.should == "rm: #{f}: No such file or directory\n"}
      @broken_links.each {|f| f.should be_existed }
    end
  end

  context 'to delete ring symbolic links' do
    before :each do
      create_ring_symbolic_links
    end

    it 'can rm a broken symbolic link if the path isn\'t end with "/"' do
      _, stdout, stderr = rm '-v', @ring_links.last
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
    before :each do
      create_files
      create_empty_dirs
    end

    it 'should delete all files' do
      stdin, stdout, stderr = rm '-iv', @files
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
      stdin, stdout, stderr = rm '-iv', @all_files
      @all_files.each {|f|
        if f.end_with? '_'
          stderr.gets.should == "rm: #{f}: No such file or directory\n"
        else
          stderr.gets('? ').should == "remove #{f}? "
          stdin.puts 'y'
        end
      }
      @files.each {|f| stdout.gets.should == "#{f}\n" }
      @files.each {|f| f.should_not be_existed }
    end

    it 'should add -d if try to rm a directory' do
      @all_files = @files + @empty_dirs
      stdin, stdout, stderr = rm '-iv', @all_files

      @files.each {|f|
        if File.directory? f
          stderr.gets.should == "rm: #{f}: Is a directory\n"
        else
          stderr.gets('? ').should == "remove #{f}? "
          stdin.puts 'y'
        end
      }
      @files.each {|f| stdout.gets.should == "#{f}\n" }
      @files.each {|f| f.should_not be_existed }
      @empty_dirs.each {|f| f.should be_existed }
    end
  end

  context 'to be rejected to delete file from a deep node' do
    before :each do
      create_deep_directory_tree
    end
    it 'should be rejected to delete all its parent nodes' do
      FileUtils.cd @tmpdir do
        stdin, stdout, stderr = rm '-ir', File.basename(@tree_root)
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
    before :each do
      create_files
      create_empty_dirs
      create_non_empty_dirs
    end

    it 'should rm empty directories' do
      @all_files = @empty_dirs + @files
      stdin, stdout, stderr = rm '-ivd', @all_files
      @all_files.each { |f|
        stderr.gets('? ').should == "remove #{f}? "
        stdin.puts 'y'
      }
      @all_files.each {|f| stdout.gets.should == "#{f}\n" }
      @all_files.each {|f| f.should_not be_existed }
    end

    it 'shouldn\'t rm anything without confirmation' do
      @all_files = @empty_dirs + @files
      stdin, stdout, stderr = rm '-ivd', @all_files
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
      stdin, stdout, stderr = rm '-ivd', @all_files

      @enable_to_delete.each { |f|
        if Pathname(f).directory? && Pathname(f).has_children?
          stderr.gets.should == "rm: #{f}: Directory not empty\n"
        else
          stderr.gets('? ').should == "remove #{f}? "
          stdin.puts 'y'
        end
      }
      @enable_to_delete.each {|f| stdout.gets.should == "#{f}\n" }
      @enable_to_delete.each {|f| f.should_not be_existed }
      @non_empty_dirs.each {|f| f.should be_existed }
    end

    it 'should examine and then remove directories even it is empty' do
      stdin, stdout, stderr = rm '-irv', @empty_dirs
      @empty_dirs.each {|f|
        stderr.gets('? ').should == "examine files in directory #{f}? "
        stdin.puts 'y'
        stderr.gets('? ').should == "remove #{f}? "
        stdin.puts 'y'
      }
      @empty_dirs.each {|f|
        stdout.gets.should == "#{f}\n"
      }
    end
  end

  context 'to delete files with continuous names in a directory' do
    before :each do
      create_files_with_continuous_names
    end

    it 'can rm all files with confirmation' do
      stdin, stdout, stderr = rm '-irv', @dir
      stderr.gets('? ').should == "examine files in directory #{@dir}? "
      stdin.puts 'y'
      stderr.gets('? ').should == "remove #{@files[0]}? "
      stdin.puts 'n'
      stderr.gets('? ').should == "remove #{@files[1]}? "
      stdin.puts 'y'
      stderr.gets('? ').should == "remove #{@files[2]}? "
      stdin.puts 'n'
      stderr.gets('? ').should == "remove #{@files[3]}? "
      stdin.puts 'y'
      stderr.gets('? ').should == "remove #{@dir}? "
      stdin.puts 'y'
      stderr.gets.should == "rm: #{@dir}: Directory not empty\n"
      [@files[1], @files[3]].each {|f| stdout.gets.should == "#{f}\n" }
      [@files[1], @files[3]].each {|f| f.should_not be_existed }
      [@files[0], @files[2], @dir].each {|f| f.should be_existed }
    end
  end

  context 'to delete hierarchical directories with confirmation' do
    before :each do
      create_hierarchical_dirs
    end

    it 'can rm all files in a directory with confirmation' do
      @all_files = (@hierachical_files + @hierachical_dirs).tree_order
      @deleted_files = []
      stdin, stdout, stderr = rm '-irv', @all_files
      @hierachical_files.each {|f|
        @deleted_files << f
        stderr.gets('? ').should == "remove #{f}? "
        stdin.puts 'y'
      }
      @all_files_in_hierachical_dirs.each_with_index do |dirs, _|
        dirs.select {|f| File.directory? f }.tree_order(true).each {|f|
          stderr.gets('? ').should == "examine files in directory #{f}? "
          stdin.puts 'y'
        }
        dirs.tree_order.each {|f|
          @deleted_files << f
          stderr.gets('? ').should == "remove #{f}? "
          stdin.puts 'y'
        }
      end

      @deleted_files.each { |f|
        stdout.gets.should == "#{f}\n"
      }
      @all_files.each {|f| f.should_not be_existed }
    end
  end

  context 'won\'t allow user to delete "." or ".."' do
    before :each do
      create_files
    end

    it 'should reject to delete "."' do
      FileUtils.cd @tmpdir do
        @params = @files.insert_wherever '.'
        _, stdout, stderr = rm '-v', @params
        stderr.gets.should == "rm: \".\" and \"..\" may not be removed\n"
        @files.each {|f| stdout.gets.should == "#{f}\n" }
        @files.each {|f| f.should_not be_existed }
      end
    end

    it 'should reject to delete ".."' do
      FileUtils.cd @tmpdir do
        @params = @files.insert_wherever '.'
        _, stdout, stderr = rm '-v', @params
        stderr.gets.should == "rm: \".\" and \"..\" may not be removed\n"
        @files.each {|f| stdout.gets.should == "#{f}\n" }
        @files.each {|f| f.should_not be_existed }
      end
    end

    it 'should reject to delete "." and ".."' do
      FileUtils.cd @tmpdir do
        @params = @files.insert_wherever('.').insert_wherever('..')
        _, stdout, stderr = rm '-v', @params
        stderr.gets.should == "rm: \".\" and \"..\" may not be removed\n"
        @files.each {|f| stdout.gets.should == "#{f}\n" }
        @files.each {|f| f.should_not be_existed }
      end
    end

    it 'shouldn\'t ask for delete "." or ".."' do
      FileUtils.cd @tmpdir do
        @params = @files.insert_wherever('.').insert_wherever('..')
        stdin, stdout, stderr = rm '-iv', @params
        stderr.gets.should == "rm: \".\" and \"..\" may not be removed\n"
        @files.each {|f|
          stderr.gets('? ').should == "remove #{f}? "
          stdin.puts 'y'
        }
        @files.each {|f| stdout.gets.should == "#{f}\n" }
        @files.each {|f| f.should_not be_existed }
      end
    end
  end

  context 'won\'t allow user to delete "/." or "/.."' do
    before :each do
      create_non_empty_dirs
    end

    it 'should reject to delete "."' do
      FileUtils.cd @tmpdir do
        @params = ['non_empty_dir_a/.', 'non_empty_dir_b/.']
        _, stdout, stderr = rm '-v', @params
        stderr.gets.should == "rm: \".\" and \"..\" may not be removed\n"
        @non_empty_dirs.each {|f| f.should be_existed }
      end
    end

    it 'should reject to delete ".."' do
      FileUtils.cd @tmpdir do
        @params = ['non_empty_dir_a/..', 'non_empty_dir_b/..']
        _, stdout, stderr = rm '-v', @params
        stderr.gets.should == "rm: \".\" and \"..\" may not be removed\n"
        @non_empty_dirs.each {|f| f.should be_existed }
      end
    end
  end

  context 'still allow user to delete "../"' do
    before :each do
      create_non_empty_dirs
    end

    it 'should reject to delete ".."' do
      FileUtils.cd "#{@tmpdir}/non_empty_dir_a" do
        _, stdout, stderr = rm '-vr', '../'
        stdout.gets.should == "..//non_empty_dir_a/file\n"
        stdout.gets.should == "..//non_empty_dir_a\n"
        stdout.gets.should == "..//non_empty_dir_b/file\n"
        stdout.gets.should == "..//non_empty_dir_b\n"
        stdout.gets.should == "../\n"
        "#{@tmpdir}/non_empty_dir_a".should_not be_existed
        "#{@tmpdir}/non_empty_dir_b".should_not be_existed
      end
    end

    it 'should reject to delete "/.."' do
      FileUtils.cd "#{@tmpdir}/non_empty_dir_a" do
        _, stdout, stderr = rm '-vr', '../non_empty_dir_b/../'
        stdout.gets.should == "../non_empty_dir_b/..//non_empty_dir_a/file\n"
        stdout.gets.should == "../non_empty_dir_b/..//non_empty_dir_a\n"
        stdout.gets.should == "../non_empty_dir_b/..//non_empty_dir_b/file\n"
        stdout.gets.should == "../non_empty_dir_b/..//non_empty_dir_b\n"
        stdout.gets.should == "../non_empty_dir_b/../\n"
        "#{@tmpdir}/non_empty_dir_a".should_not be_existed
        "#{@tmpdir}/non_empty_dir_b".should_not be_existed
      end
    end
  end

  context 'invalid argument when try to `rm ./`' do
    before :each do
      create_files
    end

    it 'should reject to delete "./"' do
      FileUtils.cd @tmpdir do
        _, stdout, stderr = rm '-vr', './'
        stderr.gets.should == "rm: ./: Invalid argument\n"
        @files.each {|f| stdout.gets.should == ".//#{File.basename(f)}\n" }
        @files.each {|f| f.should_not be_existed }
      end
    end
  end

  context 'invalid argument when try to `rm brabrabra/./`' do
    before :each do
      create_non_empty_dirs
    end

    it 'should reject to delete "/./' do
      FileUtils.cd "#{@tmpdir}/non_empty_dir_a" do
        _, stdout, stderr = rm '-vr', '../non_empty_dir_b/./'
        stderr.gets.should == "rm: ../non_empty_dir_b/./: Invalid argument\n"
        stdout.gets.should == "../non_empty_dir_b/.//file\n"
        "#{@tmpdir}/non_empty_dir_a".should be_existed
        "#{@tmpdir}/non_empty_dir_b".should be_existed
        "#{@tmpdir}/non_empty_dir_b/file".should_not be_existed
      end
    end
  end
end

describe 'test `rm -f`' do
  context 'to delete files without permission and -f' do
    before :each do
      create_hierarchical_dirs_without_write_permission
    end

    it 'should ask for your confirmation' do
      stdin, stdout, stderr = rm '-vr', @dir
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
      stdin, stdout, stderr = rm '-vr', @dir
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
      groups = @all_files_without_permission.partition {|f| File.basename(f) == '1' }
      groups.first.each {|f| stdout.gets.should == "#{f}\n" }
      groups.first.each {|f| f.should_not be_existed }
      groups.last.each {|f| f.should be_existed }
    end

    it 'shouldn\'t ask you with `rm -f`' do
      stdin, stdout, stderr = rm '-vrf', @dir
      stderr.gets.should be_nil
      @all_files.each {|f| stdout.gets.should == "#{f}\n" }
      @all_files.each {|f| f.should_not be_existed }
    end

    it 'shouldn\'t ask you with `rm -f`' do
      unexisted_files = (@all_files_without_permission + [@subdir]).map {|f| f + '_' }
      stdin, stdout, stderr = rm '-vrf', ([@dir] + unexisted_files)
      stderr.gets.should be_nil
      @all_files.each {|f| stdout.gets.should == "#{f}\n" }
      @all_files.each {|f| f.should_not be_existed }
    end
  end
end

describe 'test `rm --rm`' do
  before :each do
    create_hierarchical_dirs
  end

  it 'can call rm from $path to delete all files recursively' do
    @all_files = @hierachical_files.disorder
    _, stdout, stderr = rm '--rm', '-rfv', @all_files
    stderr.gets.should be_nil
    @all_files_in_hierachical_dirs.flatten.each {|f| stdout =~ /#{f}\n/ }
    @all_files.each {|f| f.should_not be_existed }
  end
end

describe 'test when relational parameters' do
  before :each do
    create_deep_directory_tree
  end

  it 'can still delete all files even parameters are relational' do
    _, stdout, stderr = rm '-dv', @all_dirs
    @all_dirs[0...-1].each {|dir|
      stderr.gets.should == "rm: #{dir}: Directory not empty\n"
    }
    stdout.gets.should == "#{@all_dirs.last}\n"
  end
end
