require "bundler"
require "http"
require "fileutils"

require "pakyow/processes/proxy"

module SmokeContext
  extend RSpec::SharedContext

  let(:envars) {
    {}
  }

  let(:host) {
    "0.0.0.0"
  }

  let(:port) {
    Pakyow::Processes::Proxy.find_local_port
  }

  let(:environment) {
    :development
  }
end

RSpec.configure do |config|
  config.include SmokeContext

  config.before :all do
    @project_name = "smoke-test"
    @working_path = File.expand_path("../tmp", __FILE__)
    @project_path = File.join(@working_path, @project_name)

    install
  end

  config.before do
    create
  end

  config.after do
    shutdown if booted?
    Dir.chdir(@original_path)
    FileUtils.rm_r(@working_path)
  end

  config.after :all do
    clean
  end

  def install
    Bundler.with_clean_env do
      system "bundle exec rake release:install"
    end
  end

  def clean
    system "bundle exec rake release:clean"
  end

  def create
    @original_path = Dir.pwd
    FileUtils.mkdir_p(@working_path)
    Dir.chdir(@working_path)
    system "pakyow create #{@project_name}"
    Dir.chdir(@project_path)
  end

  def boot(environment: self.environment, envars: self.envars, port: self.port, host: self.host)
    @server = Process.spawn(envars, "pakyow boot -e #{environment} -p #{port} --host #{host}")

    wait_for_boot do
      yield if block_given?
    end
  end

  def wait_for_boot(start = Time.now, timeout = 60)
    HTTP.get("http://localhost:#{port}")
    @boot_time = Time.now - start
    yield
  rescue HTTP::ConnectionError
    unless Time.now - start > timeout
      sleep 0.01
      retry
    end
  end

  def booted?
    defined?(@server)
  end

  def shutdown
    if booted?
      Process.kill("TERM", @server)
      Process.waitpid(@server)
      remove_instance_variable(:@server)
    end
  end
end
