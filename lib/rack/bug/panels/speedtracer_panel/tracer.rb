class Rack::Bug
  module SpeedTrace
    class TraceRecord
      include Render
      def initialize(id)
        @id = id
        @start = Time.now
        @children = []
      end

      def finish; @finish = Time.now; end

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
        hash.each_key do |key|
          if String === key
            next if hash.has_key?(key.to_sym)
            hash[key.to_sym] = hash[key]
          end
        end
      end
    end

    class ServerEvent < TraceRecord
      attr_accessor :children
      attr_reader :name

      def initialize(id, file, line, method, context, arguments)
        super(id)

        @file = file
        @line = line
        @method = method
        @context = context
        @arguments = arguments
        @name = [context, method, "(", arguments, ")"].join("")
      end

      def hash_representation
        {
          'range' => range(@start, @finish),
          #'id' =>  @id,
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
        render_template('panel/speedtracer/serverevent', 
                        {:self_time => duration - time_in_children}.merge(symbolize_hash(hash_representation)))
      end
    end

    class Tracer < TraceRecord
      def initialize(id, method, uri)
        super(id)

        @method = method
        @uri = uri
        @event_id = 0
        @pstack = []
      end

      #TODO: Threadsafe
      def run(context="::", called_at = caller[0], args=[], &blk)
        file, line, method = called_at.split(':')

        method = method.gsub(/^in|[^\w]+/, '') if method

        start_event(file, line, method, context, args)
        blk.call      # execute the provided code block
        finish_event
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

      def make_string_of(array)
        array.map do |item|
          short_string(item)
        end.join(",")
      end

      def start_event(file, line, method, context, arguments)
        @event_id += 1

        arguments_string = make_string_of(arguments)
        event = ServerEvent.new(@event_id, file, line, method, context, arguments_string)
        @pstack.push event
      end

      def finish_event
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

      def hash_representation
        finish
        { 'trace' =>  {

          'url' => "/speedtracer?id=#@id",

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
        "<a href='#{hash['url']}'>Raw JSON</a>\n" + 
          render_template('panel/speedtracer/serverevent', extra.merge(symbolize_hash(hash['trace']['frameStack'])))
      end

      def finish
        super()

        until @pstack.empty?
          finish_event
        end
        self
      end
    end
  end
end
