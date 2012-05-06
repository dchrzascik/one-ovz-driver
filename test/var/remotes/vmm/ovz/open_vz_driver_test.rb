require "open_vz_driver"
require "test/unit"
require 'flexmock/test_unit'

module OpenNebula
  class OpenVzDriverTest < Test::Unit::TestCase
    def setup
      @driver = OpenVzDriver.new()
    end
  
    def teardown
      # Do nothing
    end
  
    def test_deploy
      # set up mocks
      ve_id = 101
      
      open_vz_data = flexmock("open_vz_data")
      open_vz_data.should_receive(:deploy_id).times(1).and_return(ve_id)
  
      deploy_id = @driver.deploy open_vz_data
  
      assert_equal ve_id, deploy_id
    end
  end
end