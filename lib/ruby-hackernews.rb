module RubyHackernews; end

require 'rubygems'
require 'bundler/setup'
require 'mechanize'

require 'require_all'

require_all File.join(File.dirname(__FILE__), 'ruby-hackernews', 'domain')
require_all File.join(File.dirname(__FILE__), 'ruby-hackernews', 'services')
