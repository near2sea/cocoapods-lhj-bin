# frozen_string_literal: true

require 'csv'

module Pod
  class Command
    class Bin < Command
      class Fetch < Bin
        self.summary = '提取源码的中文字符串，并生成中英文对照csv文件'

        def self.options
          [
            %w[--file-type 从文件扩展名中查找中文字符串，默认为m,h],
            %w[--file-name 生成csv文件名，默认为gen_cn_key.csv]
          ]
        end

        def initialize(argv)
          @current_path = argv.shift_argument || Dir.pwd
          @file_type = argv.option('file-type', 'm,h')
          @file_name = argv.option('file-name', 'gen_cn_key.csv')
          @cn_keys = []
          super
        end

        def run
          handle_files
          gen_csv
        end

        def csv_file_name
          file_name = @file_name
          file_name = "#{@file_name}.csv" unless /.csv$/ =~ @file_name
          file_name
        end

        def gen_csv
          file = File.join(@current_path, csv_file_name)
          FileUtils.rm_rf(file) if File.exist?(file)
          CSV.open(file, 'wb:utf-8') do |csv|
            csv << %w[国际化key 中文 英文 原字符 所在文件 文件路径]
            @cn_keys.each do |k|
              csv << [k[:key], k[:cn], k[:en], k[:str], k[:fname], k[:dirname]]
            end
          end
          UI.puts "生成csv文件完成.\n文件路径：#{File.absolute_path(file)}".green
        end

        def handle_files
          Dir.glob("#{@current_path}/**/*.{#{@file_type}}").each do |f|
            handle_file f
          end
        end

        def zh_ch_reg
          /@"[^"]*[\u4e00-\u9fa5]+[^"]*"/
        end

        def handle_file(file)
          File.open(file, 'r') do |f|
            f.each_line do |line|
              handle_line(file, line) if zh_ch_reg =~ line
            end
          end
        end

        def handle_line(file, line)
          ma = zh_ch_reg.match(line)
          arr = ma.to_a
          arr.each do |str|
            key = "#{File.basename(file, '.*')}.#{rand(36**8).to_s(36)}"
            @cn_keys << { key: key, cn: str[2, str.length - 3], en: '', str: str, dirname: File.dirname(file),
                          fname: File.basename(file) }
          end
        end
      end
    end
  end
end
