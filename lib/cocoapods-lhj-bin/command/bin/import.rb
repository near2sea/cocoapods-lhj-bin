# frozen_string_literal: true

require 'find'
require 'fileutils'

module Pod
  class Command
    class Bin < Command
      class Import < Bin
        self.summary = '更改头文件引入'

        def initialize(argv)
          @current_path = argv.shift_argument || Dir.pwd
          @framework = argv.option('framework')
          @header_map = {}
          super
        end

        def run
          generate_header_map
          # find_all_sub_folder
          update_source_header
        end

        # @return [@header_map]
        def generate_header_map
          framework_headers = {}
          folders = child_dir
          folders.each do |name|
            framework_headers[name.to_sym] = all_header_map(name)
          end
          framework_headers.each do |key, value|
            value.each do |header|
              header_key = "\"#{header}\""
              @header_map[header_key] = "<#{key}/#{header}>"
            end
          end
        end

        def say_header_map
          @header_map.each do |key, value|
            puts "#{key}===> #{value}"
          end
        end

        def pod_folder_name
          "#{@current_path}/Pods"
        end

        def child_dir
          dirs = Dir.entries(pod_folder_name)
          dirs.reject! { |d| File.directory?(d) || /\./ =~ d || /_Prebuild/ =~ d || /Target/ =~ d || /Headers/ =~ d || /Podspecs/ =~ d }
          dirs
        end

        def all_header_map(folder)
          headers = Dir.glob("#{pod_folder_name}/#{folder}/**/*.h")
          headers.map! { |f| f.split('/').last }
          headers
        end

        def find_all_sub_folder
          Find.find(@current_path).each do |f|
            handler_file f if f =~ /.pch/
          end
        end

        def update_source_header
          Dir.glob("#{@current_path}/**/*.{m,h,pch}").each do |f|
            handler_file(f) unless f =~ /Pods/
          end
        end

        def handler_file(file)
          str = file_string(file)
          File.open(file, 'w+') do |f|
            f.write(str)
          end
        end

        def file_string(file)
          str = ''
          File.open(file, 'r+') do |f|
            f.each_line do |line|
              str += format_string(line)
            end
          end
          str
        end

        def format_string(line)
          result = line
          if line =~ /#import/
            head_key = find_head_key(line)
            result = line.gsub(head_key, @header_map[head_key]) if head_key
          end
          result
        end

        def find_head_key(line)
          header_reg = /"\w*.h"/
          ma = line.match(header_reg)
          head_key = @header_map.keys.find { |k| k =~ /#{ma[0]}/ } if ma
          head_key
        end
      end
    end
  end
end
