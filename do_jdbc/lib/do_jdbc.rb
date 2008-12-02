if RUBY_PLATFORM =~ /java/
  require 'java'
  require 'do_jdbc_internal'
  require 'rubygems'    
  gem 'data_objects'    
  require 'data_objects'
else
  warn "do_jdbc is for use with JRuby only"
end
