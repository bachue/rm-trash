require 'etc'

class << File
  def deletable? filename
    writable? dirname(filename)
  end

  def mode filename
    stat(filename).mode.to_s(8)[2..-1].split('').map(&:to_i).map {|permission|
      r = permission & 4 == 0 ? '-' : 'r'
      w = permission & 2 == 0 ? '-' : 'w'
      x = permission & 1 == 0 ? '-' : 'x'
      r + w + x
    }.join
  end

  def owner filename
    uid = stat(filename).uid
    Etc.getpwuid(uid).name rescue uid.to_s
  end

  def gowner filename
    gid = stat(filename).gid
    Etc.getgrgid(gid).name rescue gid.to_s
  end
end