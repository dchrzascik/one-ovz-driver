$: << "#{File.dirname(__FILE__)}/../../"

require 'openvz'
require 'file_utils'
require 'open_vz_data'
require 'scripts_common'

module OpenNebula
  class OpenVzDriver

    # OpenVzDriver exception class
    class OpenVzDriverError < StandardError; end

    # a directory where the context iso img is mounted
    CTX_ISO_MNT_DIR = '/mnt/isotmp'

    # Creates new  based on its description file
    def deploy(open_vz_data, container)
      OpenNebula.log_debug("Deploying using ctid:#{container.ctid}")

      # create symlink to enable ovz to find image
      template_name = container.ctid
      template_cache = create_template template_name, open_vz_data.disk

      # options to be passed to vzctl create
      options = process_options open_vz_data.raw, {:ostemplate => template_name}

      # create and run container
      container.create( options )
      container.start

      # and contextualise it
      contextualise container, open_vz_data.vmid, open_vz_data.context
      
      container.ctid
    ensure
      # cleanup template cache - we don't need it anymore
      File.delete template_cache if template_cache and File.exists? template_cache
    end

    # Sends shutdown signal to a VM
    def shutdown(container)
      container.stop
    rescue RuntimeError => e
      raise OpenVzDriverError, "Container can't be stopped. Details: #{e.message}"
    end

    # Destroys a Vm
    def cancel(container)
      self.shutdown container
      container.destroy
    rescue RuntimeError => e
      raise OpenVzDriverError, "Container can't be canceled. Details: #{e.message}"
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
    def poll(container)
      info = {}
      
      # state, TODO handle all cases
      states = {'exist' =>  'a', 'deleted' => 'd'}
      states.default = '-'
      info[:STATE] = states[container.status[0]]
      
      # cpu TODO handle case when there are more than one cpu
      out = (container.command "ps axo pcpu").split(/\n/)
      out = out.drop 1
      info[:USEDCPU] = 0
      out.each do |line|
        line.strip!
        info[:USEDCPU] += line.to_i
      end
      
      # net
      out = container.command "cat /proc/net/dev"
      out.split(/\n/).each do |line|
          if line =~ /^\s*venet[^\s]*\s+(.+)/
              fields = $1.split(/\s+/)
              info[:NETRX] = fields[0].to_i
              info[:NETTX] = fields[8].to_i
          end
      end

      # computer container memory usage
      out = container.command  "free -k"
      out.split(/\n/).each do |line|
          if line =~ /^Mem:\s+\d+\s+(\d+)/
              info[:USEDMEMORY] = $1.to_i
          end
      end
           
      info
    end

    # Get the ctid.
    #
    # * *Args* :
    # - +inventory+ -> reference to inventory which lists all taken ctids
    # - +vmid+ -> vmid used by opennebula
    # - +offset+ -> offset between vmid and proposed ctid. 
    #               It's used becouse vmids used by ONE starts from 0, whereas OpenVZ reserves ctids < 100 for special purposes.
    #               Hence, offset should be at least 100
    def self.ctid(inventory, vmid, offset = 690)
      # returned id is equal to vmid + offset. If there is already such id, then the nearest one is taken
      # we internally operate on ints
      ct_ids = inventory.ids.map { |e| e.to_i  }
      proposed = vmid.to_i
      
      # attempty to return propsed id
      proposed += offset
      return proposed.to_s unless ct_ids.include? proposed
      # if that id is already taken chose the closest one to avoid conflict 
      ct_ids = ct_ids.find_all{|x| x >= proposed }

      # return string since ruby-openvz takes for granted that id is a string
      # note that ct_ids are assumed to be sorted in ascending order
      ct_ids.inject(proposed) do |mem, var|
        break mem unless mem == var
        mem += 1
      end.to_s
    end

    private

    # Helper method used for template creation by symlinking it to the vm's datastore disk location
    #
    # * *Args* :
    # - +template_name+ -> name of the template cache to ve 
    # - +disk_file+ -> path to vm diskfile
    def create_template(template_name, disk_file)
      disk_file_type = FileUtils.archive_type disk_file
      template_file = File.join("/", "vz", "template", "cache", "#{template_name}.#{disk_file_type}")
      File.symlink disk_file, template_file
      template_file
    end

    #  Method used to merge vzctl options provided within:
    #  - <raw> section of deployment file
    #  - arbitrary data passed by options
    #
    # * *Args*    :
    #   - +raw+ -> The container to contextualise. An instance of OpenVZ::Container class
    #   - +options+ -> arbitrary data, ex ostemplate, ip_add
    def process_options(raw, options = {})
      raw = raw.merge(options)
      
      # normalize all keys to lowercase
      new_hash = {}
      raw.each {|k, v| new_hash.merge!({k.downcase => v})}
      
      # filter out type -> it is only meaningful to opennebula
      new_hash.delete(:type)

      new_hash
    end

    #  Method used during deployment of the given vm to contextualise it
    #
    # * *Args*    :
    #   - +container+ -> The container to contextualise. An instance of OpenVZ::Container class
    #   - +one_vmid+ -> ID set by nebula
    #   - +context+ -> Context parameters. An instance of OpenVzData::ContextNode class
    def contextualise(container, one_vmid, context)
      if context == {}
        OpenNebula.log_debug "No context provided"
        return
      end

      OpenNebula.log_debug "Applying contextualisation"

      ctx_mnt_dir = "/vz/root/#{container.ctid}#{CTX_ISO_MNT_DIR}"
      iso_file = Dir.glob("/vz/one/datastores/0/#{one_vmid}/*.iso").first

      # mount the iso file
      container.command "mkdir #{CTX_ISO_MNT_DIR}"
      OpenVZ::Util.execute "sudo mount #{iso_file} #{ctx_mnt_dir} -o loop"

      # run all executable files. It's up to them whether they use context.sh or not
      files = FileUtils.filter_executables context[:files]
      files.each do |abs_fname|
        fname = File.basename abs_fname
        container.command ". #{CTX_ISO_MNT_DIR}/#{fname}"
      end

    rescue => e
      OpenNebula.log_error "Exception while performing contextualisation: #{e.message}"
      # reraise the exception
      raise OpenVzDriverError, "Exception while performing contextualisation: #{e.message}"

    ensure
      # cleanup
      OpenVZ::Util.execute "sudo mountpoint #{ctx_mnt_dir}; if [ $? -eq 0 ]; then " \
                            " sudo umount #{ctx_mnt_dir};" \
                            " sudo rmdir #{ctx_mnt_dir};" \
                            " fi"
    end
  end
end

