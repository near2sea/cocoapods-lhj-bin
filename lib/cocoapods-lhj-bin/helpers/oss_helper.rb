require 'aliyun/oss'
require 'cocoapods-lhj-bin/config/config'

module CBin
  class OSS
    class Helper
      def initialize
        @client = Aliyun::OSS::Client.new(endpoint: CBin.config.oss_endpoint,
                                          access_key_id: CBin.config.oss_access_key_id,
                                          access_key_secret: CBin.config.oss_access_key_secret)
        @bucket = @client.get_bucket(CBin.config.oss_bucket)
      end

      def url_path
        "http://#{CBin.config.oss_bucket}.#{CBin.config.oss_endpoint}"
      end

      def upload(key, file)
        @bucket.put_object(key, :file => file)
      end

      def list
        @bucket.list_objects
      end

      def delete(key)
        @bucket.delete_object(key)
      end

      def self.instance
        @instance ||= new
      end
    end
  end
end
