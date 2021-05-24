# frozen_string_literal: true

require 'csv'

module Pod
  class Command
    class Bin < Command
      class Filter < Bin
        self.summary = '过滤重复对象'

        def initialize(argv)
          @current_path = argv.shift_argument || Dir.pwd
          @file_type = argv.option('file-type', 'm,h')
          @file_name = argv.option('file-name', 'MaucaoLife_zh_en.csv')
          @cn_keys = []
          @key_map = {}
          @used_keys = []
          super
        end

        def run
          fetch_keys
          read_csv
          gen_csv
        end

        def csv_file_name
          file_name = @file_name
          file_name = "#{@file_name}.csv" unless /.csv$/ =~ @file_name
          file_name
        end

        def read_csv
          path = File.join(@current_path, csv_file_name)
          Dir.glob(path).each do |p|
            CSV.foreach(p) do |row|
              key = row[0]
              if @used_keys.any? { |k| k.eql?(key) }
                @cn_keys << { key: key, cn: row[1], en: row[2], fname: row[3], dirname: row[4] }
              end
            end
          end
        end

        def gen_csv
          file = File.join(@current_path, csv_file_name)
          FileUtils.rm_rf(file) if File.exist?(file)
          CSV.open(file, 'wb:utf-8') do |csv|
            csv << %w[国际化key 中文 英文 所在文件 文件路径]
            @cn_keys.each do |k|
              csv << [k[:key], k[:cn], k[:en], k[:fname], k[:dirname]]
            end
          end
          UI.puts "生成csv文件完成.\n文件路径：#{File.absolute_path(file)}".green
        end

        def fetch_keys
          Dir.glob("#{@current_path}/**/*.{#{@file_type}}").each do |f|
            handle_file f
          end
        end

        def zh_ch_reg
          /MLLocalizedString\([^)]+\)/
        end

        def handle_file(file)
          File.open(file, 'r') do |f|
            f.each_line do |line|
              handle_line(file, line) if zh_ch_reg =~ line
            end
          end
        end

        def handle_line(file, line)
          line.scan(zh_ch_reg) do |str|
            str[20, str.length - 22]
            @used_keys << str[20, str.length - 22]
          end
        end

      end
    end
  end
end
