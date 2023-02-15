# frozen_string_literal: true

require 'anyway'

module Yabeda
  module Shoryuken
    # Yabeda Shoryuken config
    class Config < ::Anyway::Config
      config_name :yabeda_sidekiq

      # Declare metrics that are only tracked inside worker process even outside them
      attr_config declare_process_metrics: ::Shoryuken.server?
    end
  end
end
