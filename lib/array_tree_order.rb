require 'helper'

class Array
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