require 'open_vz_driver'
require 'openvz'
require 'test_utils'
require "test/unit"
require 'flexmock/test_unit'

module OpenNebula
  class OpenVzDriverTestModule < Test::Unit::TestCase
    CHECKPOINT_DST = "/tmp/checkpoint"

    def setup
      @inventory = OpenVZ::Inventory.new
      @driver = OpenVzDriver.new
      OpenVZ::Util.execute "sudo brctl addbr ovz-test-br0"

      # mock_tmm
      TestUtils.mkdir TestUtils::VM_DATASTORE
      TestUtils.symlink TestUtils::TEST_CTX, TestUtils::VM_CTX
      TestUtils.symlink TestUtils::TEST_DISK, TestUtils::VM_DISK
    end

    def teardown
      TestUtils.purge TestUtils::VM_DATASTORE
      TestUtils.purge_ct TestUtils::CTID
      TestUtils.purge CHECKPOINT_DST
      OpenVZ::Util.execute "sudo brctl delbr ovz-test-br0"
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
      assert_match(/exist.*down/, `sudo vzctl status #{ctid}`)

      # reboot
      out = @driver.reboot container
      assert_match(/Restarting/, out)
      assert_equal true, TestUtils.ct_exists?(ctid)

      # save
      @driver.save container, CHECKPOINT_DST
      assert_equal true, TestUtils.ct_exists?(ctid)
      assert_equal true, File.exists?(CHECKPOINT_DST)
      assert_equal false, File.exists?("/tmp/#{container.ctid}-checkpoint")
      assert_match(/running/, `sudo vzctl status #{ctid}`)

      # destroy & restore
      TestUtils.purge_ct ctid
      assert_equal false, TestUtils.ct_exists?(ctid)
      @driver.restore CHECKPOINT_DST
      assert_equal true, TestUtils.ct_exists?(ctid)
      assert_match(/running/, `sudo vzctl status #{ctid}`)
      assert_equal false, File.exists?("/tmp/#{container.ctid}-checkpoint")

      # restore container to previous state && cancel
      @driver.cancel container
      assert_match(/deleted/, `sudo vzctl status #{ctid}`)
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
