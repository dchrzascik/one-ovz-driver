require "open_vz_data"
require "test/unit"

module OpenNebula
  class OpenVzDataTest < Test::Unit::TestCase
    def setup
      @data = OpenVzData.new("test/resources/deployment_file_test.xml")
    end

    def teardown
      # Do nothing
    end

    def test_deploy_id
      one_id = 24
      ve_id = one_id + 100

      assert_equal one_id, @data.deploy_one_id 
      assert_equal ve_id, @data.deploy_id
    end
  end
end
