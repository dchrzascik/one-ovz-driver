require 'open_vz_driver'
require 'openvz'
require 'test_utils'
require 'test/unit'
require 'flexmock/test_unit'

module OpenNebula
  class OpenVzDriverTest < Test::Unit::TestCase
        
    def setup
      # mocks
      @container = flexmock("container")
      @inventory = flexmock("inventory")
      @open_vz_data = flexmock("open_vz_data")

      @driver = OpenVzDriver.new()
    end

    def test_deploy
      # set up mocks
      @container.should_receive(:ctid).times(3).and_return(TestUtils::CTID)
      @container.should_receive(:create).times(1)
      @container.should_receive(:start).times(1)
      @container.should_receive(:command).times(0)

      @open_vz_data.should_receive(:disk).times(1).and_return(TestUtils::TEST_DISK)
      @open_vz_data.should_receive(:raw).times(1).and_return({})
      @open_vz_data.should_receive(:context).times(1).and_return({})
      @open_vz_data.should_receive(:context_disk).times(1).and_return(TestUtils::VM_CTX)
      @open_vz_data.should_receive(:vmid).times(1).and_return(TestUtils::VMID)

      # assertions
      deploy_ctid = @driver.deploy(@open_vz_data, @container)
      assert_equal TestUtils::CTID, deploy_ctid
      # ensure that we've cleaned up environment
      assert_equal false, File.exists?(TestUtils::CT_CACHE)
    ensure
      TestUtils.purge TestUtils::VM_DATASTORE
    end
    
    def test_poll    
      load 'test/resources/poll_data.rb'
      
      @container.should_receive(:command).times(4).and_return(CPU_INFO, CPU_USAGE, NET_USAGE, MEMORY_USAGE)
      @container.should_receive(:status).times(1).and_return(%w(exist unmounted running))
      
      expected_status = {:state => 'a', :usedmemory => 3665112, :usedcpu => 66.8, :netrx =>972526934, :nettx =>39121984}
      
      assert_equal expected_status, @driver.poll(@container)

      # try on deleted container, we should get nothing here
      @container.should_receive(:status).times(1).and_return(%w(deleted unmounted down))
      expected_status = {:state => 'd'}

      assert_equal expected_status, @driver.poll(@container)
    end

    # verify that lowest available ve_id is used
    def test_ctid
      @inventory.should_receive(:ids).times(3).and_return([680, 691, 693, 694])
      proposed = {'0' => '690', '1' => '692', '2' => '692'}

      # assertions
      proposed.each_pair do |vmid, ctid|
        assert_equal ctid, OpenVzDriver.ctid(@inventory, vmid)
      end
    end

  end
end



