module OpenNebula

  class TestUtils
    # ids used in tests
    VMID = 4900
    CTID = 5590

    # resources
    TEST_DISK = File.expand_path(File.dirname("test/resources/unused")) + "/disk.0"
    TEST_CTX = File.expand_path(File.dirname("test/resources/unused")) + "/disk.2"

    # absolute paths describing openvz env
    DISTRO = "slackware-10.2-i386-minimal"
    CT_CACHE = "/vz/template/cache/#{DISTRO}-#{CTID}.tar.gz"
    VM_DATASTORE = "/vz/one/datastores/0/#{VMID}"
    VM_DISK = "#{VM_DATASTORE}/disk.0"
    VM_CTX = "#{VM_DATASTORE}/disk.2.iso"

    def self.ct_exists? ctid
      `sudo vzctl status #{ctid}`.split[2] == 'exist'
    end

    def self.purge_ct(ctid)
      `sudo vzctl stop #{ctid} && sudo vzctl destroy #{ctid}` if self.ct_exists? ctid
    end

    def self.purge(file)
      `sudo rm -rf #{file}` if File.exists? file
    end

    def self.mkdir(dir)
      `sudo mkdir -p #{dir}`
    end

    def self.symlink(target, link_name)
      `sudo ln -s #{target} #{link_name}`
    end

  end
end
