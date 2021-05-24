# frozen_string_literal: true

require 'csv'

module Pod
  class Command
    class Bin < Command
      class Service < Bin
        self.summary = '微服务名变更'

        def initialize(argv)
          @current_path = argv.shift_argument || Dir.pwd
          @file_type = argv.option('file-type', 'm,h')
          @file_name = argv.option('file-name', 'service_map.csv')
          @service_map = {}
          super
        end

        def run
          read_csv
          update_source
        end

        def read_csv
          path = File.join(@current_path, csv_file_name)
          Dir.glob(path).each do |p|
            CSV.foreach(p) do |row|
              @service_map[row[0]] = row[1] if row[0]
            end
          end
        end

        def csv_file_name
          file_name = @file_name
          file_name = "#{@file_name}.csv" unless /.csv$/ =~ @file_name
          file_name
        end

        def update_source
          Dir.glob("#{@current_path}/**/*.{m,h}").each do |f|
            if f =~ /Pods/
              update_file(f) if f =~ %r{Pods/ML}
            else
              update_file(f)
            end
          end
        end

        def update_file(file)
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
          if url_reg =~ line
            line.scan(url_reg).flatten.each do |key|
              result = result.gsub(key, @service_map[key]) if key && @service_map[key]
            end
          end
          result
        end

        def url_reg
          @url_key_reg ||= begin
                             keys = @service_map.keys.join('|')
                             /(#{keys})/
                           end
          @url_key_reg
        end

      end
    end
  end
end
