$: << "#{File.dirname(__FILE__)}/../../"

require 'openvz'
require 'open_vz_data'
require 'scripts_common'

module OpenNebula
  class OpenVzDriver

    attr_reader :deploy_id
    def initialize()
      OpenNebula.log_debug("OpenVzDriver's been initialized'")
    end

    # Creates new  based on its description file
    def deploy(open_vz_data, container=nil)
      @deploy_id = open_vz_data.deploy_id
      container ||= OpenVZ::Container.new(@deploy_id)
      
      @deploy_id
    end

    # Sends shutdown signal to a VM
    def shutdown()
      OpenNebula.log_error("Not yet implemented")
    end

    # Destroys a Vm
    def cancel(deploy_id)
      OpenNebula.log_error("Not yet implemented")
    end

    # Saves the state of a Vm
    def save(deploy_id, file)
      OpenNebula.log_error("Not yet implemented")
    end

    # Restores a VM to a previous saved state
    def restore(file)
      OpenNebula.log_error("Not yet implemented")
    end

    # Performs live migration of a VM
    def migrate(deploy_id, host)
      OpenNebula.log_error("Not yet implemented")
    end

    # Gets information about a VM
    def poll(deploy_id)
      OpenNebula.log_error("Not yet implemented")
    end

  end
end

