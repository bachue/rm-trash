#!/usr/bin/env ruby
$: << File.expand_path(File.dirname(__FILE__) + '/lib')

require 'optparse'
require 'pp'
require 'osascripts'
require 'option_parser'
require 'interaction'
require 'array_tree_order'

$retval = 0

ARGV << '--help' if ARGV.empty?

def rm! files = []
  files_to_rm, deleted_file_list = [], []

  files = warn_if_any_current_or_parent_directory(files)

  files.each do |file|
    abs_file = File.expand_path(file)

    catch :skip do
      assert_existed file do
        if file.end_with? '/'
          if File.symlink? abs_file
            abs_file = File.expand_path(File.readlink(abs_file.chomp('/')))
          else
            do_if_not_dir file do
              throw :skip
            end
          end
        end

        assert_existed file do
          _files_to_rm, _deleted_file_list = ready_to_rm abs_file, file
          files_to_rm.concat _files_to_rm
          deleted_file_list.concat _deleted_file_list
        end
      end
    end
  end

  do_rm! files_to_rm, deleted_file_list do |delete_file|
    puts delete_file if verbose?
  end
end

def ready_to_rm abs_file, origin
  files_to_rm, deleted_file_list = [], []
  if File.directory?(abs_file)
    if rm_r?
      files_to_rm << abs_file
      if File.symlink? origin
        deleted_file_list << origin
      else
        deleted_file_list.concat Dir[origin + '{/**/**,}'].tree_order
      end
    elsif rm_d?
      assert_not_recursive origin do
        files_to_rm << abs_file
        deleted_file_list << origin
      end
    else
      error origin, :is_dir
    end
  else
    files_to_rm << abs_file
    deleted_file_list << origin
  end
  [files_to_rm, deleted_file_list]
end

def do_rm! files, origin_files, &blk
  return if files.empty?
  if forcely?
    do_rm_forcely! files, origin_files, &blk
  else # if always_confirm?
    do_rm_with_confirmation files, origin_files, &blk
  end
end

def do_rm_forcely! files, origin_files
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
          ask_for_examine origin_file do |to_examine|
            if to_examine
              files_to_confirm << origin_file
            else
              ignored_dir = abs_file
            end
          end
        else
          ask_for_remove origin_file do
            rm_one! abs_file
            yield origin_file if block_given?
          end
        end
      }
    else
      files_to_confirm = origin_files
    end

    files_to_confirm.tree_order.each do |origin_file|
      ask_for_remove origin_file do
        assert_not_recursive origin_file do
          rm_one! File.expand_path(origin_file)
          yield origin_file if block_given?
        end
      end
    end
  end
end

do_error_handling do
  parse_options
  rm! ARGV
end

exit $retval