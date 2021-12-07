# frozen_string_literal: true
require 'cocoapods-lhj-bin/helpers/trans_helper'

module Pod
  class Command
    class Bin < Command
      class Trans < Bin
        self.summary = '源码中的简繁体转换'

        def self.options
          [
            %w[--file-type 文件扩展名，默认为m,h,pch,xib],
            %w[--zh-cn 转成简体中文，默认转成繁体]
          ]
        end

        def initialize(argv)
          @current_path = argv.shift_argument || Dir.pwd
          @file_type = argv.option('file-type', 'm,h,pch,xib')
          @zh_cn = argv.flag?('zh-cn', false)
          super
        end

        def run
          handler_files
          # rename
        end

        def rename
          folder_path = "/Users/lihaijian/Downloads/ss"
          Dir.glob("#{folder_path}/**/*.{png}").sort.each do |f|
            filename = File.basename(f, File.extname(f))
            File.rename(f, "#{folder_path}/aomi_soldout_" + filename.capitalize + File.extname(f))
          end
        end

        def handler_files
          Dir.glob("#{@current_path}/**/*.{#{@file_type}}").each do |f|
              handler_file f
            end
          end

        def handler_file(file)
          File.chmod(0o644, file) unless File.writable?(file)
          str = format_file_string(file)
          File.open(file, 'w+') do |f|
            f.write(str)
          end
        end

        def format_file_string(file)
          str = ''
          File.open(file, 'r+') do |f|
            f.each_line do |line|
              str += format_line_string(line)
            end
          end
          str
        end

        def format_line_string(line)
          result = line
          if line =~ /[\u4e00-\u9fa5]/
            result = CBin::Trans::Helper.instance.trans_zh_cn_str(line) if @zh_cn
            result = CBin::Trans::Helper.instance.trans_zh_hk_str(line) unless @zh_cn
          end
          result
        end

      end
    end
  end
end
