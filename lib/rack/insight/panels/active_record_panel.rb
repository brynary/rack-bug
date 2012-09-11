module Rack::Insight
  class ActiveRecordPanel < Panel

    def request_start(env, start)
      @records = Hash.new{ 0 }
    end

    def after_detect(method_call, timing, results, args)
      @records[method_call.object.base_class.name] += 1
    end

    def request_finish(env, status, headers, body, timing)
      store(env, @records)
    end

    def heading_for_request(number)
      record = retrieve(number).first
      total = record.inject(0) do |memo, (key, value)|
        memo + value
      end
      "#{total} AR Objects"
    end

    def content_for_request(number)
      records = retrieve(number).first.to_a.sort_by { |key, value| value }.reverse
      render_template "panels/active_record", :records => records
    end

  end

end
