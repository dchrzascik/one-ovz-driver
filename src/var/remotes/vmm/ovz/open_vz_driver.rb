$: << "#{File.dirname(__FILE__)}/../../"

require 'openvz'
require 'open_vz_data'
require 'scripts_common'
require 'sixarm_ruby_magic_number_type'

module OpenNebula
  class OpenVzDriver
    # Creates new  based on its description file
    def deploy(open_vz_data, container)
      OpenNebula.log_debug("Deploying using ctid:#{container.ctid}")

      # create symlink in /vz/template/cache
      # to enable ovz to find image
      template_name = "one-#{container.ctid}"
      create_template template_name, open_vz_data.disk

      # create and run container
      container.create( :ostemplate => template_name )
      container.start

      container.ctid
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

    # Get the lowest available ctid (no smaller than 100 - these ids are special)
    # @param reference to inventory which holds data
    # @return ctid (string)
    def self.ctid(inventory)
      # we internally operate on ints
      ct_ids = inventory.ids.map { |e| e.to_i  }
      ct_ids = ct_ids.find_all{|x| x >= 100 }

      # return string since ruby-openvz takes for granted that id is a string
      # note that ct_ids are assumed to be sorted in ascending order
      ct_ids.inject(100) do |mem, var|
        break mem unless mem == var
        mem += 1
      end.to_s
    end

    private

    def create_template(template_name, disk_file)
      disk_file_type = 'tar'
      template_file = File.join("/", "vz", "template", "cache", "#{template_name}.#{disk_file_type}")
      File.symlink disk_file, template_file
    end

  end
end
