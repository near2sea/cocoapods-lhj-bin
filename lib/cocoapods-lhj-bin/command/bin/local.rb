require 'csv'

module Pod
  class Command
    class Bin < Command
      class Local < Bin
        self.summary = '国际化文件变更'

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

        def read_csv_file
          path = "#{@current_path}/b_lvr_land_a_land.csv"
          CSV.foreach(path) { |row| @key_map[row[0]] = { zh: row[1], en: row[3] } unless row[0] =~ /[\u4e00-\u9fa5]/ }
        end

        def file_str(type)
          str = ''
          @key_map.each do |k, v|
            str += "\"#{k}\" = \"#{v[type]}\";\n"
          end
          str
        end

        def write_to_file(file, type)
          FileUtils.rm_rf(file) if File.exist?(file)
          File.open(file, 'w+') do |f|
            str = file_str(type)
            f.write(str)
          end
        end

        def write_en_strings
          file = "#{@current_path}/Main_en.strings"
          write_to_file(file, :en)
        end

        def write_zh_hans_strings
          file = "#{@current_path}/Main_zh_hans.strings"
          write_to_file(file, :zh)
        end

      end
    end
  end
end
