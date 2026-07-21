# frozen_string_literal: true

RSpec.describe BlockRepeater::Replay do
  include BlockRepeater

  describe '#replay' do
    it 'executes the block and returns the result' do
      result = replay(exceptions: [RuntimeError]) { 'success' }
      expect(result).to eq('success')
    end

    it 'retries the block when a configured exception is raised' do
      attempts = 0

      result = replay(times: 3, delay: 0.01, exceptions: [RuntimeError]) do
        attempts += 1
        raise RuntimeError, 'transient error' if attempts < 3

        'recovered'
      end

      expect(result).to eq('recovered')
      expect(attempts).to eq(3)
    end

    it 'raises the exception if still failing on the final attempt' do
      expect do
        replay(times: 3, delay: 0.01, exceptions: [RuntimeError]) do
          raise RuntimeError, 'persistent error'
        end
      end.to raise_error(RuntimeError, 'persistent error')
    end

    it 'does not catch exceptions not in the configured list' do
      expect do
        replay(times: 3, delay: 0.01, exceptions: [RuntimeError]) do
          raise IOError, 'unexpected'
        end
      end.to raise_error(IOError, 'unexpected')
    end

    it 'calls the refresh proc between retries' do
      refresh_count = 0
      attempts = 0
      refresh_proc = -> { refresh_count += 1 }

      replay(times: 3, delay: 0.01, exceptions: [RuntimeError], refresh: refresh_proc) do
        attempts += 1
        raise RuntimeError, 'error' if attempts < 3

        'done'
      end

      expect(refresh_count).to eq(2)
    end

    it 'does not call refresh on the final attempt' do
      refresh_count = 0
      refresh_proc = -> { refresh_count += 1 }

      expect do
        replay(times: 3, delay: 0.01, exceptions: [RuntimeError], refresh: refresh_proc) do
          raise RuntimeError, 'error'
        end
      end.to raise_error(RuntimeError)

      expect(refresh_count).to eq(2)
    end

    it 'does not attempt refresh when refresh is nil' do
      attempts = 0

      result = replay(times: 3, delay: 0.01, exceptions: [RuntimeError]) do
        attempts += 1
        raise RuntimeError, 'error' if attempts < 2

        'ok'
      end

      expect(result).to eq('ok')
    end

    it 'logs the error message with the provided logger' do
      test_logger = double('logger')
      logged_messages = []
      allow(test_logger).to receive(:error) do |&blk|
        logged_messages << blk.call
      end

      expect do
        replay(times: 2, delay: 0.01, exceptions: [RuntimeError], logger: test_logger) do
          raise RuntimeError, 'something broke'
        end
      end.to raise_error(RuntimeError)

      expect(logged_messages).to eq(['something broke', 'something broke'])
    end

    it 'does not raise when logger is nil' do
      attempts = 0

      result = replay(times: 2, delay: 0.01, exceptions: [RuntimeError], logger: nil) do
        attempts += 1
        raise RuntimeError, 'error' if attempts < 2

        'ok'
      end

      expect(result).to eq('ok')
    end

    it 'raises ArgumentError when no block is given' do
      expect { replay(exceptions: [RuntimeError]) }.to raise_error(ArgumentError, 'replay requires a block')
    end
  end
end
