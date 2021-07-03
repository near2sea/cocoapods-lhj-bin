require 'net/https'
require 'uri'
require 'json'

module Pod
  class Command
    class Bin < Command
      class Yapi < Bin
        self.summary = '通过yapi接口生成请求'

        def self.options
          [
            %w[--id api的id],
            %w[--model-pre 模型的前缀],
            %w[--save 保存生成文件]
          ]
        end

        def initialize(argv)
          @id = argv.option('id')
          @model_pre_name = argv.option('model-pre')
          @save = argv.flag?('save', false)
          @http_url = ''
          @http_headers = []
          @data_json = {}
          @models = []
          @config_id = ''
          @config_model_pre = 'ML'
          @type_trans = {}
          @config_model_names = []
          @model_names = []
          super
        end

        def run
          load_config
          fetch_model
          print_methods
          save_to_file if @save
        end

        def test_ding
          require 'net/http'
          require 'uri'
          body = { "msgtype" => "text", "text" => { "content" => "error:上传蒲公英超时失败!" } }.to_json
          Net::HTTP.post(URI('https://oapi.dingtalk.com/robot/send?access_token=6a3519057170cdb1b7274edfe43934c84a0062ffe2c9bcced434699296a7e26e'), body, "Content-Type" => "application/json")
        end

        def puts_h(str)
          puts str
          @h_file_array ||= []
          @h_file_array << str
        end

        def puts_m(str)
          puts str
          @m_file_array ||= []
          @m_file_array << str
        end

        def save_to_file
          @model_names = []
          file_name = gen_model_name('')
          h_file = File.join('.', "#{file_name}.h")
          m_file = File.join('.', "#{file_name}.m")
          File.write(h_file, @h_file_array.join("\n")) if @h_file_array.count > 0
          File.write(m_file, @m_file_array.join("\n")) if @m_file_array.count > 0
          puts "\n\n生成文件成功！所在路径:\n#{File.expand_path(h_file)} \n#{File.expand_path(m_file)}"
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
          begin
            puts "\n<===============打印返回数据模型-Begin=====================>\n"
            fetch_res_boy(res_json)
            print_models
            print_models_implementation
            puts "\n<===============打印返回数据模型-End=====================>\n"
          end
          begin
            puts "\n<===============打印请求模型-Begin=====================>\n"
            @models = []
            @model_names = []
            fetch_req_body(res_json)
            print_models
            print_models_implementation
            puts "\n<===============打印请求模型-End=====================>\n"
          end
        end

        def fetch_res_boy(res_json)
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

        def fetch_req_body(res_json)
          if res_json && res_json['data']
            @data_json = res_json['data']
            if @data_json['req_body_other']
              begin
                res_body = JSON.parse(@data_json['req_body_other'])
                res_body['name'] = gen_model_name('')
                handle_model(res_body)
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
          @models.each do |model|
            model_name = model[:name] || ''
            model_properties = model[:properties]
            puts_h "@interface #{model_name} : NSObject"
            model_properties.each do |m|
              print_model(m)
            end
            puts_h "@end\n\n\n"
          end
        end

        def print_models_implementation
          @models.each do |model|
            puts_m "@implementation #{model[:name]}"
            str = model[:properties].filter { |p| p[:type].eql?('array') && !p[:type_name].eql?('NSString') }.map{ |p| "@\"#{p[:key]}\": #{p[:type_name]}.class" }.join(', ')
            if str && str.length > 0
              puts_m "+(NSDictionary *)modelContainerPropertyGenericClass {"
              puts_m "  return @{#{str}};"
              puts_m "}"
            end
            puts_m "@end\n"
            puts "\n\n"
          end
        end

        def print_model(m)
          key = m[:key]
          type_name = m[:type_name]
          type = m[:type]
          des = m[:description] || ''
          des.gsub!(/\n/, '  ')
          default = m[:default]
          puts_h "///#{des} #{default}"
          if type.eql?('integer')
            puts_h "@property (nonatomic, assign) NSInteger #{key};"
            if des.include?('分')
              puts_h "/////////==========删掉其中一个属性"
              puts_h "@property (nonatomic, strong) MLCentNumber *#{key};"
            end
          elsif type.eql?('cent')
            puts_h "@property (nonatomic, strong) MLCentNumber *#{key};"
          elsif type.eql?('string')
            puts_h "@property (nonatomic, copy) NSString *#{key};"
          elsif type.eql?('number')
            puts_h "@property (nonatomic, strong) NSNumber *#{key};"
          elsif type.eql?('float')
            puts_h "@property (nonatomic, assign) CGFloat #{key};"
          elsif type.eql?('double')
            puts_h "@property (nonatomic, assign) double #{key};"
          elsif type.eql?('boolean')
            puts_h "@property (nonatomic, assign) BOOL #{key};"
          elsif type.eql?('object')
            puts_h "@property (nonatomic, strong) #{type_name} *#{key};"
          elsif type.eql?('array')
            puts_h "@property (nonatomic, strong) NSArray<#{type_name} *> *#{key};"
          else
            puts_h "@property (nonatomic, copy) NSString *#{key};"
          end
        end

        def print_methods
          puts "\n<===============方法调用=====================>\n"
          puts_m "/**"
          puts_m " *  #{@data_json['title']} -- #{@data_json['username']}"
          puts_m " */"
          key_str = @data_json['path'].split('/').map{ |s| s.gsub(/[^A-Za-z0-9]/, '').gsub(/^\w/){ $&.upcase } }.join('')
          key = "k#{key_str}URL"
          puts_m "static NSString * const #{key} = @\"#{@data_json['path']}\";"
          puts_m "\n\n"
          puts_h "@interface MLParamModel : NSObject"
          @data_json['req_query'].each do |h|
            des = h['desc'].gsub(/\n/, '  ')
            puts_h "///#{des}  #{h['example']}"
            puts_h "@property (nonatomic, copy) NSString *#{h['name']};"
          end
          puts_h "@end"
          puts "\n\n"
          model = @models.last
          if @data_json['method'].eql?('GET')
            puts_m "    [MLNetworkingManager getWithUrl:#{key} params:nil response:^(MLResponseMessage *responseMessage) {"
            puts_m "        if (response.resultCode == 0 && !response.error){"
            puts_m "            NSDictionary *detailMsg = response.detailMsg"
            puts_m "            #{model[:name]} *model = [#{model[:name]} yy_modelWithDictionary:detailMsg];" if model
            puts_m "        }"
            puts_m "    }];"
          else
            puts_m "    [MLNetworkingManager postWithUrl:#{key} params:nil response:^(MLResponseMessage *responseMessage) {"
            puts_m "        if (response.resultCode == 0 && !response.error){"
            puts_m "            NSDictionary *detailMsg = response.detailMsg"
            puts_m "            #{model[:name]} *model = [#{model[:name]} yy_modelWithDictionary:detailMsg];" if model
            puts_m "        }"
            puts_m "    }];"
          end
        end
      end
    end
  end
end
