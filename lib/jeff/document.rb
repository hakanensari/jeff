require 'nokogiri'

module Jeff
  # Internal: A SAX document that wraps the AWS XML response.
  class Document < Nokogiri::XML::SAX::Document
    def characters(val)
      (node['__content__'] ||= '') << val
    end

    def end_element(key)
      child = @stack.pop

      if child.keys == ['__content__']
        child = child['__content__']
      end

      case node[key]
      when Array
        node[key] << child
      when Hash, String
        node[key] = [node[key], child]
      else
        node[key] = child
      end
    end

    def start_element(key, attrs = [])
      @stack << {}
      attrs.each { |attr| node.store *attr }
    end

    def start_document
      @stack = [{}]
    end

    def root
      @stack.first
    end

    private

    def node
      @stack.last
    end
  end
end
