$: << "#{File.dirname(__FILE__)}"

require 'open_vz_driver'
require 'openvz'
require 'test_utils'
require "test/unit"
require 'flexmock/test_unit'

module OpenNebula
  class OpenVzDriverTestModule < Test::Unit::TestCase
    DISK = File.absolute_path 'test/resources/disk.0'
    def setup
      @open_vz_data = OpenVzData.new(File.new "test/resources/deployment_file_test.xml")
      @inventory = OpenVZ::Inventory.new
      @driver = OpenVzDriver.new
    end
    
    def test_deploy
      # init
      ctid = OpenVzDriver.ctid @inventory
      container = OpenVZ::Container.new(ctid)
      # mock container's disk path
      @open_vz_data = flexmock(@open_vz_data)
      @open_vz_data.should_receive(:disk).times(1).and_return(DISK)
      
      # deploy
      deploy_ctid = @driver.deploy @open_vz_data, container
      
      # assert
      assert_equal ctid, deploy_ctid
      assert_equal true, File.directory?("/vz/private/#{deploy_ctid}")
    ensure
      TestUtils.purge_ct deploy_ctid if deploy_ctid
      TestUtils.purge_template deploy_ctid if deploy_ctid
    end
  end
end
