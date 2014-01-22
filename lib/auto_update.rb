require 'option_parser'
require 'interaction'
require 'string_color'
require 'fileutils'
require 'helper'
require 'open-uri'

class AutoUpdate
  class << self
    CURRENT_VERSION = File.read(File.dirname(__FILE__) + '/../version').to_version
    ROOT_PATH = '/tmp/.rm_trash'.freeze
    UPDATE_LOCK_PATH = (ROOT_PATH + '/update.lock').freeze
    VERSION_FILE_PATH = (ROOT_PATH + '/version').freeze
    PROMPTED_FILE_PATH = (ROOT_PATH + '/prompted').freeze
    URL = URI('https://gitcafe.com/bachue/rm-trash/raw/master/version').freeze

    def start_checking!
      unless no_auto_update? || update_locked?
        lock_for_update!
        fork do
          set_version URL.read.strip rescue send_mail '[rm-trash] update failure', $!.message
        end
      end
    end

    def prompt_for_update
      unless no_auto_update? || prompted?
        if get_version && get_version > CURRENT_VERSION
          prompted!
          STDERR.puts <<-PROMPT.bold.green
There is a new version of rm-trash available. Some bug fixes included.
We recommand you to pull updates from `https://gitcafe.com/bachue/rm-trash` and install.
          PROMPT
        end
      end
    end

    private
      def lock_for_update!
        update_lock.open 'w'
      end

      def update_locked?
        update_lock.exist?
      end

      def update_lock
        @_update_lock ||= begin
          FileUtils.mkdir_p ROOT_PATH
          Pathname.new UPDATE_LOCK_PATH
        end
      end

      def set_version version
        version_file.open('w') {|f| f << version }
      end

      def get_version
        @_version ||= version_file.exist? && version_file.read.to_version
      end

      def version_file
        @_version_file ||= begin
          FileUtils.mkdir_p ROOT_PATH
          Pathname.new VERSION_FILE_PATH
        end
      end

      def prompted?
        prompted_file.exist?
      end

      def prompted!
        prompted_file.open 'w'
      end

      def prompted_file
        @_prompted_file ||= begin
          FileUtils.mkdir_p ROOT_PATH
          Pathname.new PROMPTED_FILE_PATH
        end
      end
  end
end