require 'jeff/serviceable'

module Jeff
  def self.included(base)
    base.send :include, Serviceable
  end
end
