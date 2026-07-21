# frozen_string_literal: true

module BlockRepeater
  ##
  # Provides a retry-with-refresh mechanism for UI actions
  # that may fail due to transient driver/page errors.
  #
  # Consumers configure which exceptions to catch and how to refresh the page.
  module Replay
    ##
    # Execute a block, retrying on configured exceptions with optional page refresh.
    #
    # @param exceptions [Array<Class>] Exception types to catch and retry on
    # @param times [Integer] Maximum retry attempts (default: 3)
    # @param delay [Float] Seconds between retries (default: 0.5)
    # @param refresh [Proc, nil] Callable to execute between retries for page refresh (default: nil)
    # @param logger [#error, nil] Logger for error messages; nil to silence (default: nil)
    # @param &block - The block of code to retry
    # @return The result of the block
    def replay(exceptions:, times: 3, delay: 0.5, refresh: nil, logger: nil, &block)
      raise ArgumentError, 'replay requires a block' unless block

      attempt = 0

      repeat(times: times, delay: delay, &block).catch(exceptions: exceptions, behaviour: :continue) do |e|
        attempt += 1
        logger&.error { e.message }
        raise(e) if attempt >= times

        refresh&.call
      end.until do |result|
        !result.is_a?(Exception)
      end
    end
  end
end
