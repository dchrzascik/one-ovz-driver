require 'xml/mapping'
require 'xml/mapping/base'

# extends xml mapper to handle loading from stream
# by default only loading from xml string / file is allowed
module XML
  module Mapping
    module ClassMethods
      def load_from_stream(stream, options={:mapping=>:_default})
        xml = REXML::Document.new(stream)
        load_from_xml xml.root, :mapping=>options[:mapping]
      end
    end
  end
end

module OpenNebula
  # OpenVzData
  # class responsible for obtainting container data from deployment_file
  class OpenVzData
    # RawNode
    # Helper class used for mapping RAW tag which may contain arbitrary data
    class RawNode < XML::Mapping::SingleAttributeNode
      def initialize(*args)
        path,*args = super(*args)
        @path = XML::XXPath.new(path + "/*")
        args
      end

      # XML => Ruby mapping only (there is no set_attr_value method)
      # Converts all nodes to key=>values pairs
      # except TYPE - it's only meaningful to opennebula
      def extract_attr_value(xml)
        raw = {}
        default_when_xpath_err {
          @path.each(xml) do |node|
            raw[node.name] = node.text
          end
        }
        raw
      end
    end

    # A mapping class for the vm's context
    class ContextNode
      include XML::Mapping

      text_node :files, "FILES", :default_value =>  nil
      text_node :hostname, "HOSTNAME", :default_value =>  nil
      text_node :ip_private, "IP_PRIVATE", :default_value =>  nil
      text_node :target, "TARGET", :default_value =>  nil
      text_node :ip_gen, "IP_GEN", :default_value =>  nil
      text_node :ip_public, "IP_PUBLIC", :default_value =>  nil
      text_node :dns, "DNS", :default_value =>  nil

    end

    XML::Mapping.add_node_class RawNode
    include XML::Mapping

    text_node :name, 'NAME'
    text_node :vmid, 'VMID'
    raw_node :raw, 'RAW'
    object_node :context, 'CONTEXT', :class => ContextNode

    # note: this is bit tricky since normally we don't override new
    # however by doing that we can provide ease to use interface
    def self.new(stream)
      OpenVzData.load_from_stream stream
    end

    # Retruns ct disk
    def disk
      "/vz/one/datastores/0/#{vmid}/disk.0"
    end

  end
end
