require 'net/https'
require 'uri'
require 'json'

module Pod
  class Command
    class Bin < Command
      class Model < Bin
        self.summary = '生成模型文件'

        def initialize(argv)
          @url = argv.shift_argument
          @models = []
        end

        def run
          uri = URI.parse(@url)
          res = Net::HTTP.get_response(uri)
          res_body = JSON.parse(res.body)
          detail_msg = res_body['detailMsg']
          fetch_models(nil, detail_msg) if detail_msg
          print_models
        end

        def validate!
          help! "请输入url" unless @url
        end

        def fetch_models(name, obj)
          model = obj
          model = obj.first if obj.respond_to? :<<
          @models.unshift({name: name, value: model})
          model.each do |key, value|
            if (value.instance_of? Hash) || (value.instance_of? Array)
              fetch_models(key, value)
            end
          end
        end

        def print_models
          @models.each do |model|
            model_name = ''
            model_name = model[:name].gsub('List', '').gsub('Vo', '').gsub(/^\w/) { $&.upcase } if model[:name]
            puts "@interface ML#{model_name}Model : NSObject"
            model[:value].each do |key, value|
              print_property(key, value)
            end
            puts "@end\n\n"
            puts "@implementation ML#{model_name}Model"
            if model[:name]
              puts "+(NSDictionary *)modelContainerPropertyGenericClass {"
              puts "  return @{@\"#{model[:name]}\" : ML#{model_name}Model.class};"
              puts "}"
            end
            puts "@end\n\n\n"
          end
        end

        def print_property(key, value)
          if value.instance_of? String
            puts "///#{value}"
            puts "@property (nonatomic, copy) NSString *#{key};"
          elsif value.instance_of? Integer
            puts "///#{value}"
            puts "@property (nonatomic, assign) NSInteger #{key};"
            puts "///#{value}" if value > 1000
            puts "@property (nonatomic, strong) MLCentNumber *#{key};" if value > 1000
          elsif value.instance_of? Float
            puts "///#{value}"
            puts "@property (nonatomic, assign) CGFloat #{key};"
          elsif (value.instance_of? TrueClass) || (value.instance_of? FalseClass)
            puts "///#{value}"
            puts "@property (nonatomic, assign) BOOL #{key};"
          elsif value.instance_of? Array
            puts "///#{key}"
            name = key.gsub('List', '').gsub('Vo', '').gsub(/^\w/) { $&.upcase }
            puts "@property (nonatomic, strong) NSArray<ML#{name}Model *> *#{key};"
          elsif value.instance_of? Hash
            puts "///#{key}"
            name = key.gsub('List', '').gsub('Vo', '').gsub(/^\w/) { $&.upcase }
            puts "@property (nonatomic, strong) ML#{name}Model *#{key};"
          end
        end
      end
    end
  end
end
