require "open_vz_data"
require "test/unit"

module OpenNebula
  class OpenVzDataTest < Test::Unit::TestCase
    def setup
      @data = OpenVzData.new(File.new "test/resources/deployment_file_test.xml")
    end

    def test_deploy_id
      vm_id = "31"
      assert_equal vm_id, @data.vm_id
    end
  end
end
