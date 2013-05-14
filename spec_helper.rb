require 'rubygems'
require 'bundler'
require 'bundler/setup'
require 'tmpdir'
require 'open3'

Bundler.require :test

def rm *args
  rm = File.expand_path(File.dirname(__FILE__) + '/rm.rb')
  _, stdout, stderr = Open3.popen3 [rm, *args].join(' ')
  [stdout.gets(nil), stderr.gets(nil)]
end

RSpec::Matchers.define :be_exists do
  match do |actual|
    File.exists? actual
  end
end

class Array
  def disorder
    sort {rand * 2 - 1}
  end
end