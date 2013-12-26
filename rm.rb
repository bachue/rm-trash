#!/usr/bin/env ruby -W0 -KU
$: << File.expand_path(File.dirname(__FILE__) + '/lib')

require 'pp'
require 'pathname'
require 'osascripts'
require 'option_parser'
require 'interaction'
require 'array_tree_order'
require 'string_color'
require 'helper'

$retval = 0

def main files = []
  files = warn_if_any_current_or_parent_directory(files).to_pathnames!

  files.each do |file|
    if assert_existed? file
      if file.to_s.end_with? '/'
        if file.symlink?
          file.follow_symlink!
        elsif !assert_dir? file
          next
        end
      end

      list = generate_list file
      next if list.nil?

      down list
      next if list.empty?

      list = list.tree_order

      up list
      next if list.empty?

      trees = decompose_trees list.tree_order(true).reverse
      rm_all! trees.map {|tree| tree.keys[0].expand_path }
      print_files trees
    end
  end
end

# generate candidates list
def generate_list file
  if assert_existed? file
    if file.directory?
      if rm_r?
        if file.symlink?
          if file.follow_symlink?
            file.ascend_tree
          else
            [file]
          end
        else
          file.ascend_tree
        end
      elsif rm_d?
        [file]
      else
        error file, Errno::EISDIR
        nil
      end
    else
      [file]
    end
  end
end

# traverse from root to leaves
def down list
  ignored_dir = nil
  list.each_with_index do |file, idx|
    if ignored_dir && file.descendant_of?(ignored_dir)
      file.flag = :delete
    elsif file.directory?
      if rm_i? && rm_r? && !ask_for_examine?(file) ||
         !rm_r? && !assert_no_children?(file)
        ignored_dir = file
        file.flag = :delete
        list[0...idx].each {|f|
          f.flag = :cannot_delete if file.descendant_of? f
        }
      end
    end
  end
  list.reject! {|file| file.flag == :delete }
end

# traverse from leaves to root
def up list
  list.each_with_index do |file, idx|
    has_confirmed = false
    if rm_i?
      if ask_for_remove? file
        error file, Errno::ENOTEMPTY and next if file.flag == :cannot_delete
        has_confirmed = true
      else
        list[idx..-1].each {|f|
          f.flag = :cannot_delete if file.descendant_of? f
        } unless file.flag == :cannot_delete
        next
      end
    end

    if file.socket? || file.pipe?
      unless file.flag == :cannot_delete
        if rm_f? || ask_for_fallback?(file)
          begin
            file.unlink
            puts file.bold if verbose?
          rescue => e
            error file, e.class
            list[idx..-1].each do |f|
              f.flag = :cannot_delete if file.descendant_of? f
            end
          end
        end
        file.flag = :cannot_delete
      end
      next
    end

    unless has_confirmed || rm_f? || file.writable?
      if ask_for_override?(file)
        error file, Errno::ENOTEMPTY and next if file.flag == :cannot_delete
        next
      else
        list[idx..-1].each {|f|
          f.flag = :cannot_delete if file.descendant_of? f
        } unless file.flag == :cannot_delete
        next
      end
    end

    if assert_valid? file
      error file, Errno::ENOTEMPTY if file.flag == :cannot_delete
    else
      file.flag = :cannot_delete
      next
    end
  end

  list.reject! {|file| file.flag == :cannot_delete }
end

# decompose file trees from candidates list
def decompose_trees list
  trees = []
  while list && list.size > 0
    root = list.last
    groups = list.partition {|file| file.descendant_of? root }
    trees << {root => groups.first}
    list = groups.last
  end
  trees
end

# output all files to delete if needed
def print_files trees
  trees.each {|tree|
    tree.values[0].tree_order.each {|file|
      puts file.bold
    }
  } if verbose?
end

do_error_handling do
  parse_options
  main ARGV
end

exit $retval
