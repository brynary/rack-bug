require "digest"

module Rack
  module Bug
    
    class ParamsSignature
      extend ERB::Util
      
      def self.sign(request, hash)
        parts = []
        
        hash.keys.sort.each do |key|
          parts << "#{key}=#{u(hash[key])}"
        end
        
        signature = new(request).signature(hash)
        parts << "hash=#{u(signature)}"
        
        parts.join("&amp;")
      end
      
      attr_reader :request
      
      def initialize(request)
        @request = request
      end
      
      def secret_key
        @request.env['rack-bug.secret_key']
      end
      
      def secret_key_blank?
        secret_key.nil? || secret_key == ""
      end
      
      def validate!
        if secret_key_blank?
          raise SecurityError.new("Missing secret key")
        end
        
        if secret_key_blank? || request.params["hash"] != signature(request.params)
          raise SecurityError.new("Invalid query hash.")
        end
      end
      
      def signature(params)
        Digest::SHA1.hexdigest(signature_base(params))
      end
      
      def signature_base(params)
        signature = []
        signature << secret_key
        
        params.keys.sort.each do |key|
          next if key == "hash"
          signature << params[key].to_s
        end
        
        signature.join(":")
      end
      
    end
    
  end
end