$: << "#{File.dirname(__FILE__)}/../../"

require 'openvz'
require 'open_vz_data'
require 'scripts_common'

class File
  def self.symlink source, target
    `sudo ln -s #{source} #{target}`
  end
end

module OpenNebula
  class OpenVzDriver

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

      # TODO when execute ctx files? add them to rc.local or run after booting?
      contextualise container, open_vz_data.vmid, open_vz_data.context

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

    #  An utility used to filter executable filenames
    #
    # * *Args*    :
    #   - +files+ -> Array containing filenames
    # * *Returns* :
    #   - Filtered array containing only executable filenames. If none of the filenames matches, the empty array is returned
    def self.filter_executable_files(files)
      if files.nil?
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
    # * *Returns* :
    #   - void
    def contextualise(container, one_vmid, context)

      # TODO Error handling when invoking system commands
      # TODO Fix datastore localization - /datastores/0 ??

      files = OpenVzDriver.filter_executable_files context.files

      if files.length > 0
        container.command "mkdir #{CTX_ISO_MNT_DIR}"
        OpenVZ::Util.execute "sudo mount /vz/one/datastores/0/#{one_vmid}/disk.2.iso /vz/root/#{container.ctid}#{CTX_ISO_MNT_DIR} -o loop"

        files.each do |abs_fname|
          fname = File.basename abs_fname
          container.command ". #{CTX_ISO_MNT_DIR}/#{fname}"
        end

        OpenVZ::Util.execute "sudo umount /vz/root/#{container.ctid}#{CTX_ISO_MNT_DIR}"
        container.command "rmdir #{CTX_ISO_MNT_DIR}"
      end
    end

  end
end

