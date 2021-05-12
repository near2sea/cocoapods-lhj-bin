require 'cocoapods-lhj-bin/helpers/oss_helper'
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
            file = File.expand_path("#{Pod::Config.instance.home_dir}/bin_dev.yml")
            CBin::OSS::Helper.instance.upload('bin_dev.yml', file)
          end

        end
      end
    end
  end
end
