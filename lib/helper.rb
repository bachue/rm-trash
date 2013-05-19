require 'etc'
require 'pathname'
require 'array_tree_order'

class Pathname
  attr_accessor :flag # user defined flag

  def exist_or_symlink?
    exist? or symlink?
  end
  alias_method :exists_or_symlink?, :exist_or_symlink?

  def follow_symlink?
    !!@follow_symlink
  end

  def follow_symlink!
    @follow_symlink = true
  end

  def exist_with_chomp?
    Pathname(to_s.chomp('/')).exist_without_chomp?
  end
  alias_method :exist_without_chomp?, :exist?
  alias_method :exist?, :exist_with_chomp?
  alias_method :exists?, :exist?

  def symlink_with_chomp?
    Pathname(to_s.chomp('/')).symlink_without_chomp?
  end
  alias_method :symlink_without_chomp?, :symlink?
  alias_method :symlink?, :symlink_with_chomp?

  def readlink_with_chomp
    Pathname(to_s.chomp('/')).readlink_without_chomp
  end
  alias_method :readlink_without_chomp, :readlink
  alias_method :readlink, :readlink_with_chomp

  def expand_path_with_follow_symlink
    if @follow_symlink
      readlink_with_chomp.expand_path_without_follow_symlink
    else
      expand_path_without_follow_symlink
    end
  end
  alias_method :expand_path_without_follow_symlink, :expand_path
  alias_method :expand_path, :expand_path_with_follow_symlink

  def filenames
    filenames = []
    each_filename {|filename| filenames << filename }
    filenames
  end

  def has_children?
    exist? or children.empty?
  end

  def ascend_tree include_self = true, &blk
    tree :ascend, include_self, &blk
  end

  def descend_tree include_self = true, &blk
    tree :descend, include_self, &blk
  end

  def permissions
    return unless exist?
    stat.mode.to_s(8).split('').last(3).map(&:to_i).map {|permission|
      r = permission & 4 == 0 ? '-' : 'r'
      w = permission & 2 == 0 ? '-' : 'w'
      x = permission & 1 == 0 ? '-' : 'x'
      r + w + x
    }.join
  end

  def owner
    return unless exist?
    uid = stat.uid
    Etc.getpwuid(uid).name rescue uid.to_s
  end

  def gowner filename
    return unless exists?
    gid = stat.gid
    Etc.getgrgid(gid).name rescue gid.to_s
  end

  def is_descendant_of? path
    to_s.start_with? path.to_s
  end

  private
    # direction: :ascend, :descend
    def tree direction, include_self
      descendants = Dir["#{to_s}/**/**"]
      descendants = descendants.tree_order if direction == :descend
      if include_self
        if direction == :descend
          descendants << to_s
        elsif direction == :ascend
          descendants.unshift to_s
        else raise ArgumentError.new 'direction should be :ascend or :descend'
        end
      end
      descendants.each {|child|
        yield child
      } if block_given?
      descendants
    end
end

class Array
  attr_accessor :flag # user defined flag
end