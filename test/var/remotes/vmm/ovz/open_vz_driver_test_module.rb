require 'open_vz_driver'
require 'openvz'
require 'test_utils'
require "test/unit"
require 'flexmock/test_unit'

module OpenNebula
  class OpenVzDriverTestModule < Test::Unit::TestCase
    def setup
      @inventory = OpenVZ::Inventory.new
      @driver = OpenVzDriver.new

      # mock_tmm
      TestUtils.mkdir TestUtils::VM_DATASTORE
      TestUtils.symlink TestUtils::TEST_CTX, TestUtils::VM_CTX
      TestUtils.symlink TestUtils::TEST_DISK, TestUtils::VM_DISK
    end

    def teardown
      TestUtils.purge TestUtils::VM_DATASTORE
      TestUtils.purge_ct TestUtils::CTID
    end

    def test_driver
      # init
      @open_vz_data = OpenVzData.new(File.new "test/resources/deployment_file_no_context_test.xml")
      ctid = OpenVzDriver.ctid @inventory, TestUtils::VMID.to_s
      container = OpenVZ::Container.new(ctid)

      # deploy
      assert_equal ctid, @driver.deploy(@open_vz_data, container)
      assert @open_vz_data.context == {}
      assert_equal true, TestUtils.ct_exists?(ctid)
      # ensure that we've cleaned up environment
      assert_equal false, File.exists?(TestUtils::CT_CACHE)

      # poll
      status = @driver.poll container
      assert_equal 'a', status[:state]
      # there have to be 5 values describing status
      assert_equal 5, status.size

      # shutdown
      @driver.shutdown container
      assert_match(/exist.*down/, `vzctl status #{ctid}`)

      # restore container to previous state && cancel
      `vzctl start #{ctid}`
      assert_match(/exist.*running/, `vzctl status #{ctid}`)
      @driver.cancel container
      assert_match(/deleted/, `vzctl status #{ctid}`)
    end

    def test_driver_with_ctx
      # init
      @open_vz_data = OpenVzData.new(File.new "test/resources/deployment_file_test.xml")
      ctid = OpenVzDriver.ctid @inventory, TestUtils::VMID.to_s
      container = OpenVZ::Container.new(ctid)

      # deploy
      assert_equal ctid, @driver.deploy(@open_vz_data, container)
      assert_equal true, TestUtils.ct_exists?(ctid)
      # ensure that we've cleaned up environment
      assert_equal false, File.exists?(TestUtils::CT_CACHE)

      # ctx assertions
      assert @open_vz_data.context != nil
      assert "tst\n" == container.command('cat /tmp/tst')
    end

  end
end
