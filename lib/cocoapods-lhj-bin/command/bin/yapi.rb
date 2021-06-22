require 'net/https'
require 'uri'
require 'json'

module Pod
  class Command
    class Bin < Command
      class Yapi < Bin
        self.summary = '通过yapi接口生成请求'

        def initialize(argv)
          @id = argv.option('id')
          @model_pre_name = argv.option('model-pre')
          @headers = []
          @models = []
          @config_id = ''
          @config_model_pre = 'ML'
          @main_model = 'Main'
        end

        def run
          load_config
          fetch_model
          print_models
          print_models_implementation
        end

        def url_str
          "http://yapi.miguatech.com/api/interface/get?id=#{api_id}"
        end

        def load_config
          yml = File.join(Pod::Config.instance.home_dir, 'yapi.yml')
          config = YAML.load_file(yml)
          config.each do |k, v|
            @headers << "#{k}=#{v}" unless (k.eql?('id') || k.eql?('pre') || k.eql?('model'))
          end
          @config_id = config['id']
          @config_model_pre = config['pre']
          @main_model = config['model']
        end

        def api_id
          @id || @config_id
        end

        def model_pre
          @model_pre_name || @config_model_pre
        end

        def req_model
          uri = URI.parse(url_str)
          req = Net::HTTP::Get.new(uri)
          req['Cookie'] = @headers.join('; ')
          res = Net::HTTP.start(uri.hostname, uri.port) do |http|
            http.request(req)
          end
          puts res.body
          puts '\n\n'
          JSON.parse(res.body)
        end

        def fetch_model
          res_json = req_model
          if res_json && res_json['data'] && res_json['data']['res_body']
            begin
              res_body = JSON.parse(res_json['data']['res_body'])
              detail_obj = res_body['properties']['detailMsg'] || {}
              detail_obj['name'] = gen_model_name(@main_model)
              handle_model(detail_obj)
            rescue => ex
              puts ex
            end
          end
        end

        def gen_model_name(name)
          n = name.gsub('List', '').gsub(/(Vo|VO|vo|model|Model)/, '').gsub(/^\w/) { $&.upcase }
          "#{model_pre}#{n}Model"
        end

        def handle_model(model)
          p_type = model['type']
          p_name = model['name']
          p_properties = model['properties']
          p_model = { name: p_name }

          properties = []
          if p_type.eql?('object')
            p_properties.each do |k, v|
              c_model = {key: k, type: v['type'], description: v['description'], default: ''}
              if v['type'].eql?('object') || v['type'].eql?('array')
                o = v['items'] || v
                o['name'] = gen_model_name(k)
                if v['type'].eql?('array') && v['items']['type'].eql?('string')
                  c_model[:type_name] = "NSString"
                else
                  c_model[:type_name] = gen_model_name(k)
                  handle_model(o)
                end
              end
              properties << c_model
            end
            p_model[:properties] = properties
            @models << p_model
          elsif p_type.eql?('array')
            t = model['items']
            t['name'] = p_name
            handle_model(t)
          end
        end

        def print_models
          @models.each do |model|
            model_name = model[:name] || ''
            model_properties = model[:properties]
            puts "@interface #{model_name} : NSObject"
            model_properties.each do |m|
              print_model(m)
            end
            puts "@end\n\n\n"
          end
        end

        def print_models_implementation
          @models.each do |model|
            puts "@implementation #{model[:name]}"
            str = model[:properties].filter { |p| p[:type].eql?('array') && !p[:type_name].eql?('NSString') }.map{ |p| "@\"#{p[:key]}\": #{p[:type_name]}.class" }.join(', ')
            if str && str.length > 0
              puts "+(NSDictionary *)modelContainerPropertyGenericClass {"
              puts "  return @{#{str}};"
              puts "}"
            end
            puts "@end\n\n\n"
          end
        end

        def print_model(m)
          key = m[:key]
          type_name = m[:type_name]
          type = m[:type]
          des = m[:description] || ''
          des.gsub!(/\n/, '')
          default = m[:default]
          puts "///#{des} #{default}"
          if type.eql?('integer')
            puts "@property (nonatomic, assign) NSInteger #{key};"
          elsif type.eql?('cent')
            puts "@property (nonatomic, strong) MLCentNumber *#{key};"
          elsif type.eql?('string')
            puts "@property (nonatomic, copy) NSString *#{key};"
          elsif type.eql?('number')
            puts "@property (nonatomic, strong) NSNumber *#{key};"
          elsif type.eql?('float')
            puts "@property (nonatomic, assign) CGFloat #{key};"
          elsif type.eql?('double')
            puts "@property (nonatomic, assign) double #{key};"
          elsif type.eql?('boolean')
            puts "@property (nonatomic, assign) BOOL #{key};"
          elsif type.eql?('object')
            puts "@property (nonatomic, strong) #{type_name} *#{key};"
          elsif type.eql?('array')
            puts "@property (nonatomic, strong) NSArray<#{type_name} *> *#{key};"
          else
            puts "@property (nonatomic, copy) NSString *#{key};"
          end
        end
      end
    end
  end
end
