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
          @key_map = {}
          super
        end

        def run
          handle_files
          gen_csv
          # update_source_header
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
            csv << %w[国际化key 中文 英文 所在文件 文件路径]
            @cn_keys.each do |k|
              csv << [k[:key], k[:cn], k[:en], k[:fname], k[:dirname]]
            end
          end
          UI.puts "生成csv文件完成.\n文件路径：#{File.absolute_path(file)}".green
        end

        def handle_files
          Dir.glob("#{@current_path}/**/*.{#{@file_type}}").each do |f|
            dir_name = File.dirname(f)
            if /Pods/ =~ f
              mod_name = framework_name(dir_name)
              handle_file f if /^ML/ =~ mod_name
            else
              handle_file f
            end
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
          line.scan(zh_ch_reg) do |str|
            fname = File.basename(file)
            dir_name = File.dirname(file)
            mod_name = framework_name(dir_name)
            key = "#{mod_name}.#{File.basename(file, '.*')}.#{rand(36**8).to_s(36)}"
            cn_str = str[2, str.length - 3]
            en_str = cn_str.gsub(/[\u4e00-\u9fa5]/, 'x')
            @cn_keys << { key: key, cn: cn_str, en: en_str, fname: fname, dirname: dir_name }
          end
        end

        def framework_name(path)
          mod_name = 'Main'
          if /pods/i =~ path
            ary = path.split('/')
            index = ary.find_index { |p| p.eql?('Pods') }
            if index
              i = index + 1
              mod_name = ary[i]
            end
          end
          mod_name
        end

        def handle_static_line(file, line)
          line.scan(zh_ch_reg) do |str|
            ma = line.match(/\*.*=/)
            key = ma[0][1, ma[0].length - 2].strip
            @key_map[key.to_sym] = str
          end
        end

        def update_source_header
          Dir.glob("#{@current_path}/**/*.{m,h}").each do |f|
            if f =~ /Pods/
              handler_file(f) if f =~ %r{Pods/MLF} || f =~ %r{Pods/MLU} || f =~ %r{Pods/MLN}
            else
              handler_file(f)
            end
          end
        end

        def handler_file(file)
          puts "#{File.absolute_path(file)} \n"
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
          unless /static/ =~ line
            @key_map.each_key do |key|
              n_key = /#{key.to_s}\s/
              n_val = "#{@key_map[key]}\s"
              result = result.gsub(n_key, n_val)
            end
          end
          result
        end

      end
    end
  end
end
