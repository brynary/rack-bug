require "digest"

module Rack::Insight

  class ParamsSignature
    extend ERB::Util

    def self.sign(request, hash)
      #puts "ParamsSignature#sign called!: #{caller.first}"
      parts = []

      hash.keys.sort.each do |key|
        parts << "#{key}=#{u(hash[key])}"
      end

      hancock = new(request).signature(hash)
      parts << "hash=#{u(hancock)}"

      parts.join("&amp;")
    end

    attr_reader :request

    def initialize(request)
      @request = request
    end

    def secret_key
      @request.env['rack-insight.secret_key']
    end

    def secret_key_blank?
      secret_key.nil? || secret_key == ""
    end

    def validate!
      if secret_key_blank?
        raise SecurityError.new("Missing secret key")
      elsif request.params["hash"] != signature(request.params)
        #puts "request params hash: #{request.params}\nsignature: #{signature(request.params)}"
        raise SecurityError.new("Invalid query hash.")
      end
    end

    def signature(params)
      Digest::SHA1.hexdigest(signature_base(params))
    end

    def signature_base(params)
      hancock = []
      hancock << secret_key

      params.keys.sort.each do |key|
        next if key == "hash"
        hancock << params[key].to_s
      end

      hancock.join(":")
    end

  end

end
