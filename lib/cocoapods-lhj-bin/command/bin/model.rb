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
          @model_pre_name = argv.option('model-pre', 'ML')
          @models = []
        end

        def run
          uri = URI.parse(@url)
          res = Net::HTTP.get_response(uri)
          res_body = JSON.parse(res.body)
          detail_msg = res_body['detailMsg']
          fetch_models(nil, detail_msg) if detail_msg
          print_models
          print_models_implementation
        end

        def validate!
          help! "请输入url" unless @url
        end

        def fetch_models(name, obj)
          model = obj
          model = obj.first if obj.respond_to? :<<
          @models.unshift({name: name, value: model}) if model.instance_of? Hash
          if model.instance_of? Hash
            model.each do |key, value|
              if (value.instance_of? Hash) || (value.instance_of? Array)
                fetch_models(key, value)
              end
            end
          end
        end

        def print_models
          @models.each do |model|
            model_name = ''
            model_name = model[:name].gsub('List', '').gsub('Vo', '').gsub(/^\w/) { $&.upcase } if model[:name]
            puts "@interface #{@model_pre_name}#{model_name}Model : NSObject"
            model[:value].each do |key, value|
              print_property(key, value)
            end
            puts "@end\n\n\n"
          end
        end

        def print_models_implementation
          @models.each do |model|
            model_name = model[:name].gsub('List', '').gsub('Vo', '').gsub(/^\w/) { $&.upcase } if model[:name]
            puts "@implementation #{@model_pre_name}#{model_name}Model"
            puts "+(NSDictionary *)modelContainerPropertyGenericClass {"
            puts "  return @{@\"#{model[:name]}\" : #{@model_pre_name}#{model_name}Model.class};"
            puts "}"
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
            if value.first.instance_of? String
              puts "///#{key}"
              puts "@property (nonatomic, strong) NSArray<NSString *> *#{key};"
            else
              puts "///#{key}"
              name = key.gsub('List', '').gsub('Vo', '').gsub(/^\w/) { $&.upcase }
              puts "@property (nonatomic, strong) NSArray<#{@model_pre_name}#{name}Model *> *#{key};"
            end
          elsif value.instance_of? Hash
            puts "///#{key}"
            name = key.gsub('List', '').gsub('Vo', '').gsub(/^\w/) { $&.upcase }
            puts "@property (nonatomic, strong) #{@model_pre_name}#{name}Model *#{key};"
          else
            puts "///#{value}"
            puts "@property (nonatomic, copy) NSString *#{key};"
          end
        end
      end
    end
  end
end
