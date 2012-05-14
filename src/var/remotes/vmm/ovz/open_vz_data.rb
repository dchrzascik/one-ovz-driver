require 'rexml/document'

include REXML

module OpenNebula
  # OpenVzData
  # class responsible for obtainting container data from deployment_file
  class OpenVzData
    def initialize(deployment_stream)
      @xmldoc = Document.new(deployment_stream)
    end

    # Retruns vm's id used by opennebula
    def vm_id
      XPath.first(@xmldoc, "//VMID").cdatas[0].to_s
    end

    def disk
      "/vz/one/datastores/0/#{vm_id}/disk.0"
    end

  end
end