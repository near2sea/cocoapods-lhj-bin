require 'cocoapods-lhj-bin/command/bin/initHotKey'
require 'cocoapods-lhj-bin/command/bin/init'
require 'cocoapods-lhj-bin/command/bin/archive'
require 'cocoapods-lhj-bin/command/bin/auto'
require 'cocoapods-lhj-bin/command/bin/code'
require 'cocoapods-lhj-bin/command/bin/update'
require 'cocoapods-lhj-bin/command/bin/install'
require 'cocoapods-lhj-bin/command/bin/import'
require 'cocoapods-lhj-bin/command/bin/reverse_import'
require 'cocoapods-lhj-bin/command/bin/local/local'
require 'cocoapods-lhj-bin/command/bin/local/fetch'
require 'cocoapods-lhj-bin/command/bin/local/filter'
require 'cocoapods-lhj-bin/command/bin/local/micro_service'
require 'cocoapods-lhj-bin/command/bin/local/upload'
require 'cocoapods-lhj-bin/command/bin/trans'
require 'cocoapods-lhj-bin/command/bin/lhj'
require 'cocoapods-lhj-bin/command/bin/model'
require 'cocoapods-lhj-bin/command/bin/yapi'
require 'cocoapods-lhj-bin/command/bin/view'
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

      self.summary = '????????????????????????.'
      self.description = <<-DESC
        ????????????????????????????????????????????????????????????????????????????????????????????????????????????
      DESC

      def initialize(argv)
        @help = argv.flag?('help')
        super
      end

      def validate!
        super
        # ???????????? --help ?????? validate! ?????????????????????????????? --help ??????
        # pod lib create ??????????????????
        banner! if @help
      end
    end
  end
end
