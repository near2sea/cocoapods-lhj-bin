# frozen_string_literal: true
# copy from https://github.com/CocoaPods/cocoapods-packager

require 'cocoapods-lhj-bin/helpers/framework'
require 'cocoapods-lhj-bin/helpers/build_utils'
require 'English'
require 'cocoapods-lhj-bin/config/config_builder'
require 'shellwords'

module CBin
  class Framework
    class Builder
      include Pod
#Debug下还待完成
      def initialize(spec, file_accessor, platform, source_dir, isRootSpec = true, build_model='Debug')
        @spec = spec
        @source_dir = source_dir
        @file_accessor = file_accessor
        @platform = platform
        @build_model = build_model
        @isRootSpec = isRootSpec
        #vendored_static_frameworks 只有 xx.framework  需要拼接为 xx.framework/xx by slj
        vendored_static_frameworks = file_accessor.vendored_static_frameworks.map do |framework|
          path = framework
          extn = File.extname  path
          path = File.join(path,File.basename(path, extn)) if extn.downcase == '.framework'
          path
        end

        @vendored_libraries = (vendored_static_frameworks + file_accessor.vendored_static_libraries).map(&:to_s)
      end

      def build
        defines = compile
        build_sim_libraries(defines)

        defines
      end

      def lipo_build(defines)

        # if CBin::Build::Utils.is_swift_module(@spec) || !CBin::Build::Utils.uses_frameworks?
        #   UI.section("Building static Library #{@spec}") do
        #     output = framework.versions_path + Pathname.new(@spec.name)
        #
        #     build_static_library_for_ios(output)
        #
        #     copy_headers
        #     copy_license
        #     copy_resources
        #
        #     cp_to_source_dir
        #   end
        # else
        #   begin
            UI.section("Building framework  #{@spec}") do
              output = framework.fwk_path + Pathname.new(@spec.name)

              copy_static_framework_dir_for_ios

              build_static_framework_machO_for_ios(output)

              # copy_license
              copy_framework_resources
          end
        # end

        framework
      end

      private

      def cp_to_source_dir
        # 删除Versions 软链接
        framework.remove_current_version if CBin::Build::Utils.is_swift_module(@spec)

        framework_name = "#{@spec.name}.framework"
        target_dir = File.join(CBin::Config::Builder.instance.zip_dir,framework_name)
        FileUtils.rm_rf(target_dir) if File.exist?(target_dir)

        zip_dir = CBin::Config::Builder.instance.zip_dir
        FileUtils.mkdir_p(zip_dir) unless File.exist?(zip_dir)

        `cp -fa #{@platform}/#{framework_name} #{target_dir}`
      end

      #模拟器，目前只支持 debug x86-64
      def build_sim_libraries(defines)
        UI.message 'Building simulator libraries'

        # archs = %w[i386 x86_64]
        archs = ios_architectures_sim
        archs.map do |arch|
          xcodebuild(defines, "-sdk iphonesimulator ARCHS=\'#{arch}\' ", "build-#{arch}",@build_model)
        end

      end


      def static_libs_in_sandbox(build_dir = 'build')
        file = Dir.glob("#{build_dir}/lib#{target_name}.a")
        UI.warn "file no find = #{build_dir}/lib#{target_name}.a" unless file
        file
      end

      def build_static_library_for_ios(output)
        UI.message "Building ios libraries with archs #{ios_architectures}"
        static_libs = static_libs_in_sandbox('build') + static_libs_in_sandbox('build-simulator') + @vendored_libraries

        ios_architectures.map do |arch|
          static_libs += static_libs_in_sandbox("build-#{arch}") + @vendored_libraries
        end
        ios_architectures_sim do |arch|
          static_libs += static_libs_in_sandbox("build-#{arch}") + @vendored_libraries
        end

        build_path = Pathname('build')
        build_path.mkpath unless build_path.exist?

        libs = (ios_architectures + ios_architectures_sim) .map do |arch|
          library = "build-#{arch}/lib#{@spec.name}.a"
          library
        end

        UI.message "lipo -create -output #{output} #{libs.join(' ')}"
        `lipo -create -output #{output} #{libs.join(' ')}`
      end

      def ios_build_options
        "ARCHS=\'#{ios_architectures.join(' ')}\' OTHER_CFLAGS=\'-fembed-bitcode -Qunused-arguments\'"
      end

      def ios_architectures
        # >armv7
        #   iPhone4
        #   iPhone4S
        # >armv7s   去掉
        #   iPhone5
        #   iPhone5C
        # >arm64
        #   iPhone5S(以上)
        # >i386
        #   iphone5,iphone5s以下的模拟器
        # >x86_64
        #   iphone6以上的模拟器
        %w[arm64 armv7]
        # archs = %w[x86_64 arm64 armv7s i386]
        # @vendored_libraries.each do |library|
        #   archs = `lipo -info #{library}`.split & archs
        # end
        
      end

      def ios_architectures_sim

        %w[x86_64]
        # TODO: 处理是否需要 i386
        
      end

      def compile
        defines = "GCC_PREPROCESSOR_DEFINITIONS='$(inherited)'"
        defines += ' '
        defines += @spec.consumer(@platform).compiler_flags.join(' ')

        options = ios_build_options
        # if is_debug_model
          archs = ios_architectures
          # archs = %w[arm64 armv7 armv7s]
          archs.map do |arch|
            xcodebuild(defines, "ARCHS=\'#{arch}\' OTHER_CFLAGS=\'-fembed-bitcode -Qunused-arguments\'","build-#{arch}",@build_model)
          end
        # else
          # xcodebuild(defines,options)
        # end

        defines
      end

      def is_debug_model
        @build_model == 'Debug'
      end

      def target_name
        #区分多平台，如配置了多平台，会带上平台的名字
        # 如libwebp-iOS
         if @spec.available_platforms.count > 1
           "#{@spec.name}-#{Platform.string_name(@spec.consumer(@platform).platform_name)}"
         else
            @spec.name
         end
      end

      def xcodebuild(defines = '', args = '', build_dir = 'build', build_model = 'Debug')

        if File.exist?('Pods.xcodeproj')
          command = "xcodebuild #{defines} #{args} CONFIGURATION_BUILD_DIR=#{build_dir} clean build -configuration #{build_model} -target #{target_name} -project ./Pods.xcodeproj 2>&1"
        else #cocoapods-generate v2.0.0
          command = "xcodebuild #{defines} #{args} CONFIGURATION_BUILD_DIR=#{File.join(File.expand_path('..', build_dir), File.basename(build_dir))} clean build -configuration #{build_model} -target #{target_name} -project ./Pods/Pods.xcodeproj 2>&1"
        end

        UI.message "command = #{command}"
        output = `#{command}`.lines.to_a

        if $CHILD_STATUS.exitstatus != 0
          raise <<~EOF
            Build command failed: #{command}
            Output:
            #{output.map { |line| "    #{line}" }.join}
          EOF

          Process.exit
        end
      end

      def copy_headers
        #走 podsepc中的public_headers
        public_headers = []

        #by slj 如果没有头文件，去 "Headers/Public"拿
        # if public_headers.empty?
        spec_header_dir = "./Headers/Public/#{@spec.name}"
        spec_header_dir = "./Pods/Headers/Public/#{@spec.name}" unless File.exist?(spec_header_dir)
        raise "copy_headers #{spec_header_dir} no exist " unless File.exist?(spec_header_dir)
        Dir.chdir(spec_header_dir) do
          headers = Dir.glob('*.h')
          headers.each do |h|
            public_headers << Pathname.new(File.join(Dir.pwd,h))
          end
        end
        # end

        # UI.message "Copying public headers #{public_headers.map(&:basename).map(&:to_s)}"

        public_headers.each do |h|
          `ditto #{h} #{framework.headers_path}/#{h.basename}`
        end

        # If custom 'module_map' is specified add it to the framework distribution
        # otherwise check if a header exists that is equal to 'spec.name', if so
        # create a default 'module_map' one using it.
        if !@spec.module_map.nil?
          module_map_file = @file_accessor.module_map
          module_map = File.read(module_map_file) if Pathname(module_map_file).exist?
        elsif public_headers.map(&:basename).map(&:to_s).include?("#{@spec.name}-umbrella.h")
          module_map = <<-MAP
          framework module #{@spec.name} {
            umbrella header "#{@spec.name}-umbrella.h"

            export *
            module * { export * }
          }
          MAP
        end

        unless module_map.nil?
          UI.message "Writing module map #{module_map}"
          framework.module_map_path.mkpath unless framework.module_map_path.exist?
          File.write("#{framework.module_map_path}/module.modulemap", module_map)

          # unless framework.swift_module_path.exist?
          #   framework.swift_module_path.mkpath
          # end
          # todo 所有架构的swiftModule拷贝到 framework.swift_module_path
          archs = ios_architectures + ios_architectures_sim
          archs.map do |arch|
            swift_module = "build-#{arch}/#{@spec.name}.swiftmodule"
            FileUtils.cp_r("#{swift_module}/.", framework.swift_module_path) if File.directory?(swift_module)
          end
          swift_Compatibility_Header = "build-#{archs.first}/Swift\ Compatibility\ Header/#{@spec.name}-Swift.h"
          FileUtils.cp(swift_Compatibility_Header,framework.headers_path) if File.exist?(swift_Compatibility_Header)
          info_plist_file = File.join(File.dirname(__FILE__),'info.plist')
          FileUtils.cp(info_plist_file,framework.fwk_path)
        end
      end

      def copy_swift_header; end

      def copy_license
        UI.message 'Copying license'
        license_file = @spec.license[:file] || 'LICENSE'
        `cp "#{license_file}" .` if Pathname(license_file).exist?
      end

      def copy_resources
        resource_dir = './build/*.bundle'
        resource_dir = './build-armv7/*.bundle' if File.exist?('./build-armv7')
        resource_dir = './build-arm64/*.bundle' if File.exist?('./build-arm64')

        bundles = Dir.glob(resource_dir)

        bundle_names = [@spec, *@spec.recursive_subspecs].flat_map do |spec|
          consumer = spec.consumer(@platform)
          consumer.resource_bundles.keys +
              consumer.resources.map do |r|
                File.basename(r, '.bundle') if File.extname(r) == 'bundle'
              end
        end.compact.uniq

        bundles.select! do |bundle|
          bundle_name = File.basename(bundle, '.bundle')
          bundle_names.include?(bundle_name)
        end

        if bundles.count.positive?
          UI.message "Copying bundle files #{bundles}"
          bundle_files = bundles.join(' ')
          `cp -rp #{bundle_files} #{framework.resources_path} 2>&1`
        end

        real_source_dir = @source_dir
        unless @isRootSpec
          spec_source_dir = File.join(Dir.pwd,@spec.name.to_s)
          spec_source_dir = File.join(Dir.pwd,"Pods/#{@spec.name}") unless File.exist?(spec_source_dir)
          raise "copy_resources #{spec_source_dir} no exist " unless File.exist?(spec_source_dir)

          spec_source_dir = File.join(Dir.pwd,@spec.name.to_s)
          real_source_dir = spec_source_dir
        end

        resources = [@spec, *@spec.recursive_subspecs].flat_map do |spec|
          expand_paths(real_source_dir, spec.consumer(@platform).resources)
        end.compact.uniq

        if resources.count.zero? && bundles.count.zero?
          framework.delete_resources
          return
        end

        if resources.count.positive?
          #把 路径转义。 避免空格情况下拷贝失败
          escape_resource = []
          resources.each do |source|
            escape_resource << Shellwords.join(source)
          end
          UI.message "Copying resources #{escape_resource}"
          `cp -rp #{escape_resource.join(' ')} #{framework.resources_path}`
        end
      end

      def expand_paths(source_dir, path_specs)
        path_specs.map do |path_spec|
          Dir.glob(File.join(source_dir, path_spec))
        end
      end

      #---------------------------------swift--------------------------------------#
      #   lipo -create .a
      def build_static_framework_machO_for_ios(output)
        UI.message "Building ios framework with archs #{ios_architectures}"

        static_libs = static_libs_in_sandbox('build') + @vendored_libraries
        ios_architectures.map do |arch|
          static_libs += static_libs_in_sandbox("build-#{arch}") + @vendored_libraries
        end

        ios_architectures_sim do |arch|
          static_libs += static_libs_in_sandbox("build-#{arch}") + @vendored_libraries
        end

        build_path = Pathname('build')
        build_path.mkpath unless build_path.exist?

        libs = (ios_architectures + ios_architectures_sim) .map do |arch|
          library = "build-#{arch}/#{@spec.name}.framework/#{@spec.name}"
          library
        end

        UI.message "lipo -create -output #{output} #{libs.join(' ')}"
        `lipo -create -output #{output} #{libs.join(' ')}`
      end

      def copy_static_framework_dir_for_ios

        archs = ios_architectures + ios_architectures_sim
        framework_dir = "build-#{ios_architectures_sim.first}/#{@spec.name}.framework"
        framework_dir = "build-#{ios_architectures.first}/#{@spec.name}.framework" unless File.exist?(framework_dir)
        raise "#{framework_dir} path no exist" unless File.exist?(framework_dir)
        File.join(Dir.pwd, "build-#{ios_architectures_sim.first}/#{@spec.name}.framework")
        FileUtils.cp_r(framework_dir, framework.root_path)

        # TODO: 所有架构的swiftModule拷贝到 framework.swift_module_path
        archs.map do |arch|
          swift_module = "build-#{arch}/#{@spec.name}.framework/Modules/#{@spec.name}.swiftmodule"
          FileUtils.cp_r("#{swift_module}/.", framework.swift_module_path) if File.directory?(swift_module)
        end

        # 删除Versions 软链接
        framework.remove_current_version
      end

      def copy_framework_resources
        resources = Dir.glob("#{framework.fwk_path + Pathname.new('Resources')}/*")
        framework.delete_resources if resources.count.zero?

        consumer = @spec.consumer(@platform)
        if consumer.resource_bundles.keys.any?
          consumer.resource_bundles.each_key do |bundle_name|
            bundle_file = "build-arm64/#{bundle_name}.bundle"
            `cp -fa #{bundle_file} #{framework.fwk_path.to_s}`
          end
        end
      end


      #---------------------------------getter and setter--------------------------------------#

      def framework
        @framework ||= begin
          framework = Framework.new(@spec.name, @platform.name.to_s)
          framework.make
          framework
        end
      end


    end
  end
end
