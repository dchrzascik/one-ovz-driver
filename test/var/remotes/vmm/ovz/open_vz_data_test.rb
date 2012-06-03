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

      # context section variables
      files = %w(/srv/cloud/one/context/test.sh /srv/cloud/one/context/katalog/plik)
      hostname = 'MAINHOST'
      ip_private = '192.168.0.106'
      target = 'hdb'

      
      assert_equal vmid, data.vmid
      assert_equal "one-#{vmid}", data.name
      assert_equal "#{DATASTORE}/0/#{vmid}/disk.0", data.disk
      assert_equal raw, data.raw

      # context section vars assertions
      assert_equal files, data.context.files.split
      assert_equal hostname, data.context.hostname
      assert_equal ip_private, data.context.ip_private
      assert_equal target, data.context.target

    end

  end
end
