require 'yaml'
require 'cocoapods-lhj-bin/helpers/oss_helper'

module CBin
  class LocalConfig
    def config_file
      File.join(Pod::Config.instance.home_dir, config_file_name)
    end

    def config_file_name
      'localizable_config.yml'
    end

    def syn_config_file
      CBin::OSS::Helper.instance.down_load(config_file_name, config_file)
    end

    def default_config
      { 'gen_en_dir' => 'local_gen/en.lproj',
        'gen_zh_hk_dir' => 'local_gen/zh-Hant.lproj',
        'gen_zh_cn_dir' => 'local_gen/zh-Hans.lproj',
        'gen_file_name' => 'Localizable.strings',
        'source_format_string' => 'NSLocalizedString(%s, @"")',
        'csv_key_col' => 0,
        'csv_cn_col' => 1,
        'csv_en_col' => 2,
        'read_csv_file' => '*.csv',
        'gen_zh_cn' => true,
        'trans_zh_hk' => false,
        'trans_zh_cn' => false,
        'download' => false,
        'download_csv' => 'zh_en.csv' }
    end

    def load_config
      syn_config_file unless File.exist?(config_file)
      YAML.load_file(config_file) || default_config
    end

    def config
      @config ||= load_config
    end

    def self.instance
      @instance ||= new
    end

  end
end
