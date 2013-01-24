require "open_vz_data"
require "test/unit"
require 'flexmock/test_unit'

module OpenNebula
  class OpenVzDataTest < Test::Unit::TestCase

    def test_xml_mapping
      data = OpenVzData.new(File.new "test/resources/deployment_file_test.xml")

      # expected values
      vmid = "4900"
      name = "one-49"
      raw = {:config => 'basic', :type => 'ovz'}
      context = {:files => '/srv/cloud/one/context/test.sh /srv/cloud/one/context/katalog/plik', :hostname => 'MAINHOST', :ip_private => '192.168.0.106', :target => 'hdb'}
      networking = {:bridge => 'ovz-test-br0', :ip => '10.1.1.2', :mac => '02:00:0a:01:01:02', :network => 'Ranged lan with a bridge', :network_id => '1', :vlan => 'NO'}

      # assertions
      assert_equal vmid, data.vmid
      assert_equal name, data.name
      assert_equal raw, data.raw
      assert_equal context, data.context

      data = OpenVzData.new(File.new "test/resources/deployment_file_network_test.xml")
      assert_equal networking, data.networking
    end

  end
end
