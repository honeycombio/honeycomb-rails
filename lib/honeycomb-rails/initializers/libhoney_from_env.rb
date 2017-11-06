require 'libhoney'

module HoneycombRails
  module Initializers
    module LibhoneyFromEnv
      def set_libhoney_from_env!
        @libhoney = Libhoney::Client.new(writekey: ENV.fetch('HONEYCOMB_WRITEKEY'),
                                        dataset:  ENV['HONEYCOMB_DATASET'] || 'rails')
      end

      def libhoney
        @libhoney
      end
    end
  end
end
