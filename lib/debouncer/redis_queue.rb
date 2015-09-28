require 'redis'
require 'json'

module Debouncer
  class RedisQueue
    attr_reader :redis_connection

    QUEUE_KEY = "debouncer_event_queue".freeze
    PAYLOAD_KEY = "debouncer_event_payloads".freeze

    def initialize(redis_connection)
      @redis_connection = redis_connection
    end

    def count
      redis_connection.zcard(QUEUE_KEY).to_i
    end

    def push(event)
      payload = serialize_arguments(event.arguments)
      redis_connection.multi do
        redis_connection.zadd(QUEUE_KEY, event.run_after, event.id)
        redis_connection.hset(PAYLOAD_KEY, event.id, payload)
      end
    end

    def enqueued?(event_id)
      redis_connection.zscore(QUEUE_KEY, event_id).to_i > 0
    end

    def peek(event_id)
      score, payload = redis_connection.pipelined do
        redis_connection.zscore(QUEUE_KEY, event_id)
        redis_connection.hget(PAYLOAD_KEY, event_id)
      end
      build_event(event_id, score, payload) if score
    end

    def remove(event_id_or_ids)
      counts = redis_connection.multi do
        removed_count = redis_connection.zrem(QUEUE_KEY, event_id_or_ids)
        redis_connection.hdel(PAYLOAD_KEY, event_id_or_ids)
      end
      counts.first
    end

    def next_after(timestamp)
      event_ids_and_scores = Hash[redis_connection.zrangebyscore(QUEUE_KEY, '-inf', timestamp.to_f, with_scores: true)]
      return [] if event_ids_and_scores.empty?

      event_payloads = redis_connection.hmget(PAYLOAD_KEY, event_ids_and_scores.keys)

      event_ids_and_scores.map.each_with_index do |event_id_and_score, index|
        event_id, score = event_id_and_score
        build_event(event_id, score, event_payloads[index])
      end
    end

    private
      def serialize_arguments(payload)
        JSON.generate(payload) if payload
      end

      def deserialize_arguments(data)
        JSON.parse(data) if data
      end

      def build_event(event_id, score, payload)
        name, key = event_id.split('@')
        arguments = deserialize_arguments(payload)
        Event.new(name, key, score.to_f, arguments)
      end
  end
end
