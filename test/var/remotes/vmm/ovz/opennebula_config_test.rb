require 'opennebula_config'
require 'test_utils'
require 'test/unit'
require 'flexmock/test_unit'

module OpenNebula
  class OpenNebulaConfigTest < Test::Unit::TestCase

    def setup
		@config = OpenNebulaConfig.new 'test/resources/oned.conf'
    end

    def test_datastore
		assert_equal '/vz/one/datastores', @config.datastore
    end

  end
end
