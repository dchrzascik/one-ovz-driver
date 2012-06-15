require 'xml/mapping'
require 'xml/mapping/base'

module XML
  module Mapping
    module ClassMethods
      # Allows XML::Mapping to load data from stream
      # by default only loading from xml string / file is allowed
      def load_from_stream(stream, options={:mapping=>:_default})
        xml = REXML::Document.new(stream)
        load_from_xml xml.root, :mapping=>options[:mapping]
      end
    end
  end
end

module OpenNebula

  # OpenVzData holds data which describes container
  # Most of its contents is derived from deployment_file and opennebula configuration 
  class OpenVzData
    include XML::Mapping
    
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
            raw[node.name.downcase.to_sym] = node.text
          end
        }
        raw
      end
    end

    XML::Mapping.add_node_class RawNode

    text_node :name, 'NAME'
    text_node :vmid, 'VMID'
    raw_node :raw, 'RAW'
    raw_node :context, 'CONTEXT'

    def self.new(stream)
      # note: this is bit tricky since normally we don't override new
      # however by doing that we can provide easy to use interface
      OpenVzData.load_from_stream stream
    end

    # Retruns container disk
    def disk
      # TODO such hardcoded paths have to be moved out to some configuration files
      "/vz/one/datastores/0/#{vmid}/disk.0"
    end
    
    def context_disk
      # TODO such hardcoded paths have to be moved out to some configuration files
      iso = Dir.glob("/vz/one/datastores/0/#{vmid}/*.iso")
      # there have to be exacly one iso file, otherwise we don't know which one holds context data
      # note: this will raise exception even if there is no context at all
      raise OpenVzDriverError, "Can't select context file: there are #{iso.size} isos corresponding to this vm" if iso.size != 1
      iso.first
    end

  end
end
