require 'open_vz_driver'
require 'openvz'
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
      if !File.exists? DISK
        p "There is no image located under path: #{DISK}, place template cache here to run integration test"
        fail
      end

      # init
      ctid = OpenVzDriver.ctid @inventory
      container = OpenVZ::Container.new(ctid)
      # mock container's disk path
      @open_vz_data = flexmock(@open_vz_data)
      @open_vz_data.should_receive(:disk).times(1).and_return(DISK)

      # deploy
      deploy_ctid = @driver.deploy @open_vz_data, container

      # assert
      assert_equal ctid, @deploy_ctid
    ensure
    # ct
      if File.directory? "/vz/private/#{deploy_ctid}"
        p "Deleting CT"
        sh "vzctl stop #{deploy_ctid} && vzctl delete #{deploy_ctid}"
      end

      # cache
      cache = "/vz/template/cache/one-#{deploy_ctid}.tar"
      if File.exist? cache
        p "Deleting cache: #{cache}"
        File.delete cache
      end
      end
  end
end
