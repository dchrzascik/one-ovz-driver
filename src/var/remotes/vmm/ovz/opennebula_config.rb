module OpenNebula
	class OpenNebulaConfig
		
    ONE_LOCATION = ENV["ONE_LOCATION"]
    if !ONE_LOCATION
       ONE_CONFIG = "/usr/bin" 
    else
       ONE_CONFIG = ONE_LOCATION + "/lib"
    end
		
		def initialize(config_file = nil)
		  
		  
			@config = File.read config_file
		end

		def datastore
			@config.match("DATASTORE_LOCATION\s*=\s*(.*)")[1]
		end
	end
end
