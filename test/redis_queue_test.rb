require 'test_helper'

describe Debouncer::RedisQueue do
  let(:redis_connection) { Redis.new(url:'redis://localhost:6379/15') }
  let(:queue) { Debouncer::RedisQueue.new(redis_connection) }
  let(:now) { Time.now.to_f }

  after do
    redis_connection.flushdb
  end

  describe "push" do
    it "adds the event to the queue" do
      event = Debouncer::Event.new('reticulate', 'splines', now + 100, {
        "first_name" => 'Michael', "last_name" => 'Dwan'
        })
      queue.push(event)
      queue.count.must_equal 1
      queue.enqueued?(event.id).must_equal true
      queue.peek(event.id).must_equal event
    end

    it "overwrites an existing event with the same id" do
      event = Debouncer::Event.new('reticulate', 'key1', now + 100, {"a" => 123, "b" => 456})

      queue.push(event)
      queue.count.must_equal 1
      queue.enqueued?(event.id).must_equal true
      queue.peek(event.id).must_equal event

      event.run_after = now + 1000

      queue.push(event)
      queue.count.must_equal 1
      queue.peek(event.id).run_after.must_equal now + 1000
    end
  end

  describe 'peek' do
    it "returns nil if the event isn't queued" do
        queue.peek('fake_event_id').must_be_nil
    end

    it "returns the event" do
      event = Debouncer::Event.new('reticulate', 'key1', now + 100, {"a" => 123, "b" => 456})
      queue.push(event)
      queue.peek(event.id).must_equal event
    end
  end

  describe 'next_after' do
    it 'returns an empty array when the queue is empty' do
      queue.next_after(now).must_be_empty
    end

    it 'returns an empty array when no events can run' do
      event1 = Debouncer::Event.new('reticulate', 'key1', now + 100, {a: 123, b: 456})
      queue.push(event1)
      queue.next_after(now).must_be_empty
    end

    it 'returns events where run_at is greater than the current timestamp' do
      event1 = Debouncer::Event.new('reticulate', 'key1', now - 100, {"a" => 123, "b" => 456})
      event2 = Debouncer::Event.new('reticulate', 'key2', now - 100, {"a" => 123, "b" => 456})
      event3 = Debouncer::Event.new('reticulate', 'key3', now + 100, {"a" => 123, "b" => 456})
      queue.push(event1)
      queue.push(event2)
      queue.push(event3)
      queue.next_after(now).must_include event1
      queue.next_after(now).must_include event2
      queue.next_after(now).count.must_equal 2
    end
  end

  describe "remove" do
    before do
      @event1 = Debouncer::Event.new('reticulate', 'key1', now - 100, {a: 123, b: 456})
      @event2 = Debouncer::Event.new('reticulate', 'key2', now + 100, {a: 123, b: 456})
      queue.push(@event1)
      queue.push(@event2)
    end

    it 'removes a single event from the queue' do
      queue.remove([@event1.id]).must_equal 1
      queue.enqueued?(@event1).must_equal false
    end

    it 'removes multiple events from the queue' do
      queue.remove([@event1.id, @event2.id]).must_equal 2
      queue.enqueued?(@event1).must_equal false
      queue.enqueued?(@event2).must_equal false
    end
  end
end
