
module CBin
  class Trans
    class Helper

      def self.instance
        @instance ||= new
      end

      def yaml_file
        File.join(Pod::Config.instance.home_dir, 'zh2hant.yml')
      end

      def load_trans_map
        require 'yaml'
        down_load_yaml unless File.exist?(yaml_file)
        contents = YAML.safe_load(File.open(yaml_file))
        contents.to_hash
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

      def trans_zh_cn_str(input)
        @trans_map_invert ||= load_trans_map.invert
        out = []
        input.each_char do |c|
          out << (@trans_map_invert[c] || c)
        end
        out.join('')
      end

      def trans_zh_hk_str(input)
        @trans_map ||= load_trans_map
        out = []
        input.each_char do |c|
          out << (@trans_map[c] || c)
        end
        out.join('')
      end
    end
  end
end
