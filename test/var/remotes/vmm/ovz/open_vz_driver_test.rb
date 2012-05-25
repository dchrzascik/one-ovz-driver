require 'open_vz_driver'
require 'openvz'
require 'test_utils'
require 'test/unit'
require 'flexmock/test_unit'

module OpenNebula
  class OpenVzDriverTest < Test::Unit::TestCase

    CTID = 100
    DISK = File.absolute_path "test/resources/disk.0"
    CACHE = "/vz/template/cache/one-#{CTID}.tar.gz"
    def setup
      # mocks
      @container = flexmock("container")
      @inventory = flexmock("inventory")
      @open_vz_data = flexmock("open_vz_data")

      @driver = OpenVzDriver.new()
    end

    def test_deploy
      # set up mocks
      @container.should_receive(:ctid).times(3).and_return(CTID)
      @container.should_receive(:create).times(1)
      @container.should_receive(:start).times(1)

      @open_vz_data.should_receive(:disk).times(1).and_return(DISK)

      # assertions
      deploy_ctid = @driver.deploy(@open_vz_data, @container)
      assert_equal CTID, deploy_ctid
      assert_equal true, File.exists?(CACHE)
    ensure
      TestUtils.purge_template CACHE if deploy_ctid
    end

    # verify that lowest available ve_id is used
    def test_ctid
      @inventory.should_receive(:ids).times(3).and_return([24], [100, 102], [100, 101, 102])

      # assertions
      %w(100 101 103).each do |id|
        assert_equal id, OpenVzDriver.ctid(@inventory)
      end
    end

  end
end
