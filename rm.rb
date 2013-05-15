#!/usr/bin/env ruby
$: << File.expand_path(File.dirname(__FILE__) + '/lib')

require 'optparse'
require 'pp'
require 'osascripts'
require 'option_parser'
require 'interaction'
require 'array_tree_order'

$retval = 0

def rm! files = []
  files_to_rm, deleted_file_list = [], []
  files.each do |file|
    abs_file = File.expand_path(file)

    catch :skip do
      assert_existed file do
        if file.end_with?('/')
          if File.symlink?(abs_file)
            abs_file = File.expand_path(File.readlink(abs_file.chomp('/')))
          else
            do_if_not_dir file do
              throw :skip
            end
          end
        end

        assert_existed file do
          _files_to_rm, _deleted_file_list = ready_to_rm(abs_file, file)
          files_to_rm.concat _files_to_rm
          deleted_file_list.concat _deleted_file_list
        end
      end
    end
  end

  deleted_file_list = do_rm!(files_to_rm, deleted_file_list)
  deleted_file_list.each {|file| puts file} if verbose?
end

def ready_to_rm abs_file, origin
  files_to_rm, deleted_file_list = [], []
  if File.directory?(abs_file)
    if rm_r?
      files_to_rm << abs_file
      deleted_file_list.concat Dir[origin + '{/**/**,}'].tree_order
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

def do_rm! files, origin_files
  return if files.empty?
  if forcely?
    do_rm_forcely! files, origin_files
  else # if always_confirm?
    do_rm_with_confirmation files, origin_files
  end
end

def do_rm_forcely! files, origin_files
  rm_all! files
  origin_files
end

def do_rm_with_confirmation _, origin_files
  deleted_files = []
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
            deleted_files << origin_file
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
          deleted_files << origin_file
        end
      end
    end
  end
  deleted_files
end

do_error_handling do
  parse_options
  rm! ARGV
end

exit $retval