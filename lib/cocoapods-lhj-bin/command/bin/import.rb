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
          @header_folder_map = {}
          super
        end

        def run
          generate_header_map
          # say_header_map
          # find_all_sub_folder
          update_source_header
        end

        # @return [@header_map]
        def generate_header_map
          framework_headers = {}
          folders = child_dir
          folders.each { |name| framework_headers[name] = all_header_map(name) }
          framework_headers.each do |key, value|
            value.each do |header|
              header_key = "\"#{header}\""
              framework_name = framework_name_map[key.to_sym] || key
              @header_map[header_key.to_sym] = "<#{framework_name}/#{header}>"
              @header_folder_map[header_key.to_sym] = key
            end
          end
        end

        def framework_name_map
          { 'lottie-ios': 'Lottie', 'UITableView+FDTemplateLayoutCell': 'UITableView_FDTemplateLayoutCell', 'mob_sharesdk': 'ShareSDK' }
        end

        def framework_black_list
          %w[mob_sharesdk]
        end

        def say_header_map
          @header_map.each do |key, value|
            puts "#{key}===> #{value}"
          end
        end

        def pod_folder_name
          File.directory?("#{@current_path}/Pods") ? "#{@current_path}/Pods" : "#{@current_path}/Example/Pods"
        end

        def child_dir
          dirs = Dir.entries(pod_folder_name)
          dirs.reject! do |d|
            File.directory?(d) || /\./ =~ d || /_Prebuild/ =~ d || /Target/ =~ d || /Headers/ =~ d || /Podspecs/ =~ d || framework_black_list.any?{ |f| f == d }
          end
          dirs
        end

        def all_header_map(folder)
          headers = Dir.glob("#{pod_folder_name}/#{folder}/**/*.h")
          headers.map! { |f| f.split('/').last }
          headers
        end

        def find_all_sub_folder
          Find.find(@current_path).each do |f|
            handler_file f if f =~ /APPDelegate/
          end
        end

        def update_source_header
          Dir.glob("#{@current_path}/**/*.{m,h,pch}").each do |f|
            if f =~ /Pods/
              handler_file(f) if f =~ %r{Pods/ML}
            else
              handler_file(f)
            end
          end
        end

        def handler_file(file)
          File.chmod(0o644, file)
          str = file_string(file)
          File.open(file, 'w+') do |f|
            f.write(str)
          end
          File.chmod(0o444, file) if file =~ /Pods/
        end

        def file_string(file)
          str = ''
          File.open(file, 'r+') do |f|
            f.each_line do |line|
              str += format_string(f, line)
            end
          end
          str
        end

        def format_string(file, line)
          result = line
          if line =~ /#import/
            ma = find_head_key(line)
            result = line.gsub(ma[0], @header_map[ma[0].to_sym] || ma[0]) if ma && !exist_in_file(file, ma[0])
          end
          result
        end

=begin
        def format_string(file, line)
          result = line
          if /(\W)(TicketList)(\W)/ =~ line
            result = result.gsub(/(\W)(TicketList)(\W)/, '\1TKTicketModel\3')
          end
          result
        end
=end

        def exist_in_file(file, header)
          folder_name = @header_folder_map[header.to_sym]
          Regexp.new("/Pods/#{folder_name}") =~ File.path(file) if folder_name
        end

        def find_head_key(line)
          header_reg = /"\D*.h"/
          line.match(header_reg)
        end
      end
    end
  end
end
