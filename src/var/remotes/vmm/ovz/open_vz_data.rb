require 'xml/mapping'

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
    include XML::Mapping

    text_node :name, "NAME"
    text_node :vmid, "VMID"
    
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
