# frozen_string_literal: true

require 'csv'
require 'cocoapods-lhj-bin/helpers/trans_helper'
require 'cocoapods-lhj-bin/helpers/oss_helper'
require 'cocoapods-lhj-bin/config/local_config'

module Pod
  class Command
    class Bin < Command
      class Local < Bin
        self.summary = '根据中英文对照csv文件，生成国际化配置, 及批量更新源码(使用国际化写法)'

        def self.options
          [
            %w[--key-col 国际化key在csv中第几列，默认为0],
            %w[--cn-col 中文在csv中第几列，默认为1],
            %w[--en-col 英文在csv中第几列，默认为2],
            %w[--download-csv 云端下载cvs的文件名],
            %w[--read-csv-file 读取csv的文件名，默认为当前目录下所有csv文件],
            %w[--gen-file 生成配置文件名，默认名为:Localizable.strings],
            %w[--modify-source 修改源码，使用国际化key代替中文字符串],
            %w[--modify-file-type 需要修改源码的文件类型，默认为m,h],
            %w[--modify-format-string 修改为国际化后的字符格式，默认为NSLocalizedString(%s,@"")]
          ]
        end

        def initialize(argv)
          @current_path = argv.shift_argument || Dir.pwd
          @key_col = argv.option('key-col', CBin::LocalConfig.instance.config['csv_key_col']).to_i
          @cn_col = argv.option('cn-col', CBin::LocalConfig.instance.config['csv_cn_col']).to_i
          @en_col = argv.option('en-col', CBin::LocalConfig.instance.config['csv_en_col']).to_i
          @download_csv_files = argv.option('download-csv')
          @read_csv_file = argv.option('read-csv-file', CBin::LocalConfig.instance.config['read_csv_file'])
          @gen_file_name = argv.option('gen-file', CBin::LocalConfig.instance.config['gen_file_name'])
          @modify_source_flag = argv.flag?('modify-source', false)
          @modify_file_type = argv.option('modify-file-type', 'm,h')
          @modify_format_string = argv.option('modify-format-string', CBin::LocalConfig.instance.config['source_format_string'])
          @key_map = {}
          super
        end

        def run
          down_load_csv_file if need_download
          read_csv
          if @key_map.keys.length.positive?
            write_en_strings
            write_zh_hk_strings
            write_zh_cn_strings
            handle_modify_source if @modify_source_flag
          else
            UI.puts "获取中英文映射文件失败, 检查参数--read-csv-file=xx是否正常\n".red
          end
        end

        def en_dir_name
          CBin::LocalConfig.instance.config['gen_en_dir']
        end

        def zh_hk_dir_name
          CBin::LocalConfig.instance.config['gen_zh_hk_dir']
        end

        def zh_cn_dir_name
          CBin::LocalConfig.instance.config['gen_zh_cn_dir']
        end

        def generate_file_name
          @gen_file_name
        end

        def need_download
          @download_csv_files || CBin::LocalConfig.instance.config['download']
        end

        def download_cvs_str
          @download_csv_files || CBin::LocalConfig.instance.config['download_csv']
        end

        def read_csv_file_name
          file_name = @read_csv_file
          file_name = "#{@read_csv_file}.csv" unless /.csv$/ =~ @read_csv_file
          file_name
        end

        def down_load_csv_file
          ary = get_download_keys
          ary.each do |key|
            file_name = File.basename(key)
            file = File.join(@current_path, file_name)
            backup_csv_file file if File.exist?(file)
            UI.puts "下载csv文件:#{CBin::OSS::Helper.instance.object_url(key)} 到目录#{file}\n".green
            CBin::OSS::Helper.instance.down_load(key, file)
          end
          UI.puts "下载云端csv文件完成 \n".green
        end

        def backup_csv_file(file)
          dest_file = bak_file(file)
          FileUtils.mkdir_p(File.dirname(dest_file)) unless File.exist?(File.dirname(dest_file))
          UI.puts "备份csv文件:#{file} 到目录#{dest_file}".green
          FileUtils.cp file, dest_file
          FileUtils.rm_rf file
        end

        def bak_file(file)
          dest_file = File.join(File.dirname(file), 'csv_bak', File.basename(file))
          File.exist?(dest_file) ? bak_file(dest_file) : dest_file
        end

        def get_download_keys
          download_keys = []
          csv_files = download_cvs_str.split(/,/).map(&:strip)
          all_keys = CBin::OSS::Helper.instance.list.map(&:key)
          csv_files.each do |f|
            arr = all_keys.select { |k| %r{^csv/} =~ k && /#{f}/ =~ k }
            if arr.count.positive?
              arr.sort! { |a, b| b.split(%r{/})[1].to_i <=> a.split(%r{/})[1].to_i }
              download_keys << arr[0]
            end
          end
          download_keys
        end

        def read_csv
          path = File.join(@current_path, read_csv_file_name)
          Dir.glob(path).each do |f|
            read_csv_file f
          end
        end

        def read_csv_file(file)
          key_c = CBin::LocalConfig.instance.get_col_by_name(file, 'csv_key_col')
          cn_c = CBin::LocalConfig.instance.get_col_by_name(file, 'csv_cn_col')
          en_c = CBin::LocalConfig.instance.get_col_by_name(file, 'csv_en_col')
          trans_hk = CBin::LocalConfig.instance.get_col_by_name(file, 'trans_zh_hk')
          trans_cn = CBin::LocalConfig.instance.get_col_by_name(file, 'trans_zh_cn')
          CSV.foreach(file) do |row|
            if row.length > 2
              key = row[key_c]
              cn_str = row[cn_c]
              hk_str = row[cn_c]
              cn_str = CBin::Trans::Helper.instance.trans_zh_cn_str(cn_str) if trans_cn
              hk_str = CBin::Trans::Helper.instance.trans_zh_hk_str(hk_str) if trans_hk
              @key_map[key] = { key: key, cn: cn_str, hk: hk_str, en: row[en_c] } unless key =~ /[\u4e00-\u9fa5]/
            end
          end
        end

        def handle_modify_source
          UI.puts '修改源码开始'
          Dir.glob("#{@current_path}/**/*.{#{@modify_file_type}}").each do |f|
            # handle_modify_file f if File.stat(f).writable?
            if f =~ /Pods/
              handle_modify_file(f) if f =~ %r{Pods/ML}
            else
              handle_modify_file(f)
            end
          end
          UI.puts '修改源码结束'
        end

        def handle_modify_file(file)
          File.chmod(0o644, file)
          str = modify_file_string(file)
          File.open(file, 'w+') do |f|
            f.write(str)
          end
          File.chmod(0o444, file) if file =~ /Pods/
        end

        def modify_file_string(file)
          str = ''
          File.open(file, 'r') do |f|
            f.each_line do |line|
              str += modify_format_string(f, line)
            end
          end
          str
        end

        def zh_ch_reg
          /@"[^"]*[\u4e00-\u9fa5]+[^"]*"/
        end

        def modify_format_string(file, line)
          result = line
          result = handle_modify_line(file, line) if zh_ch_reg =~ line && !((/DDLog/ =~ line) || (/NSLog/ =~ line))
          result
        end

        def handle_modify_line(file, line)
          result = line
          line.scan(zh_ch_reg) do |m|
            key = find_key_by_cn_val(file, m)
            if key
              val = format(@modify_format_string, "@\"#{key}\"")
              result = result.gsub(m, val)
            end
          end
          result
        end

        def find_key_by_cn_val(file, val)
          file_name = File.basename(file, '.*')
          cn_key = val[2, val.length - 3]
          index = @key_map.values.find_index { |obj| cn_key.eql?(obj[:zh]) && /#{file_name}/ =~ obj[:key] }
          index ||= @key_map.values.find_index { |obj| cn_key.eql?(obj[:zh]) }
          @key_map.values[index][:key] if index
        end

        def format_str(type)
          str = ''
          @key_map.each do |k, v|
            str += "\"#{k}\" = \"#{v[type]}\";\n"
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
          gen_zh_cn_strings_file
        end

        def gen_zh_cn_strings_file
          file = File.join(@current_path, zh_cn_dir_name, generate_file_name)
          content = format_str(:cn)
          write_to_file(file, content)
          UI.puts "生成简体中文配置完成.文件路径：#{File.absolute_path(file)}\n".green
        end

        def copy_hk_to_cn_file
          source_file = File.join(@current_path, zh_hk_dir_name, generate_file_name)
          dest_file = File.join(@current_path, zh_cn_dir_name, generate_file_name)
          FileUtils.cp source_file, dest_file
          UI.puts "繁体中文配置覆盖简体中文配置\n".green
        end

        def write_zh_hk_strings
          file = File.join(@current_path, zh_hk_dir_name, generate_file_name)
          content = format_str(:hk)
          write_to_file(file, content)
          UI.puts "生成繁体中文配置完成.文件路径：#{File.absolute_path(file)}\n".green
        end
      end
    end
  end
end
