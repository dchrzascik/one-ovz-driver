module OpenNebula

  class TestUtils

    def self.purge_ct(deploy_ctid)
      if File.directory? "/vz/private/#{deploy_ctid}"
        p "Deleting container: #{deploy_ctid}"
        `sudo vzctl stop #{deploy_ctid} && sudo vzctl delete #{deploy_ctid}`
      end
    end

    def self.purge_template(cache)
      if File.exist? cache
        p "Deleting cache: #{cache}"
        `sudo rm -rf #{cache}`
      end
    end
  end

end
