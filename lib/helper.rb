require 'etc'
require 'pathname'
require 'alias_method_chain'
require 'string_color'

class Pathname
  attr_accessor :flag # user defined flag
  alias_method :to_str, :to_s # to be compatible with RUBY1.9+

  def ftype_with_trash_check
    already_trashed? ? 'trashed' : ftype_without_trash_check
  end
  alias_method_chain :ftype, :trash_check

  def already_trashed?
    descendant_of? Pathname "#{ENV['HOME']}/.Trash"
  end

  def exist_with_symlink_read?
    if symlink?
      readlink.exist_without_symlink_read? ||
      readlink.symlink?
    else
      exist_without_symlink_read?
    end
  end
  alias_method_chain :exist?, :symlink_read
  alias_method :exists?, :exist_with_symlink_read?

  def exist_or_symlink?
    exist? or symlink?
  end
  alias_method :exists_or_symlink?, :exist_or_symlink?

  def broken_symlink?
    symlink? and !exist?
  end

  def follow_symlink?
    !!@follow_symlink
  end

  def follow_symlink!
    @follow_symlink = true
  end

  def writable_with_follow_symlink?
    if symlink?
      if follow_symlink?
        readlink.lstat.writable?
      else
        lstat.writable?
      end
    else
      writable_without_follow_symlink?
    end
  end
  alias_method_chain :writable?, :follow_symlink

  def ftype_with_cache
    cache(:ftype)[@path] ||= ftype_without_cache
  end
  alias_method_chain :ftype, :cache

  def already_trashed_with_cache?
    cache(:already_trashed?)[@path] ||= already_trashed_without_cache?
  end
  alias_method_chain :already_trashed?, :cache

  def exist_with_cache?
    cache(:exist?)[@path] ||= exist_without_cache?
  end
  alias_method_chain :exist?, :cache

  def exist_with_chomp?
    Pathname(to_s.chomp('/')).exist_without_chomp?
  end
  alias_method_chain :exist?, :chomp
  alias_method :exists?, :exist?

  def symlink_with_chomp?
    Pathname(to_s.chomp('/')).symlink_without_chomp?
  end
  alias_method_chain :symlink?, :chomp

  def readlink_with_chomp
    Pathname(to_s.chomp('/')).readlink_without_chomp
  end
  alias_method_chain :readlink, :chomp

  def directory_with_cache?
    cache(:directory?)[@path] ||= directory_without_cache?
  end
  alias_method_chain :directory?, :cache

  def expand_path_with_cache
    cache(:expand_path)[@path] ||= expand_path_without_cache
  end
  alias_method_chain :expand_path, :cache

  # Fix the issue that escape_path will crush when filename starts with ~
  def expand_path_with_escape_wave
    if @path.start_with? '~'
      tmp = @path
      @path = "./#{tmp}"
    end
    expand_path_without_escape_wave
  ensure
    @path = tmp if tmp
  end
  alias_method_chain :expand_path, :escape_wave

  def expand_path_with_follow_symlink
    if @follow_symlink
      readlink_with_chomp.expand_path_without_follow_symlink
    else
      expand_path_without_follow_symlink
    end
  end
  alias_method_chain :expand_path, :follow_symlink

  def filenames
    cache(:filenames)[@path] ||= begin
      filenames = []
      each_filename {|filename| filenames << filename }
      filenames
    end
  end

  def has_children?
    exist? and !children.empty?
  end

  def ascend_tree include_self = true
    tree :ascend, include_self
  end

  def descend_tree include_self = true
    tree :descend, include_self
  end

  def permissions
    return unless exist?
    lstat.mode.to_s(8).split('').last(3).map(&:to_i).map {|permission|
      r = permission & 4 == 0 ? '-' : 'r'
      w = permission & 2 == 0 ? '-' : 'w'
      x = permission & 1 == 0 ? '-' : 'x'
      r + w + x
    }.join
  end

  def owner
    return unless exist?
    uid = lstat.uid
    Etc.getpwuid(uid).name rescue uid.to_s
  end

  def gowner
    return unless exists?
    gid = lstat.gid
    Etc.getgrgid(gid).name rescue gid.to_s
  end

  def descendant_of? path
    left_parents = expand_path_without_follow_symlink.filenames
    right_parents = path.expand_path_without_follow_symlink.filenames
    left_parents.take(right_parents.size) == right_parents
  end

  # Color Support
  def method_missing(method, *args)
    method = method.to_s
    if String::COLORS.keys.include?(method) ||
       String::COLORS.keys.map {|color| "bright_#{color}"}.include?(method) ||
       method == 'bold'
      return to_s.send method, *args
    end

    super
  end

  # delegate these methods to :to_s
  [:start_with?, :end_with?].each do |method|
    define_method(method) do |arg|
      to_s.send method, arg
    end
  end

  class << self
    def cache
      @cache ||= Hash.new {|h, k| h[k] = {} }
    end
  end

  private
    def cache cls
      self.class.cache[cls]
    end

    # direction: :ascend, :descend
    def tree direction, include_self
      descendants = Dir["#{to_s}/**/**"].to_pathnames
      descendants = descendants.tree_order if direction == :descend
      if include_self
        if direction == :descend
          descendants << self
        elsif direction == :ascend
          descendants.unshift self
        else raise ArgumentError.new 'direction should be :ascend or :descend'
        end
      end
      descendants
    end
end

class Array
  include Comparable
  attr_accessor :flag # user defined flag

  def from_root_to_leaves
    @order = :from_root_to_leaves
    self
  end

  def from_leaves_to_root
    @order = :from_leaves_to_root
    self
  end

  def to_pathnames
    map {|ele| Pathname(ele) }
  end

  def to_pathnames!
    map! {|ele| Pathname(ele) }
  end

  def mark_ancestors_of current
    range = case @order
            when :from_root_to_leaves then 0..current
            when :from_leaves_to_root then current..-1
            else raise ArgumentError.new('order must be set before `mark_ancestors_of` was called')
            end
    self[range].each {|f|
      f.flag = :cannot_delete if self[current].descendant_of? f
    }
  end

  def reject_if_flag_is! flag
    reject! {|e| e.flag == flag }
  end

  def tree_order(preorder = false)
    mag_num = preorder ? -1 : 1
    sort { |f1, f2|
      p1, p2 = Pathname(f1), Pathname(f2)
      case
      when p1.descendant_of?(p2); -mag_num
      when p2.descendant_of?(p1); mag_num
      else f1 <=> f2
      end
    }
  end
end

class String
  # Convert 123""'456'""789 to 123\"\"'456'\"\"789
  def escape_quote
    inspect.gsub(/^"(.+)"$/, '\1')
  end

  def to_version
    strip.split('.').map(&:to_i)
  end
end
