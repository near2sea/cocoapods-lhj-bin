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
          super
        end

        def run
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

        def load_yaml_from_remote
          require 'open-uri'
          key_map = {}
          URI.open('http://aomi-ios-repo.oss-cn-shenzhen.aliyuncs.com/zh2hant.yml') do |f|
            key_map = YAML.safe_load(f.read)
          end
          puts key_map
        end

        def read_csv_file
          Dir.glob("#{@current_path}/**/*.csv").each do |p|
            CSV.foreach(p) { |row| @key_map[row[0]] = { zh: row[1], en: row[3] } unless row[0] =~ /[\u4e00-\u9fa5]/ }
          end
        end

        def format_str(type)
          str = ''
          @key_map.each do |k, v|
            str += "\"#{k}\" = \"#{v[type]}\";\n"
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
