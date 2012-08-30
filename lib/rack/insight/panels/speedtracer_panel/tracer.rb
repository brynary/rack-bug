module Rack::Insight
  module SpeedTracer
    class Tracer
      def initialize(table)
        @pstack = []
        @table = table
        @event_id = 0
      end

      def request_start(env, start)
        id, method, uri = env.values_at("rack-insight.speedtracer-id", "REQUEST_METHOD", "PATH_INFO")
        @pstack.push RequestRecord.new(id, method, uri)
      end

      def request_finish(env, status, headers, body, timing)
        env["rack-insight.speedtracer-record"] = @pstack.pop
      end

      def before_detect(method_call, arguments)
        @event_id += 1

        #arguments_string = make_string_of(arguments)
        arguments_string = ""
        #XXX ServerEvent use method call...
        event = ServerEvent.new(method_call, arguments_string)
        @pstack.push event
      end

      def after_detect(method_call, timing, arguments, result)
        event = @pstack.pop
        if event.nil?
        else
          event.finish

          unless (parent = @pstack.last).nil?
            parent.children.push event
          else
            @children.push event
          end
        end
      end

      def make_string_of(array)
        array.map do |item|
          short_string(item)
        end.join(",")
      end

      def short_string(item, max_per_elem = 50)
        begin
          string = item.inspect
          if string.length > max_per_elem
            case item
            when NilClass
              "nil"
            when Hash
              "{ " + item.map do |key, value|
                short_string(key, 15) + "=>" + short_string(value, 30)
              end.join(", ") + " }"
            when find_constant("ActionView::Base")
              tmpl = item.template
              if tmpl.nil?
                item.path.inspect
              else
                [tmpl.base_path, tmpl.name].join("/")
              end
            when find_constant("ActiveRecord::Base")
              string = "#{item.class.name}(#{item.id})"
            else
              string = item.class.name
            end
          else
            string
          end
        rescue Exception => ex
          "..."
        end
      end

    end

    class TraceRecord
      include Render
      def initialize
        @start = Time.now
        @children = []
      end

      attr_accessor :children
      attr_reader :start

      def finish
        @finish ||= Time.now
      end

      def time_in_children
        @children.inject(0) do |time, child|
          time + child.duration
        end
      end

      def duration
        ((@finish - @start) * 1000).to_i
      end

      def to_json
        Yajl::Encoder.encode(hash_representation, :pretty => true, :indent => '  ')
      end

      private
      # all timestamps in SpeedTracer are in milliseconds
      def range(start, finish)
        {
          'duration'  =>  ((finish - start) * 1000).to_i,
          'start'     =>  [start.to_i,  start.usec/1000].join(''),
          #'end'       =>  [finish.to_i, finish.usec/1000].join('')
        }
      end

      def symbolize_hash(hash)
        symbolled_hash = {}
        hash.each_key do |key|
          if String === key
            next if hash.has_key?(key.to_sym)
            symbolled_hash[key.to_sym] = hash[key]
          end
        end
        hash.merge!(symbolled_hash)
      end
    end

    class ServerEvent < TraceRecord
      attr_reader :name

      def initialize(method_call, arguments)
        super()
        @arguments = arguments
        @name = "#{method_call.context}#{method_call.kind == :instance ? "#" : "::"}#{method_call.method}(#{arguments})"
      end

      def hash_representation
        {
          'range' => range(@start, @finish),
          'operation' =>  {
          #          'sourceCodeLocation' =>  {
          #          'className'   =>  @file,
          #          'methodName'  =>  @method,
          #          'lineNumber'  =>  @line
          #        },
          'type' =>  'METHOD',
          'label' =>  @name
        },
          'children' =>  @children
        }
      end

      def to_html
        render_template('panels/speedtracer/serverevent',
                        {:self_time => duration - time_in_children}.merge(symbolize_hash(hash_representation)))
      end
    end


    class RequestRecord < TraceRecord
      def initialize(id, method, uri)
        super()

        @id = id
        @method = method
        @uri = uri
        @event_id = 0
      end

      def uuid
        @id
      end

      def hash_representation
        finish
        { 'trace' =>  {

          'url' => "/__insight__/speedtracer?id=#@id",

          'frameStack' => {

            'range' => range(@start, @finish),
            'operation' =>  {
            'type' =>  'HTTP',
            'label' =>  [@method, @uri].join(' ')
          },
            'children' =>  @children

          }, #end frameStack

            'resources' => {
            'Application' => '/', #Should get the Rails app name...
            'Application.endpoint' => '/' #Should get the env path thing
          }, #From what I can tell, Speed Tracer treats this whole hash as optional

            'range' =>  range(@start, @finish)
        }
        }
      end

      def to_html
        hash = hash_representation
        extra = {:self_time => duration - time_in_children}
        "<a href='#{hash['trace']['url']}'>Raw JSON</a>\n" +
          render_template('panels/speedtracer/serverevent', extra.merge(symbolize_hash(hash['trace']['frameStack'])))
      end
    end
  end
end
