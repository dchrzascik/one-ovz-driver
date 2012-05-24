module OpenNebula
	class OpenNebulaConfig
		
		def initialize(config_file = 'src/etc/oned.conf')
			@config = File.read config_file
		end

		def datastore
			@config.match("DATASTORE_LOCATION\s*=\s*(.*)")[1]
		end
	end
end
