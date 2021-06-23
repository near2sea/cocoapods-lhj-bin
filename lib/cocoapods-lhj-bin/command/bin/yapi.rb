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
          @http_url = ''
          @http_headers = []
          @data_json = {}
          @models = []
          @config_id = ''
          @config_model_pre = 'ML'
          @type_trans = {}
          @config_model_names = []
          @model_names = []
        end

        def run
          load_config
          fetch_model
          print_models
          print_models_implementation
          print_methods
        end

        def url_str
          "#{@http_url}#{api_id}"
        end

        def load_config
          yml = File.join(Pod::Config.instance.home_dir, 'yapi.yml')
          config = YAML.load_file(yml)
          config.each do |k, v|
            @http_headers << "#{k}=#{v}" if (k.eql?('__wpkreporterwid_') || k.eql?('_yapi_token') || k.eql?('_yapi_uid'))
          end
          @http_url = config['url']
          @config_id = config['id']
          @config_model_pre = config['model_pre']
          @config_model_names = config['model_names']
          @type_trans = config['type_trans']
        end

        def api_id
          @id || @config_id.to_s
        end

        def model_pre
          @model_pre_name || @config_model_pre
        end

        def req_model
          uri = URI.parse(url_str)
          req = Net::HTTP::Get.new(uri)
          req['Cookie'] = @http_headers.join('; ')
          res = Net::HTTP.start(uri.hostname, uri.port) do |http|
            http.request(req)
          end
          puts res.body
          JSON.parse(res.body)
        end

        def fetch_model
          res_json = req_model
          if res_json && res_json['data']
            @data_json = res_json['data']
            if @data_json['res_body']
              begin
                res_body = JSON.parse(@data_json['res_body'])
                detail_obj = res_body['properties']['detailMsg'] || {}
                detail_obj['name'] = gen_model_name('')
                handle_model(detail_obj)
              rescue => ex
                puts ex
              end
            end
          end
        end

        def gen_model_name(name)
          n = name.gsub(/vo|model|list/i, '').gsub(/(.*)s$/, '\1').gsub(/^\w/) { $&.upcase }
          if n.length <= 0
            n = @config_model_names.detect{ |c| !@model_names.any?{ |n| n.gsub(/#{model_pre}(.*)Model/, '\1').eql?(c) } }
          end
          model_name = "#{model_pre}#{n}Model"
          @model_names << model_name
          model_name
        end

        def handle_model(model)
          p_type = model['type']
          p_name = model['name']
          p_properties = model['properties']
          p_model = { name: p_name }

          properties = []
          if p_type.eql?('object')
            p_properties.each do |k, v|
              c_type = @type_trans[v['type']] || v['type']
              c_model = {key: k, type: c_type, description: v['description'], default: ''}
              if v['type'].eql?('object') || v['type'].eql?('array')
                o = v['items'] || v
                o['name'] = gen_model_name(k)
                if v['type'].eql?('array') && v['items']['type'].eql?('string')
                  c_model[:type_name] = "NSString"
                else
                  c_model[:type_name] = o['name']
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
          puts "\n<===============打印模型=====================>\n"
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

        def print_methods
          puts "\n<===============方法调用=====================>\n"
          puts "/**"
          puts " *  #{@data_json['title']} -- #{@data_json['username']}"
          puts " */"
          key_str = @data_json['path'].split('/').map{ |s| s.gsub(/[^A-Za-z0-9]/, '').gsub(/^\w/){ $&.upcase } }.join('')
          key = "k#{key_str}URL"
          puts "static NSString * const #{key} = @\"#{@data_json['path']}\";"
          puts "\n\n"
          puts "@interface MLParamModel : NSObject"
          @data_json['req_query'].each do |h|
            puts "///#{h['desc']}  #{h['example']}"
            puts "@property (nonatomic, copy) NSString *#{h['name']}"
          end
          puts "@end"
          puts "\n\n"
          model = @models.last
          if @data_json['method'].eql?('GET')
            puts "    [MLNetworkingManager getWithUrl:#{key} params:nil response:^(MLResponseMessage *responseMessage) {"
            puts "        if (response.resultCode == 0 && !response.error){"
            puts "            NSDictionary *detailMsg = response.detailMsg"
            puts "            #{model[:name]} *model = [#{model[:name]} yy_modelWithDictionary:detailMsg];" if model
            puts "        }"
            puts "    }];"
          else
            puts "    [MLNetworkingManager postWithUrl:#{key} params:nil response:^(MLResponseMessage *responseMessage) {"
            puts "        if (response.resultCode == 0 && !response.error){"
            puts "            NSDictionary *detailMsg = response.detailMsg"
            puts "            #{model[:name]} *model = [#{model[:name]} yy_modelWithDictionary:detailMsg];" if model
            puts "        }"
            puts "    }];"
          end
        end
      end
    end
  end
end
