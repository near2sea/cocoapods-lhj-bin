require 'cocoapods-lhj-bin/command/bin/initHotKey'
require 'cocoapods-lhj-bin/command/bin/init'
require 'cocoapods-lhj-bin/command/bin/archive'
require 'cocoapods-lhj-bin/command/bin/auto'
require 'cocoapods-lhj-bin/command/bin/code'
require 'cocoapods-lhj-bin/command/bin/update'
require 'cocoapods-lhj-bin/command/bin/install'
require 'cocoapods-lhj-bin/command/bin/import'
require 'cocoapods-lhj-bin/command/bin/local/local'
require 'cocoapods-lhj-bin/command/bin/local/fetch'
require 'cocoapods-lhj-bin/command/bin/local/upload'
require 'cocoapods-lhj-bin/command/bin/trans'
require 'cocoapods-lhj-bin/command/bin/lhj'
require 'cocoapods-lhj-bin/command/bin/config/push'
require 'cocoapods-lhj-bin/command/bin/oss/list'
require 'cocoapods-lhj-bin/command/bin/oss/del'
require 'cocoapods-lhj-bin/helpers'
require 'cocoapods-lhj-bin/native'

module Pod
  class Command
    # This is an example of a cocoapods plugin adding a top-level subcommand
    # to the 'pod' command.
    #
    # You can also create subcommands of existing or new commands. Say you
    # wanted to add a subcommand to `list` to show newly deprecated pods,
    # (e.g. `pod list deprecated`), there are a few things that would need
    # to change.
    #
    # - move this file to `lib/pod/command/list/deprecated.rb` and update
    #   the class to exist in the the Pod::Command::List namespace
    # - change this class to extend from `List` instead of `Command`. This
    #   tells the plugin system that it is a subcommand of `list`.
    # - edit `lib/cocoapods_plugins.rb` to require this file
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
    class Bin < Command
      include CBin::SourcesHelper
      include CBin::SpecFilesHelper

      self.abstract_command = true

      self.summary = '组件二进制化插件.'
      self.description = <<-DESC
        组件二进制化插件。利用源码私有源与二进制私有源实现对组件依赖类型的切换。
      DESC

      def initialize(argv)
        @help = argv.flag?('help')
        super
      end

      def validate!
        super
        # 这里由于 --help 是在 validate! 方法中提取的，会导致 --help 失效
        # pod lib create 也有这个问题
        banner! if @help
      end
    end
  end
end
