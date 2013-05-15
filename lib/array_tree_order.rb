class Array
  def tree_order(preorder = false)
    mag_num = preorder ? -1 : 1
    sort { |f1, f2|
      case
      when f1.start_with?(f2); -mag_num
      when f2.start_with?(f1); mag_num
      else f1 <=> f2
      end
    }
  end
end