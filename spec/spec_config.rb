require "pakyow/support/deep_dup"

RSpec.configure do |config|
  using Pakyow::Support::DeepDup

  config.expect_with :rspec do |expectations|
    # TODO This option will default to `true` in RSpec 4. Remove then.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # TODO Will default to `true` in RSpec 4. Remove then
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.warnings = true
  config.color = true

  config.order = :random
  Kernel.srand config.seed

  if ENV.key?("CI_BENCH")
    config.filter_run benchmark: true
  else
    config.filter_run_excluding benchmark: true
  end

  if ENV.key?("CI_SMOKE")
    config.filter_run smoke: true
  else
    config.filter_run_excluding smoke: true
  end

  def rss
   `ps -eo pid,rss | grep #{Process.pid} | awk '{print $2}'`.to_i
  end

  config.before :suite do
    require "pakyow/support/cli/style"
    Pakyow::Support::CLI.instance_variable_set(:@style, Pastel.new(enabled: true))

    if Pakyow.respond_to?(:config)
      $original_pakyow_config = Pakyow.config
    end

    if Pakyow.instance_variable_defined?(:@__class_state)
      $original_class_state = Pakyow.instance_variable_get(:@__class_state).keys.each_with_object({}) do |class_level_ivar, state|
        state[class_level_ivar] = Pakyow.instance_variable_get(class_level_ivar)
      end
    end

    $original_load_path_count = $LOAD_PATH.count

    if ENV["SPEC_PROFILE"] == "memory"
      require "memory_profiler"
      MemoryProfiler.start
    end

    if ENV["SPEC_PROFILE"] && ENV["SPEC_PROFILE"] != "memory"
      require "ruby-prof"
      RubyProf.start
    end
  end

  config.after :suite do
    if ENV["SPEC_PROFILE"] == "memory"
      puts "printing"
      GC.start
      MemoryProfiler.stop.pretty_print
    end

    if ENV["SPEC_PROFILE"] && ENV["SPEC_PROFILE"] != "memory"
      result = RubyProf.stop
      printer = RubyProf::FlatPrinter.new(result)
      printer.print(STDOUT)
    end
  end

  config.before do
    allow($stdout).to receive(:tty?).and_return(true)

    $original_constants = Object.constants

    allow(Pakyow).to receive(:at_exit)
    allow(Pakyow).to receive(:exit)
    allow(Process).to receive(:exit)
    allow(Process).to receive(:exit!)
    allow(Pakyow).to receive(:trap)

    cache_config(Pakyow)
    cache_config(Pakyow::Application) if defined?(Pakyow::Application)
    cache_config(Pakyow::Plugin) if defined?(Pakyow::Plugin)

    if defined?(Pakyow::Processes::Environment)
      allow(Pakyow::Processes::Environment).to receive(:trap)
    end

    if Pakyow.respond_to?(:load)
      allow(Pakyow).to receive(:load)
    end

    if Pakyow.instance_variable_defined?(:@__class_state)
      $original_class_state.each do |ivar, original_value|
        Pakyow.instance_variable_set(ivar, original_value.deep_dup)
      end
    end

    @defined_constants = Module.constants.dup
  end

  config.after do
    if defined?(Rake)
      Rake.application.clear
    end

    $LOAD_PATH.shift($LOAD_PATH.count - $original_load_path_count)

    if Pakyow.respond_to?(:apps)
      # Cleanup app state.
      #
      Pakyow.apps.each do |app|
        if app.respond_to?(:data)
          app.data&.subscribers&.shutdown
        end
      end
    end

    reset_config(Pakyow::Plugin) if defined?(Pakyow::Plugin)
    reset_config(Pakyow::Application) if defined?(Pakyow::Application)
    reset_config(Pakyow)

    [:@port, :@host, :@logger, :@app, :@output, :@deprecator, :@config].each do |ivar|
      if Pakyow.instance_variable_defined?(ivar)
        Pakyow.remove_instance_variable(ivar)
      end
    end

    if Object.const_defined?("Pakyow::Presenter::Composers::View")
      Pakyow::Presenter::Composers::View.__cache.clear
    end

    if defined?(Pakyow::Support::Deprecator) && Pakyow::Support::Deprecator.instance_variable_defined?(:@global)
      Pakyow::Support::Deprecator.remove_instance_variable(:@global)
    end

    remove_constants(
      (Object.constants - $original_constants).select { |constant_name|
        constant_name.to_s.start_with?("Test")
      }.map(&:to_sym)
    )

    Thread.current[:pakyow_logger] = nil

    if ENV["RSS"]
      GC.start
      puts "rss: #{rss} live objects (#{GC.stat[:heap_live_slots]})"
    end
  end

  def cache_config(object)
    config = if object.respond_to?(:__settings)
      object
    elsif object.respond_to?(:__config)
      object.__config
    end

    if config
      @config_defaults_cache ||= {}
      @config_blocks_cache ||= {}
      @config_blocks_cache[config.name] ||= {}
      @config_defaults_cache[config.name] ||= {}

      config.__settings.each_value do |setting|
        @config_defaults_cache[config.name][setting.name] = setting.instance_variable_get(:@default).deep_dup
        @config_blocks_cache[config.name][setting.name] = setting.instance_variable_get(:@block).deep_dup
      end

      config.__groups.each_value do |group|
        cache_config(group)
      end
    end
  end

  def reset_config(object)
    config = if object.respond_to?(:__settings)
      object
    elsif object.respond_to?(:__config)
      object.__config
    end

    if config
      config.__settings.each_value do |setting|
        setting.instance_variable_set(:@default, @config_defaults_cache.dig(config.name, setting.name))
        setting.instance_variable_set(:@block, @config_blocks_cache.dig(config.name, setting.name))

        if setting.instance_variable_defined?(:@value)
          setting.remove_instance_variable(:@value)
        end
      end

      config.__groups.each_value do |group|
        reset_config(group)
      end
    end
  end

  def remove_constants(constant_names, within = Object)
    constant_names.each do |constant_name|
      if within.const_defined?(constant_name, false)
        constant = within.const_get(constant_name, false)

        if constant.respond_to?(:constants)
          remove_constants(constant.constants(false), constant.respond_to?(:remove_const, true) ? constant : within)
        end

        within.__send__(:remove_const, constant_name)
      end
    end
  end
end

RSpec::Matchers.define :eq_sans_whitespace do |expected|
  match do |actual|
    expected.gsub(/\s+/, "") == actual.gsub(/\s+/, "")
  end

  diffable
end

RSpec::Matchers.define :include_sans_whitespace do |expected|
  match do |actual|
    actual.to_s.gsub(/\s+/, "").include?(expected.to_s.gsub(/\s+/, ""))
  end

  diffable
end

require "warning"
warnings = []
pakyow_path = File.expand_path("../../", __FILE__)
Warning.process do |warning|
  if warning.start_with?(pakyow_path) && !warning.include?("_spec.rb") && !warning.include?("spec/")
    warnings << warning.gsub(/^#{pakyow_path}\//, "")
  end
end

at_exit do
  if warnings.any?
    require "pakyow/support/cli/style"
    puts Pakyow::Support::CLI.style.yellow "#{warnings.count} warnings were generated:"
    warnings.take(1_000).each do |warning|
      puts Pakyow::Support::CLI.style.yellow("  › ") + warning.strip
    end
    puts
  end
end

def start_simplecov(&block)
  if ENV["COVERAGE"]
    require "simplecov"
    require "simplecov-console"

    SimpleCov::Formatter::Console.table_options = { max_width: 200 }
    SimpleCov.formatter = SimpleCov::Formatter::Console
    SimpleCov.start do
      add_filter "spec/"
      add_filter ".bundle/"
      self.instance_eval(&block) if block_given?
    end
  end
end

require "pry"

ENV["SESSION_SECRET"] = "sekret"

def wait_for_redis!(redis_url = ENV["REDIS_URL"] || "redis://127.0.0.1:6379")
  require "redis"

  connected = false
  iterations = 0
  until iterations > 30
    connection = Redis.new(url: redis_url)

    begin
      connection.info
      connected = true
      break
    rescue
      iterations += 1
      sleep 1
    end
  end

  unless connected
    raise RuntimeError, "Could not connect to redis: #{redis_url}"
  end
end
