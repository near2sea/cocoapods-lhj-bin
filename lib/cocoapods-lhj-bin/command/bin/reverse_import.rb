# frozen_string_literal: true

require 'find'
require 'fileutils'

module Pod
  class Command
    class Bin < Command
      class ReverseImport < Bin
        self.summary = '更改头文件引入'

        def initialize(argv)
          @current_path = argv.shift_argument || Dir.pwd
          @framework_names = []
          super
        end

        def run
          get_all_frameworks
          get_import_headers
        end

        def get_import_headers
          Dir.glob("#{@current_path}/**/*.{m,h,pch}").each do |f|
              header_handler_file(f) unless f =~ /Pods/
          end
        end

        def get_all_frameworks
          folders = child_dir
          folders.each { |name| @framework_names << name }
        end

        def framework_name_reg
          @url_key_reg ||= begin
                             keys = @framework_names.join('|')
                             /#{keys}/
                           end
          @url_key_reg
        end

        def pod_folder_name
          File.join(@current_path, 'MacauLife', 'CustomPods')
        end

        def child_dir
          dirs = Dir.entries(pod_folder_name)
          dirs.reject!{ |d| File.directory?(d) }
          dirs
        end

        def import_reg
          /#import\s*<(.*)\/(.*)>$/
        end

        def header_handler_file(f)
          str = ''
          File.readlines(f).each do |l|
            if import_reg =~ l
              ma = l.match(import_reg)
              if framework_name_reg =~ ma[1]
                str += "#import \"#{ma[2]}\"\n"
              else
                str += l.dup
              end
            else
              str += l.dup
            end
          end
          File.write(f, str)
        end

      end
    end
  end
end
