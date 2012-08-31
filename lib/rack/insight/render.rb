require 'erb'

module Rack::Insight
  module Render
    include ERB::Util
    include Logging

    def signed_params(hash)
      ParamsSignature.sign(request, hash)
    end

    module CompiledTemplates
    end
    include CompiledTemplates

    def render_template(filename, local_assigns = {})
      compile(filename, local_assigns)
      render_symbol = method_name(filename, local_assigns)
      send(render_symbol, local_assigns)
    end

    def compile(filename, local_assigns)
      render_symbol = method_name(filename, local_assigns)

      if !CompiledTemplates.instance_methods.include?(render_symbol.to_s)
        compile!(filename, local_assigns)
      end
    end

    def compile!(filename, local_assigns)
      render_symbol = method_name(filename, local_assigns)
      locals_code = local_assigns.keys.map { |key| "#{key} = local_assigns[:#{key}];" }.join

      source = <<-end_src
      def #{render_symbol}(local_assigns)
        #{locals_code}
        #{compiled_source(filename)}
      end
      end_src

      begin
        CompiledTemplates.module_eval(source, filename, 0)
      rescue Object => ex
        logger.error do
          "#{ex.class.name}: #{ex.message} in\n" +
          source +
            ex.backtrace.join("\n")
        end
      end
    end

    def compiled_source(filename)
      primary_file_path = ::File.join(::File.dirname(__FILE__), "views/#{filename}.html.erb")
      file = nil
      begin
        file = ::File.read(primary_file_path)
      rescue Errno::ENOENT
      end
      if file.nil?
        Rack::Insight::Config.config[:panel_load_paths].each do |load_path|
          begin
            file = ::File.read(::File.join(load_path, "#{filename}.html.erb"))
            break # If no error is raised then the file was read!
          rescue Errno::ENOENT
          end
        end
      end
      if file
        ::ERB.new(file, nil, "-").src
      else
        warn "Rack::Insight: Unable to find expected view template #{primary_file_path} or a #{filename}.html.erb template in rack-insight's :panel_load_paths.  Configured panel load paths are: #{Rack::Insight::Config.config[:panel_load_paths].inspect}"
      end
    end

    def method_name(filename, local_assigns)
      if local_assigns && local_assigns.any?
        method_name = method_name_without_locals(filename).dup
        method_name << "_locals_#{local_assigns.keys.map { |k| k.to_s }.sort.join('_')}"
      else
        method_name = method_name_without_locals(filename)
      end
      method_name.to_sym
    end

    def method_name_without_locals(filename)
      filename.split("/").join("_").tr("-", "_")
    end

  end

end
