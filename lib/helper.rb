require 'etc'
require 'pathname'
require 'array_tree_order'
require 'alias_method_chain'
require 'string_color'

class Pathname
  attr_accessor :flag # user defined flag
  alias_method :to_str, :to_s # to be compatible with RUBY1.9+

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

  def exist_with_chomp?
    Pathname(to_s.chomp('/')).exist_without_chomp?
  end
  alias_method_chain :exist?, :chomp
  alias_method :exists?, :exist_with_chomp?

  def symlink_with_chomp?
    Pathname(to_s.chomp('/')).symlink_without_chomp?
  end
  alias_method_chain :symlink?, :chomp

  def readlink_with_chomp
    Pathname(to_s.chomp('/')).readlink_without_chomp
  end
  alias_method_chain :readlink, :chomp

  def expand_path_with_follow_symlink
    if @follow_symlink
      readlink_with_chomp.expand_path_without_follow_symlink
    else
      expand_path_without_follow_symlink
    end
  end
  alias_method_chain :expand_path, :follow_symlink

  def filenames
    filenames = []
    each_filename {|filename| filenames << filename }
    filenames
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
    to_s.start_with? path.to_s
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

  private
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

    ## This code can build a cache layer for Pathname, but it should be applied seriously or
    ## there'll be lots of bugs in code. I won't uncomment it until I feel Pathname has performance issue
    #
    # def self.cache_method(method)
    #   aliased_target, punctuation = method.to_s.sub(/([?!=])$/, ''), $1
    #   define_method "#{aliased_target}_with_cache#{punctuation}" do |*args|
    #     instance_variable_name = "@__cache_#{aliased_target}"
    #     if instance_variable_defined? instance_variable_name
    #       instance_variable_get instance_variable_name
    #     else
    #       result = send "#{aliased_target}_without_cache#{punctuation}"
    #       instance_variable_set instance_variable_name, result
    #       result
    #     end
    #   end
    #   alias_method_chain method, :cache
    # end

    # Pathname.instance_methods(false).grep(/\?$/) +
    # [:readlink, :expand_path, :filenames, :ascend_tree, :descend_tree,
    #  :permissions, :owner, :gowner].each {|method| cache_method method }
end

class Array
  attr_accessor :flag # user defined flag

  def to_pathnames
    map {|ele| Pathname(ele) }
  end

  def to_pathnames!
    map! {|ele| Pathname(ele) }
  end
end

# Convert 123""'456'""789 to 123\\\"\\\"'456'\\\"\\\"789
def escape_filename filename
  filename.to_s.inspect.inspect.gsub(/^"\\"(.+)\\""$/, '\1')
end
