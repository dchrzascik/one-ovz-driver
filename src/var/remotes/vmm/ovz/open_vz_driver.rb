$: << "#{File.dirname(__FILE__)}/../../"

require 'openvz'
require 'open_vz_data'
require 'scripts_common'

class File
  def self.symlink source, target
    OpenNebula.exec_and_log "sudo ln -s #{source} #{target}"
  end
end

module OpenNebula
  class OpenVzDriver

    # OpenVzDriver exception class
    class OpenVzDriverException < StandardError; end

    # a directory where the context iso img is mounted
    CTX_ISO_MNT_DIR = '/mnt/isotmp'

    # allowed executable extensions
    CTX_EXEC_EXT = %w(.sh .ksh .zsh)


    # Creates new  based on its description file
    def deploy(open_vz_data, container)
      OpenNebula.log_debug("Deploying using ctid:#{container.ctid}")

      # create symlink in /vz/template/cache
      # to enable ovz to find image
      template_name = "one-#{container.ctid}"
      create_template template_name, open_vz_data.disk

      # options to be passed to vzctl create
      options = process_options open_vz_data.raw, {:ostemplate => template_name}

      # create and run container
      container.create( options )
      container.start

      # and contextualise it
      contextualise container, open_vz_data.vmid, open_vz_data.context

      container.ctid
    end

    # Sends shutdown signal to a VM
    def shutdown(container)
      container.stop
      template_name = "one-#{container.ctid}"
      template_cache = Dir.glob("/vz/template/cache/#{template_name}.*").first
      OpenNebula.exec_and_log "sudo rm -rf #{template_cache}"
    rescue RuntimeError => e
      raise OpenVzDriverException, "Container can't be stopped. Details: #{e.message}"
    end

    # Destroys a Vm
    def cancel(container)
      self.shutdown container
      container.destroy
    rescue RuntimeError => e
      raise OpenVzDriverException, "Container can't be canceled. Details: #{e.message}"
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
    # It's equal to vmid + offset. If there is already such id, then the nearest one is taken
    #
    # @param reference to inventory which holds data
    # @return ctid (string)
    def self.ctid(inventory, vmid, offset = 690)
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

    #  An utility used to filter executable filenames
    #
    # * *Args*    :
    #   - +files+ -> String containing filenames separated by whitespaces
    # * *Returns* :
    #   - Filtered array containing only executable filenames. If none of the filenames matches, the empty array is returned
    def self.filter_executable_files(files)
      if files.nil? or files.empty?
        []
      else
        files.split.find_all {|f| CTX_EXEC_EXT.find {|e| e == File.extname(f) } != nil }
      end
    end

    private

    def create_template(template_name, disk_file)
      disk_file_type = template_type disk_file
      template_file = File.join("/", "vz", "template", "cache", "#{template_name}.#{disk_file_type}")
      File.symlink disk_file, template_file
    end

    def template_type(file_name)
      # compression type is determined by 2 bytes representing 'magic number'
      types = {"\x1F\x8B" => 'tar.gz', "BZ" => 'tar.bz2', "\xFD\x00" => 'tar.xz'}

      File.open(file_name, "r") do |file|
        bytes = file.read(2)
        return types[bytes]
      end
      
      raise "Cannot determine filetype of #{file_name}"
    end

    def process_options(raw, options = {})
      raw = raw.merge(options)
      
      # normalize all keys to lowercase
      new_hash = {}
      raw.each {|k, v| new_hash.merge!({k.downcase => v})}
      
      # filter out type -> it is only meaningful to opennebula
      new_hash.delete('type')

      new_hash
    end

    #  Method used during deployment of the given vm to contextualise it
    #
    # * *Args*    :
    #   - +container+ -> The container to contextualise. An instance of OpenVZ::Container class
    #   - +one_vmid+ -> ID set by nebula
    #   - +context+ -> Context parameters. An instance of OpenVzData::ContextNode class
    def contextualise(container, one_vmid, context)
      if context.nil?
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
      files = OpenVzDriver.filter_executable_files context.files
      files.each do |abs_fname|
        fname = File.basename abs_fname
        container.command ". #{CTX_ISO_MNT_DIR}/#{fname}"
      end

    rescue => e
      OpenNebula.log_error "Exception while performing contextualisation: #{e.message}"
      # reraise the exception
      raise OpenVzDriverException, "Exception while performing contextualisation: #{e.message}"

    ensure
      # cleanup
      OpenVZ::Util.execute "sudo mountpoint #{ctx_mnt_dir}; if [ $? -eq 0 ]; then " \
                            " sudo umount #{ctx_mnt_dir};" \
                            " sudo rmdir #{ctx_mnt_dir};" \
                            " fi"
    end
  end
end

