module Pod
  class Command
    class Bin < Command
      class View < Bin
        self.summary = '生成源码'

        def initialize(argv)
          @name = argv.option('name', 'titleLabel')
          @type = argv.option('type', 'UILabel')
          super
        end

        def names
          @name.split(",").map(&:strip)
        end

        def type
          @ele_type ||= begin
                          if @type =~ /image/i
                            'UIImageView'
                          elsif  @type =~ /stack/i
                            'UIStackView'
                          elsif @type =~ /label/i
                            'UILabel'
                          elsif @type =~ /table/i
                            'UITableView'
                          elsif @type =~ /text/i
                            'UITextField'
                          elsif @type =~ /button/i
                            'UIButton'
                          elsif @type =~ /view/i
                            'UIView'
                          else
                            @type
                          end
                      end
        end

        def run
          print_declare
          puts "\n\n"
          print_instance
          puts "\n\n"
          print_layout
          puts "\n\n"
          print_value
        end

        def print_declare
          names.each do |name|
            puts "///"
            puts "@property (nonatomic, strong) #{type} *#{name};"
          end
        end

        def print_instance
          names.each do |name|
            puts "-(#{type} *)#{name}"
            puts "{"
            puts "    if(!_#{name}){"
            print_alloc(name)
            puts "        _#{name}.translatesAutoresizingMaskIntoConstraints = NO;"
            print_property(name)
            puts "    }"
            puts "    return _#{name};"
            puts "}"
            puts "\n"
          end
        end

        def print_alloc(name)
          if type.eql?('UIImageView')
            puts "        _#{name} = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@\"xxxx\"]];"
          elsif type.eql?('UIButton')
            puts "        _#{name} = [UIButton buttonWithType:UIButtonTypeCustom];"
          elsif type.eql?('UITableView')
            puts "        _#{name} = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];"
          else
            puts "        _#{name} = [[#{type} alloc] init];"
          end
        end

        def print_property(name)
          if type.eql?('UILabel')
            puts "        _#{name}.textColor = kSetCOLOR(0x333333);"
            puts "        _#{name}.text = @\"xxxxxxxx\";"
            puts "        _#{name}.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];"
            puts "        _#{name}.textAlignment = NSTextAlignmentCenter;"
          elsif type.eql?('UIImageView')
            puts "        _#{name}.backgroundColor = kBackgroundColor;"
            puts "        _#{name}.contentMode = UIViewContentModeScaleAspectFit;"
            puts "        _#{name}.clipsToBounds = YES;"
            puts "        _#{name}.layer.cornerRadius = 6.0f;"
            puts "        _#{name}.layer.borderColor = kLineColor.CGColor;"
            puts "        _#{name}.layer.borderWidth = 0.5;"
          elsif type.eql?('UITextField')
            puts "        _#{name}.textColor = kSetCOLOR(0x333333);"
            puts "        _#{name}.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];"
          elsif type.eql?('UIView')
            puts "        _#{name}.backgroundColor = kBackgroundColor;"
          elsif type.eql?('UIStackView')
            puts "        _#{name}.axis = UILayoutConstraintAxisHorizontal;"
            puts "        _#{name}.distribution = UIStackViewDistributionFillEqually;"
          elsif type.eql?('UITableView')
            puts "        _#{name}.backgroundColor = kBackgroundColor;"
            puts "        _#{name}.delegate = self;"
            puts "        _#{name}.delegate = self;"
            puts "        _#{name}.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];"
            puts "        _#{name}.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];"
            puts "        _#{name}.separatorStyle = UITableViewCellSeparatorStyleNone;"
          elsif type.eql?('UIButton')
            puts "        _#{name}.backgroundColor = kBackgroundColor;"
            puts "        [_#{name} setTitle:@\"xxx\" forState:UIControlStateNormal];"
            puts "        [_#{name} setTitleColor:kSetCOLOR(0x999999) forState:UIControlStateNormal];"
            puts "        _#{name}.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];"
            puts "        [_#{name} setImage:[UIImage imageNamed:@\"xx\"] forState:UIControlStateNormal];"
            puts "        [_#{name} setImage:[UIImage imageNamed:@\"xx\"] forState:UIControlStateSelected];"
            puts "        [_#{name} addTarget:self action:@selector(actionHandler:) forControlEvents:UIControlEventTouchUpInside];"
          end
        end

        def print_layout
          names.each do |name|
            puts "[contentView addSubview:self.#{name}];"
            puts "[self.#{name}.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:0].active = YES;"
            puts "[self.#{name}.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:0].active = YES;"
            puts "[self.#{name}.topAnchor constraintEqualToAnchor:contentView.topAnchor].active = YES;"
            puts "[self.#{name}.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor].active = YES;"
            puts "[self.#{name}.widthAnchor constraintEqualToConstant:80].active = YES;"
            puts "[self.#{name}.heightAnchor constraintEqualToConstant:80].active = YES;"
            if type.eql?('UILabel')
              puts "[self.#{name} setContentHuggingPriority:300 forAxis:UILayoutConstraintAxisHorizontal];"
              puts "[self.#{name} setContentCompressionResistancePriority:300 forAxis:UILayoutConstraintAxisHorizontal];"
            end
            puts "\n\n"
          end
        end

        def print_value
          names.each do |name|
            if type.eql?('UILabel')
              puts "self.#{name}.text = @\"xxxxx\";"
            end
          end
        end

      end
    end
  end
end
