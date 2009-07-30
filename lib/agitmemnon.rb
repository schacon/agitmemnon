$:.unshift File.dirname(__FILE__) # For use/testing when no gem is installed

require 'logger'

require 'agitmemnon/repo'
require 'agitmemnon/client'

module Agitmemnon
  class << self
    # Set +debug+ to true to log all agmn calls and responses
    attr_accessor :debug

    # The standard +logger+ for debugging git calls - this defaults to a plain STDOUT logger
    attr_accessor :logger
    def log(str)
      logger.debug { str }
    end
  end

  self.debug = false
  @logger ||= ::Logger.new(STDOUT)

  def self.version
    yml = YAML.load(File.read(File.join(File.dirname(__FILE__), *%w[.. VERSION.yml])))
    "#{yml[:major]}.#{yml[:minor]}.#{yml[:patch]}"
  end
end
