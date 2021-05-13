# frozen_string_literal: true

require 'csv'

module Pod
  class Command
    class Bin < Command
      class Local < Bin
        self.summary = '生成国际化文件'

        def self.options
          [
            %w[--key Key在csv中第几列，默认为0],
            %w[--cn 中文在csv中第几列，默认为1],
            %w[--en 英文文在csv中第几列，默认为2]
          ]
        end

        def initialize(argv)
          @current_path = argv.shift_argument || Dir.pwd
          @key_col = argv.option('key').to_i || 0
          @cn_col = argv.option('cn', 1).to_i || 1
          @en_col = argv.option('en', 2).to_i || 2
          @key_map = {}
          @trans_map = {}
          @trans_map_invert = {}
          super
        end

        def run
          load_trans_map
          read_csv_file
          write_en_strings
          write_zh_cn_strings
          write_zh_hk_strings
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
            CSV.foreach(p) { |row| @key_map[row[@key_col]] = { zh: row[@cn_col], en: row[@en_col] } unless row[0] =~ /[\u4e00-\u9fa5]/ }
          end
        end

        def format_str(type, area = :cn)
          str = ''
          @key_map.each do |k, v|
            val = v[type]
            case area
            when :hk
              val = trans_zh_hk_str val
            when :cn
              val = trans_zh_cn_str val
            end
            str += "\"#{k}\" = \"#{val}\";\n"
          end
          str
        end

        def trans_zh_cn_str(input)
          out = []
          input.each_char do |c|
            out << (@trans_map_invert[c] || c)
          end
          out.join('')
        end

        def trans_zh_hk_str(input)
          out = []
          input.each_char do |c|
            out << (@trans_map[c] || c)
          end
          out.join('')
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
        end

        def write_zh_cn_strings
          file = File.join(@current_path, zh_cn_dir_name, generate_file_name)
          generate_file(file, :zh)
        end

        def write_zh_hk_strings
          file = File.join(@current_path, zh_hk_dir_name, generate_file_name)
          content = format_str(:zh, :hk)
          write_to_file(file, content)
        end
      end
    end
  end
end
