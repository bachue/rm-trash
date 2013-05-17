require 'etc'
require 'pathname'

class << File
  def mode filename
    return unless File.exists?(filename)
    stat(filename).mode.to_s(8).split('').last(3).map(&:to_i).map {|permission|
      r = permission & 4 == 0 ? '-' : 'r'
      w = permission & 2 == 0 ? '-' : 'w'
      x = permission & 1 == 0 ? '-' : 'x'
      r + w + x
    }.join
  end

  def owner filename
    return unless File.exists?(filename)
    uid = stat(filename).uid
    Etc.getpwuid(uid).name rescue uid.to_s
  end

  def gowner filename
    return unless File.exists?(filename)
    gid = stat(filename).gid
    Etc.getgrgid(gid).name rescue gid.to_s
  end
end

class << Dir
  def empty?(filename)
    glob("#{filename}/*").empty?
  end

  def tree(filename)
    glob("#{filename}/**/**") + [filename]
  end
end

class Pathname
  def filenames
    filenames = []
    each_filename {|filename| filenames << filename }
    filenames
  end

  def ascend_tree(include_self = true)
    descendants = Dir["#{to_s}/**/**"]
    descendants.unshift to_s if include_self
    descendants
  end

  def descend_tree(include_self = true)
    descendants = Dir["#{to_s}/**/**"].sort { |f1, f2|
      case
      when f1.start_with?(f2); -1
      when f2.start_with?(f1); 1
      else f1 <=> f2
      end
    }
    descendants << to_s if include_self
    descendants
  end
end