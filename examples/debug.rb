$:.unshift File.expand_path '../../lib', __FILE__

require 'yaml'

require 'jeff'
require 'pry'
require 'pry-doc'

class Client
  include Jeff

  params  'AssociateTag' => -> { tag },
          'Service'      => 'AWSECommerceService',
          'Version'      => '2011-08-01'

  attr_accessor :tag

  def initialize
    self.key      = config['key']
    self.secret   = config['secret']
    self.tag      = config['tag']
    self.endpoint = 'http://ecs.amazonaws.com/onca/xml'
  end

  def find(asins)
    params = {
      'Operation' => 'ItemLookup',
      'ItemId'    => Array(asins).join(',')
    }

    streamer = Streamer.new
    res = get query: params, response_block: streamer
    res.body = streamer
    res
  end

  private

  def config
    @config ||= YAML.load_file File.expand_path '../amazon.yml', __FILE__
  end
end

binding.pry
