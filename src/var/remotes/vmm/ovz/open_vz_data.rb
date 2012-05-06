require 'rexml/document'

include REXML

module OpenNebula
  # OpenVzData
  # class responsible for obtainting container data from deployment_file
  class OpenVzData
    def initialize(deployment_file)
      @xmldoc = Document.new(File.new(deployment_file))
    end

    # Retruns container's id
    # It's shifted by 100 in comparision to ONE ( ovz reserves ids < 100 )
    def deploy_id()
      deploy_one_id.to_s.to_i + 100
    end
    
    # Retruns vm's id used by opennebula
    def deploy_one_id()
      XPath.first(@xmldoc, "//VMID").cdatas[0]
    end

  end
end