# frozen_string_literal: true

require 'csv'
require 'cocoapods-lhj-bin/helpers/trans_helper'

module Pod
  class Command
    class Bin < Command
      class Local < Bin
        self.summary = '根据中英文对照csv文件，生成国际化配置'

        def self.options
          [
            %w[--key-col 国际化key在csv中第几列，默认为0],
            %w[--cn-col 中文在csv中第几列，默认为1],
            %w[--en-col 英文在csv中第几列，默认为2],
            %w[--csv-file csv文件名，默认为当前目录下所有csv文件],
            %w[--gen-file 生成配置文件名，默认名为: Localizable.strings]
          ]
        end

        def initialize(argv)
          @current_path = argv.shift_argument || Dir.pwd
          @key_col = argv.option('key-col').to_i || 0
          @cn_col = argv.option('cn-col', 1).to_i || 1
          @en_col = argv.option('en-col', 2).to_i || 2
          @csv_file = argv.option('csv-file', '*')
          @gen_file_name = argv.option('gen-file', 'Localizable.strings')
          @key_map = {}
          super
        end

        def run
          read_csv_file
          if @key_map.keys.length.positive?
            write_en_strings
            write_zh_cn_strings
            write_zh_hk_strings
          end
        end

        def en_dir_name
          'en.lproj'
        end

        def zh_hk_dir_name
          'zh-hk.lproj'
        end

        def zh_cn_dir_name
          'zh-cn.lproj'
        end

        def generate_file_name
          @gen_file_name
        end

        def read_csv_file
          path = "#{@current_path}/#{@csv_file}.csv"
          Dir.glob(path).each do |p|
            CSV.foreach(p) { |row| @key_map[row[@key_col]] = { zh: row[@cn_col], en: row[@en_col] } unless row[0] =~ /[\u4e00-\u9fa5]/ }
          end
        end

        def format_str(type, area = :cn)
          str = ''
          @key_map.each do |k, v|
            val = v[type]
            case area
            when :hk
              val = CBin::Trans::Helper.instance.trans_zh_hk_str val
            when :cn
              val = CBin::Trans::Helper.instance.trans_zh_cn_str val
            end
            str += "\"#{k}\" = \"#{val}\";\n"
          end
          str
        end

        def write_to_file(file, contents)
          FileUtils.rm_rf(file) if File.exist?(file)
          FileUtils.mkdir_p(File.dirname(file)) unless File.exist?(File.dirname(file))
          File.open(file, 'w+') do |f|
            f.write(contents)
          end
        end

        def generate_file(file, type)
          content = format_str(type)
          write_to_file(file, content)
        end

        def write_en_strings
          file = File.join(@current_path, en_dir_name, generate_file_name)
          generate_file(file, :en)
          UI.puts "生成英文配置完成.文件路径：#{File.absolute_path(file)}\n".green
        end

        def write_zh_cn_strings
          file = File.join(@current_path, zh_cn_dir_name, generate_file_name)
          generate_file(file, :zh)
          UI.puts "生成简体中文配置完成.文件路径：#{File.absolute_path(file)}\n".green
        end

        def write_zh_hk_strings
          file = File.join(@current_path, zh_hk_dir_name, generate_file_name)
          content = format_str(:zh, :hk)
          write_to_file(file, content)
          UI.puts "生成繁体中文配置完成.文件路径：#{File.absolute_path(file)}\n".green
        end
      end
    end
  end
end
