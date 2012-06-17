module OpenNebula
	class OpenNebulaConfig
	  
		def initialize(config_file)
			@config = File.read config_file
		end

		def datastore
			@config.match("DATASTORE_LOCATION\s*=\s*(.*)")[1]
		end
	end
end
