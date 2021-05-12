# frozen_string_literal: true
require 'cocoapods-lhj-bin/helpers/oss_helper'

module Pod
  class Command
    class Bin < Command
      class OSS < Bin
        class Del < OSS
          self.summary = '删除OSS的key'

          self.arguments = [
            CLAide::Argument.new('--key=XX', true)
          ]

          def self.options
            [
              ['--key', 'OSS对应的key']
            ]
          end

          def initialize(argv)
            @key = argv.option('key')
            super
          end

          def validate!
            help! "请输入key" unless @key
            super
          end

          def run
            CBin::OSS::Helper.instance.delete(@key)
          end
        end
      end
    end
  end
end