require "open_vz_data"
require "test/unit"

module OpenNebula
  class OpenVzDataTest < Test::Unit::TestCase
    def test_xml_mapping
      data = OpenVzData.new(File.new "test/resources/deployment_file_test.xml")
      
      assert_equal "31", data.vmid
      assert_equal "one-24", data.name
    end

  end
end
