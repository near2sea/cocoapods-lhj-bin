require 'cocoapods-lhj-bin/helpers/oss_helper'

module Pod
  class Command
    class Bin < Command
      class Local < Bin
        class Upload < Local
          self.summary = '上传中英文对照csv文件'

          def self.options
            [
              %w[--upload-file 上传中英文对照csv文件名]
            ]
          end

          def initialize(argv)
            @pwd_path = argv.shift_argument || Dir.pwd
            @upload_csv_file = argv.option('upload-file', '*.csv')
            super
          end

          def csv_file_name
            file_name = @upload_csv_file
            file_name = "#{@upload_csv_file}.csv" unless /.csv$/ =~ @upload_csv_file
            file_name
          end

          def csv_oss_key(file_name)
            "csv/#{Time.now.to_i}/#{file_name}"
          end

          def run
            csv_files = File.join(@pwd_path, '**', csv_file_name)
            Dir.glob(csv_files).each do |f|
              file_name = File.basename(f)
              oss_key = csv_oss_key file_name
              CBin::OSS::Helper.instance.upload(oss_key, f)
              url = CBin::OSS::Helper.instance.object_url(oss_key)
              UI.puts "云端上传成功.下载Url：#{url}\n".green
            end
          end
        end
      end
    end
  end
end
