require 'file_utils'
require 'test_utils'
require 'test/unit'
require 'flexmock/test_unit'

module OpenNebula
  class FileUtilsTest < Test::Unit::TestCase
    def test_archive_type
      # assertions
      assert_equal 'tar.gz', FileUtils.archive_type(TestUtils::TEST_DISK)

      # behaviour when testing non-archive file
      assert_raises RuntimeError do
        FileUtils.archive_type TestUtils::TEST_CTX
      end
    end

    def test_filter_executables
      files = '/root/sample_cd.iso /home/radek/wallpaper.jpg /usr/local/executable.sh /tmp/yaexecutable.ksh'
      expected_files = %w(/usr/local/executable.sh /tmp/yaexecutable.ksh)

      assert_equal expected_files, FileUtils.filter_executables(files)
      assert FileUtils.filter_executables(nil) == []
      assert FileUtils.filter_executables([]) == []
      assert FileUtils.filter_executables('') == []
      assert FileUtils.filter_executables('/home/image.jpg') == []
    end

  end
end