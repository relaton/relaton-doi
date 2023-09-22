module RelatonDoi
  module Util
    extend RelatonBib::Util

    def self.logger
      RelatonDoi.configuration.logger
    end
  end
end
