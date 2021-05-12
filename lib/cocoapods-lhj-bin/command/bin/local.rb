# frozen_string_literal: true
require 'csv'

module Pod
  class Command
    class Bin < Command
      class Local < Bin
        self.summary = '生成国际化文件'

        def initialize(argv)
          @current_path = argv.shift_argument || Dir.pwd
          @key_map = {}
          @trans_map = {}
          @trans_map_invert = {}
          super
        end

        def run
          load_trans_map
          read_csv_file
          write_en_strings
          write_zh_hans_strings
        end

        def en_dir_name
          'en.lproj'
        end

        def zh_hans_dir_name
          'zh-Hans.lproj'
        end

        def zh_hant_dir_name
          'zh-Hant.lproj'
        end

        def generate_file_name
          'Localizable.strings'
        end

        def yaml_file
          File.join(Pod::Config.instance.home_dir, 'zh2hant.yml')
        end

        def load_trans_map
          require 'yaml'
          down_load_yaml unless File.exist?(yaml_file)
          contents = YAML.safe_load(File.open(yaml_file))
          @trans_map = contents.to_hash
          @trans_map_invert = @trans_map.invert
        end

        def down_load_yaml
          require 'open-uri'
          UI.puts "开始下载简繁配置文件...\n"
          URI.open('http://aomi-ios-repo.oss-cn-shenzhen.aliyuncs.com/zh2hant.yml') do |i|
            File.open(yaml_file, 'w+') do |f|
              f.write(i.read)
            end
          end
        end

        def read_csv_file
          Dir.glob("#{@current_path}/**/*.csv").each do |p|
            CSV.foreach(p) { |row| @key_map[row[0]] = { zh: row[1], en: row[3] } unless row[0] =~ /[\u4e00-\u9fa5]/ }
          end
        end

        def format_str(type)
          str = ''
          @key_map.each do |k, v|
            reg = /#{@trans_map_invert.keys}/
            val = v[type].gsub(reg) { |s| @trans_map_invert[s] }
            str += "\"#{k}\" = \"#{val}\";\n"
          end
          str
        end

        def write_to_file(file, type)
          FileUtils.rm_rf(file) if File.exist?(file)
          FileUtils.mkdir_p(File.dirname(file)) unless File.exist?(File.dirname(file))
          File.open(file, 'w+') do |f|
            str = format_str(type)
            f.write(str)
          end
        end

        def write_en_strings
          file = File.join(@current_path, en_dir_name, generate_file_name)
          write_to_file(file, :en)
        end

        def write_zh_hans_strings
          file = File.join(@current_path, zh_hans_dir_name, generate_file_name)
          write_to_file(file, :zh)
        end

        def write_zh_hant_strings
          file = File.join(@current_path, zh_hant_dir_name, generate_file_name)
          write_to_file(file, :zh)
        end

      end
    end
  end
end
