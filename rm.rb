#!/usr/bin/env ruby
$: << File.expand_path(File.dirname(__FILE__) + '/lib')

require 'optparse'
require 'pp'
require 'osascripts'
require 'option_parser'
require 'interaction'
require 'array_tree_order'
require 'string_color'
require 'helper'

$retval = 0

ARGV << '--help' if ARGV.empty?

def main files = []
  files_to_rm, deleted_file_list = [], []

  files = warn_if_any_current_or_parent_directory(files)

  files.each do |file|
    abs_file = File.expand_path(file)

    if assert_existed? file
      if file.end_with? '/'
        if File.symlink? abs_file
          abs_file = File.expand_path(File.readlink(abs_file.chomp('/')))
        else
          if assert_not_dir? file
            next
          end
        end
      end

      if assert_existed? file
        _files_to_rm, _deleted_file_list = ready_to_rm abs_file, file
        files_to_rm.concat _files_to_rm
        deleted_file_list.concat _deleted_file_list
      end
    end
  end

  rm! files_to_rm, deleted_file_list do |delete_file|
    puts delete_file.bold if verbose?
  end
end

def ready_to_rm abs_file, origin
  files_to_rm, deleted_file_list = [], []
  if File.directory?(abs_file)
    if rm_r?
      check_permission_recursively abs_file, origin do |absfile, orifile|
        files_to_rm << absfile
        if File.symlink? orifile
          deleted_file_list << orifile
        else
          deleted_file_list.concat Dir.tree(orifile).tree_order
        end
      end
    elsif rm_d?
      if assert_not_recursive? origin
        check_permission_recursively abs_file, origin do |absfile, orifile|
          files_to_rm << absfile
          deleted_file_list << orifile
        end
      end
    else
      error origin, :is_dir
    end
  else
    check_permission_recursively abs_file, origin do |absfile, orifile|
      files_to_rm << absfile
      deleted_file_list << orifile
    end
  end
  [files_to_rm, deleted_file_list]
end

def rm! files, origin_files, &blk
  return if files.empty?
  if always_confirm?
    do_rm_with_confirmation files, origin_files, &blk
  else # if forcely? or default?
    do_rm! files, origin_files, &blk
  end
end

def do_rm! files, origin_files
  rm_all! files
  origin_files.each {|f| yield f } if block_given?
end

def do_rm_with_confirmation _, origin_files
  do_error_handling do
    files_to_confirm = []
    if rm_r?
      ignored_dir = nil
      origin_files.tree_order(true).each {|origin_file|
        abs_file = File.expand_path origin_file
        next if abs_file.start_with? ignored_dir
        if File.directory? abs_file
          if ask_for_examine? origin_file
            files_to_confirm << origin_file
          else
            ignored_dir = abs_file
          end
        else
          if ask_for_remove? origin_file
            rm_one! abs_file
            yield origin_file if block_given?
          end
        end
      }
    else
      files_to_confirm = origin_files
    end

    files_to_confirm.tree_order.each do |origin_file|
      if ask_for_remove? origin_file
        if assert_not_recursive? origin_file
          rm_one! File.expand_path(origin_file)
          yield origin_file if block_given?
        end
      end
    end
  end
end

def check_permission_recursively abs_file, origin_file
  yield abs_file, origin_file and return if rm_f?

  abs_files = Dir.tree(abs_file).tree_order
  origin_files = Dir.tree(origin_file).tree_order
  if assert_same_size? abs_files, origin_files
    have_deleted = false

    list = abs_files.zip(origin_files).each {|arr| arr << nil }
    list.each_with_index { |(abs, ori, flag), idx|
      if flag.nil?
        if File.exists?(abs) && !File.writable?(abs) && !ask_for_override?(ori)
          list[(idx..-1)].select {|lst| abs.start_with? lst[0] }.each {|lst| lst[2] = :cannot_delete }
          have_deleted = true
        end
      else
        error ori, :not_empty
      end
    }
    yield abs_file, origin_file and return unless have_deleted

    list.reject! { |_, _, flag| flag == :cannot_delete }
    list.reverse!

    trees = []
    while list && list.size > 0
      root = list.first[0]
      groups = list.group_by {|abs, ori, flag| abs.start_with? root }
      trees << groups[true]
      list = groups[false]
    end
    trees.each {|tree|
      yield tree[0][0..1] if block_given?
    }
  end
end

do_error_handling do
  parse_options
  main ARGV
end

exit $retval