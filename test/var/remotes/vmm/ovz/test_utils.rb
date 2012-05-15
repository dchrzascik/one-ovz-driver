module OpenNebula

  class TestUtils

    def self.purge_ct(deploy_ctid)
      if File.directory? "/vz/private/#{deploy_ctid}"
        p "Deleting container: #{deploy_ctid}"
        sh "vzctl stop #{deploy_ctid} && vzctl delete #{deploy_ctid}"
      end
    end

    def self.purge_template(cache)
      if File.exist? cache
        p "Deleting cache: #{cache}"
        File.delete cache
      end
    end
  end

end
