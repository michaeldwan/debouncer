require 'thread'

module Debouncer
  class MemoryQueue
    attr_reader :events

    def initialize
      @events = {}
      @mutex = Mutex.new
    end

    def push(event)
      @events[event.id] = event
    end

    def remove(event_id_or_ids)
      @mutex.synchronize do
        Array(event_id_or_ids).each do |event_id|
          @events.delete(event_id)
        end
      end
    end

    def peek(event_id)
      @events[event_id]
    end

    def next_after(timestamp)
      timestamp = timestamp.to_f
      @events.values.select do |event|
        event.run_after < timestamp
      end
    end
  end
end
