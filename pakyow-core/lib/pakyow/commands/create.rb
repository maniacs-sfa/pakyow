# frozen_string_literal: true

command :create, global: true do
  describe "Create a new project"
  required :cli

  argument :path, "Where to create the project", required: true
  option :template, "The template to create the project from", default: "default"

  action do
    require "pakyow/support/inflector"

    project_name = Pakyow::Support.inflector.underscore(
      File.basename(@path).downcase
    )

    project_name.gsub!("  ", " ")
    project_name.gsub!(" ", "_")

    human_project_name = Pakyow::Support.inflector.humanize(project_name)

    template = @template.downcase.strip
    generator = case template
    when "default"
      require_relative "../generators/project"
      Pakyow::Generators::Project.new(
        File.expand_path("../../generators/project/default", __FILE__)
      )
    else
      require_relative "../generators/project/#{template}"
      Pakyow::Generators::Project.const_get(Pakyow::Support.inflector.classify(template)).new(
        File.expand_path("../../generators/project/#{template}", __FILE__)
      )
    end

    generator.generate(
      @path,
      project_name: project_name,
      human_project_name: human_project_name
    )

    require "pakyow/support/cli/style"
    @cli.feedback.puts <<~OUTPUT

      #{Pakyow::Support::CLI.style.bold "You're all set! Go to your new project:"}
    OUTPUT

    @cli.feedback.puts "  $ cd #{@path}"
    @cli.feedback.puts

    @cli.feedback.puts <<~OUTPUT
      #{Pakyow::Support::CLI.style.bold "Then boot it up:"}
    OUTPUT

    @cli.feedback.puts "  $ pakyow boot"
    @cli.feedback.puts
  end
end
