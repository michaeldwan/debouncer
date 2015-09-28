require "debouncer/version"
require 'debouncer/memory_queue'
require 'debouncer/redis_queue'

module Debouncer
  def self.queue
    @queue ||= MemoryQueue.new
  end

  def self.queue=(queue)
    @queue = queue
  end

  def self.callbacks
    @callbacks ||= {}
  end

  def self.clear_callbacks
    callbacks.clear
  end

  def self.add_callback(name, &block)
    self.callbacks[name] = block
  end

  def self.remove_callback(name, &block)
    self.callbacks.delete(name)
  end

  def self.enqueue(*args)
    timeout = args[0]
    event = args[1]
    arguments = args.pop if args.last.is_a?(Hash)
    key = args[2]
    run_after = Time.now.to_f + timeout

    event = Event.new(event, key, run_after, arguments)
    self.queue.push(event)
  end

  def self.enqueued?(event_id)
    self.queue.enqueued?(event_id)
  end

  def self.remove(event_id_or_ids)
    self.queue.remove(event_id_or_ids)
  end

  def self.peek(event_id)
    self.queue.peek(event_id)
  end

  def self.start
    loop do
      now = Time.now.to_f
      events = self.queue.next_after(now)
      events.each do |event|
        puts "triggering #{event}"
        callback = callbacks[event.name]
        callback.yield(event.arguments)
      end

      self.queue.remove(events.map(&:id))
      sleep 0.1
    end
  end

  def self.start_async
    Thread::abort_on_exception = true
    Thread.new do
      self.start
    end
  end

  class Event < Struct.new(:name, :key, :run_after, :arguments)
    def id
      key ? "#{name}@#{key}" : name.to_s
    end
  end
end
