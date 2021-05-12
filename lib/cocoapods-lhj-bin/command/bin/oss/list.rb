# frozen_string_literal: true
require 'cocoapods-lhj-bin/helpers/oss_helper'

module Pod
  class Command
    class Bin < Command
      class OSS < Bin
        class List < OSS
          self.summary = '查看OSS列表'

          def initialize(argv)
            super
          end

          def run
            objects = CBin::OSS::Helper.instance.list
            objects.each do |o|
              path = "#{CBin::OSS::Helper.instance.url_path}/#{o.key}"
              UI.puts path.green
            end
          end
        end
      end
    end
  end
end
