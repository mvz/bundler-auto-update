require "bundler-auto-update/version"

module Bundler
  module AutoUpdate
    class CLI
      def initialize(argv)
        @argv = argv
      end

      def run!
        Updater.new(test_command).auto_update!
      end

      def test_command
        if @argv.first == '-c'
          @argv[1..-1].join(' ')
        end
      end
    end

    class Updater
      DEFAULT_TEST_COMMAND = "rake"

      attr_reader :test_command

      def initialize(test_command = nil)
        @test_command = test_command || DEFAULT_TEST_COMMAND
      end

      def auto_update!
        gemfile.gems.each do |gem|
          GemUpdater.new(gem, gemfile, test_command).auto_update
        end
      end

      def gemfile
        @gemfile ||= Gemfile.new
      end
    end

    class GemUpdater
      attr_reader :gem, :gemfile, :test_command

      def initialize(gem, gemfile, test_command)
        @gem, @gemfile, @test_command = gem, gemfile, test_command
      end

      def auto_update
        if updatable?
          Logger.log "Updating #{gem.name}."
          update(:patch) and update(:minor) and update(:major)
        else
          Logger.log "#{gem.name} is not auto-updatable, passing it."
        end
      end

      def update(version_type)
        new_version = gem.last_version(version_type)

        if new_version == gem.version
          Logger.log_indent "Current gem already at latest #{version_type} version. Passing this update."
          return
        end

        Logger.log_indent "Updating to #{version_type} version #{new_version}"

        gem.version = new_version

        gemfile.update_gem(gem)

        if run_test_suite
          Logger.log_indent "Test suite ran succesfully. Committing changes."
          commit_new_version
        else
          Logger.log_indent "Test suite failed to run. Reverting changes."
          revert_to_previous_version
        end
      end

      def updatable?
        gem.version =~ /^\d+\.\d+\.\d+$/ && gem.options.nil?
      end

      def commit_new_version
        run_cmd "git commit Gemfile Gemfile.lock -m 'Auto update #{gem.name} to version #{gem.new_version}'"
      end

      def revert_to_previous_version
        run_cmd "git reset --hard Gemfile Gemfile.lock"
      end

      def run_test_suite
        run_cmd test_command
      end

      def run_cmd(cmd)
        Logger.log cmd

        CommandRunner.system(cmd)
      end
    end # class Updater

    class Gemfile

      GEM_LINE_REGEX = /^\s*gem\s*['"](\w+)['"]\s*(,\s*['"](.+)['"])?\s*(,\s*(.*))?\n$/

      # @note This funky code parser could be replaced by a funky dsl re-implementation
      def gems
        gems = []

        content.each_line do |l|
          if match = l.match(GEM_LINE_REGEX)
            _, name, _, version, _, options = match.to_a
            gems << Dependency.new(name, version, options)
          end
        end

        gems
      end

      # @todo spec
      def update_gem(gem)
        # IMPLEMENT ME !
      end

      private

      def content
        @content ||= File.read('Gemfile')
      end
    end # class Gemfile

    class Logger
      def self.log(msg, prefix = "")
        puts prefix + msg
      end

      def self.log_indent(msg)
        log(msg, "  - ")
      end
    end

    class Dependency
      attr_reader :name, :options, :major, :minor, :patch
      attr_accessor :version

      def initialize(name, version = nil, options = nil)
        @name, @version, @options = name, version, options

        @major, @minor, @patch = version.split('.') if version
      end

      def last_version(version_type)
        case version_type
        when :patch
          available_versions.select { |v| v =~ /^#{major}\.#{minor}\D/ }.first
        when :minor
          available_versions.select { |v| v =~ /^#{major}\./ }.first
        when :major
          available_versions.first
        end
      end

      def available_versions
        rails_line = gem_remote_list_output.scan(/^#{name}\s.*$/).first
        rails_line.scan /\d+\.\d+\.\d+/
      end

      def gem_remote_list_output
        CommandRunner.run "gem list #{name} -r"
      end
    end # class Dependency

    class CommandRunner
      def self.system(cmd)
        Kernel.system cmd
      end

      def self.run(cmd)
        `#{cmd}`
      end
    end
  end # module AutoUpdate
end # module Bundler
