# frozen_string_literal: true

module RSMP
  module Validator
    module Compliance
      # Converts a failed Sus assertion/error into compact JSON-friendly data.
      class ReportFailure
        ANSI_ESCAPE = /\e\[[0-9;]*m/

        def initialize(failure)
          @failure = failure
        end

        def to_h
          message = failure_message
          {
            'id' => failure_id,
            'message' => clean_text(message[:text]),
            'location' => message[:location],
            'type' => @failure.class.name
          }.compact
        end

        private

        def failure_message
          @failure.message
        rescue StandardError => e
          { text: e.message, location: failure_id }
        end

        def failure_id
          identity = @failure.respond_to?(:identity) ? @failure.identity : nil
          identity&.to_s
        end

        def clean_text(text)
          return nil unless text

          text.to_s.gsub(ANSI_ESCAPE, '').strip
        end
      end
    end
  end
end
