require "open_vz_data"
require "test/unit"
require 'flexmock/test_unit'

module OpenNebula
  class OpenVzDataTest < Test::Unit::TestCase
    
    DATASTORE = '/vz/one/datastores'
    
    def test_xml_mapping
      data = OpenVzData.new(File.new "test/resources/deployment_file_test.xml")
      
      vmid = "49"
      raw = {'CONFIG' => 'basic', 'TYPE' => 'ovz'}
      
      assert_equal vmid, data.vmid
      assert_equal "one-#{vmid}", data.name
      assert_equal "#{DATASTORE}/0/#{vmid}/disk.0", data.disk
      assert_equal raw, data.raw
    end

  end
end
