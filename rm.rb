#!/usr/bin/env ruby
$: << File.expand_path(File.dirname(__FILE__) + '/lib')

require 'optparse'
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

      list = if assert_existed? file
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
            error file, :is_dir
            nil
          end
        else
          [file]
        end
      end

      next if list.nil?
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
      next if list.empty?

      list = list.tree_order
      list.each_with_index do |file, idx|
        has_confirmed = false
        if rm_i?
          if ask_for_remove? file
            error file, :not_empty and next if file.flag == :cannot_delete
            has_confirmed = true
          else
            list[idx..-1].each {|f|
              f.flag = :cannot_delete if file.descendant_of? f
              } unless file.flag == :cannot_delete
            next
          end
        end

        unless has_confirmed || rm_f? || file.writable?
          if ask_for_override?(file)
            error file, :not_empty and next if file.flag == :cannot_delete
            next
          else
            list[idx..-1].each {|f|
              f.flag = :cannot_delete if file.descendant_of? f
            } unless file.flag == :cannot_delete
            next
          end
        end

        error file, :not_empty if file.flag == :cannot_delete
      end

      list.reject! {|file| file.flag == :cannot_delete }
      next if list.empty?

      trees = []
      while list && list.size > 0
        root = list.last
        groups = list.group_by {|file| file.descendant_of? root }
        trees << {root => groups[true]}
        list = groups[false]
      end
      rm_all! trees.map {|tree| tree.keys[0].expand_path }
      trees.each {|tree| tree.values.each {|file| puts file }} if verbose?
    end
  end
end

do_error_handling do
  parse_options
  main ARGV
end

exit $retval