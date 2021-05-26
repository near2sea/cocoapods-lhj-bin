#coding:utf-8
require 'cocoapods-lhj-bin/helpers/oss_helper'
require 'yaml'

module Pod
  class Command
    class Bin < Command
      class Init < Bin
        class Push < Init
          self.summary = '推送配置文档到OSS.'

          def initialize(argv)
            super
          end

          def run
            push
          end

          def push_cn_hk
            file = File.expand_path("#{Pod::Config.instance.home_dir}/localizable_config.yml")
            CBin::OSS::Helper.instance.upload('localizable_config.yml', file)
          end

          def push
            file = File.expand_path("#{Pod::Config.instance.home_dir}/bin_dev.yml")
            CBin::OSS::Helper.instance.upload('bin_dev.yml', file)
          end

          def trans
            key_map = {}
            path = '/Users/lihaijian/workspace/cocoa/cocoapods-lhj-bin-build-temp/zh2Hant.properties'
            File.open(path, 'r+') do |f|
              f.each_line do |line|
                arr = line.split('=')
                key = [arr[0][2, 4].hex].pack("U")
                val = arr[1].strip!
                key_map[key] = [val[2, 4].hex].pack("U")
              end
            end
            File.open('/Users/lihaijian/workspace/cocoa/cocoapods-lhj-bin-build-temp/zh2hant.yml', 'w') { |f| f.write key_map.to_yaml }
          end

        end
      end
    end
  end
end
