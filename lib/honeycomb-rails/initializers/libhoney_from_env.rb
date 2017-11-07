require 'libhoney'

module HoneycombRails
  module Initializers
    module LibhoneyFromEnv
      def set_libhoney_from_env!
        writekey = ENV['HONEYCOMB_WRITEKEY'] or raise LoadError, 'boom' # TODO
        @libhoney = Libhoney::Client.new(writekey: writekey,
                                        dataset:  ENV['HONEYCOMB_DATASET'] || 'rails')
      end

      def libhoney
        @libhoney
      end
    end
  end
end
