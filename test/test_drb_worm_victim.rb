require 'minitest/autorun'
require 'drb/worm'
require 'tmpdir'

class TestDRbWormVictim < Minitest::Test

  def setup
    DRb.start_service unless DRb.primary_server

    @victim = DRb::Worm::Victim.new DRb.uri
  end

  def test_add_to_load_path
    Dir.mktmpdir do |lib|
      @victim.add_to_load_path lib do
        assert_equal lib, $LOAD_PATH.first
      end

      refute_includes $LOAD_PATH, lib
    end
  end

  def test_inject_file
    Dir.mktmpdir do |lib|
      @victim.inject_file 'foo.rb', __FILE__, lib

      assert_equal File.read(__FILE__), File.read(File.join(lib, 'foo.rb'))
    end
  end

  def test_local_files
    path, file = @victim.local_files.first

    root = File.expand_path '../..', __FILE__

    assert path.start_with? root
    assert file.start_with? 'drb/worm'
  end

  def test_r_Dir
    dir = @victim.r_Dir

    assert_kind_of DRb::DRbObject, dir

    assert_equal Dir.object_id, dir.__drbref
  end

  def test_r_FileUtils
    require 'fileutils'

    file_utils = @victim.r_FileUtils

    assert_kind_of DRb::DRbObject, file_utils

    assert_equal FileUtils.object_id, file_utils.__drbref
  end

  def test_r_LOAD_PATH
    load_path = @victim.r_LOAD_PATH

    assert_kind_of DRb::DRbObject, load_path

    assert_equal $LOAD_PATH.object_id, load_path.__drbref
  end

  def test_r_const_get
    dir = @victim.r_const_get :Dir

    assert_kind_of DRb::DRbObject, dir

    assert_equal Dir.object_id, dir.__drbref
  end

  def test_r_open
    @victim.r_open __FILE__ do |io|
      assert_equal File.read(__FILE__), io.read
    end
  end

  def test_r_require
    refute @victim.r_require 'drb/worm'
  end

  def test_remote_object
    ro = @victim.remote_object

    assert_respond_to ro, :LOAD_PATH
    assert_respond_to ro, :const_get_id
  end

  def test_remote_script
    assert_match 'o = Object.new', @victim.remote_script

    assert_match 'extend DRb::DRbUndumped',  @victim.remote_script
    assert_match 'public :require',          @victim.remote_script
    assert_match 'def o.const_get_id(name)', @victim.remote_script
    assert_match 'def o.LOAD_PATH()',        @victim.remote_script
  end

end

