require_relative 'mspec/matchers'
require_relative 'mspec/expectations'
require_relative 'mspec/mocks'
require_relative 'mspec/runner'
require_relative 'mspec/guards'
require_relative 'mspec/helpers'
require_relative 'mspec/version'

# If the implementation on which the specs are run cannot
# load pp from the standard library, add a pp.rb file that
# defines the #pretty_inspect method on Object or Kernel.
begin
  require 'pp'
rescue LoadError
  module Kernel
    def pretty_inspect
      inspect
    end
  end
end
