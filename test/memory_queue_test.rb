require 'test_helper'

describe Debouncer::MemoryQueue do
  let(:queue) { Debouncer::MemoryQueue.new }
  let(:now) { Time.now.to_f }

  describe "push" do
    it "adds the event to the queue" do
      event = Debouncer::Event.new('reticulate', 'splines', now + 100, {first_name: 'Michael', last_name: 'Dwan'})
      queue.push(event)
      queue.events.count.must_equal 1
    end

    it "overwrites an existing event with the same id" do
      event1 = Debouncer::Event.new('reticulate', 'key1', now + 100, {a: 123, b: 456})
      event2 = Debouncer::Event.new('reticulate', 'key1', now + 100, {a: 123, b: 456})

      queue.push(event1)
      queue.push(event2)
      queue.events.count.must_equal 1
      queue.events[event1.id].must_be_same_as event2
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
      queue.next_after(Time.now.to_f).must_be_empty
    end

    it 'returns an empty array when no events can run' do
      event1 = Debouncer::Event.new('reticulate', 'key1', now + 100, {a: 123, b: 456})
      queue.push(event1)
      queue.next_after(Time.now.to_f).must_be_empty
    end

    it 'returns events where run_at is greater than the current timestamp' do
      event1 = Debouncer::Event.new('reticulate', 'key1', now - 100, {a: 123, b: 456})
      event2 = Debouncer::Event.new('reticulate', 'key2', now + 100, {a: 123, b: 456})
      queue.push(event1)
      queue.push(event2)
      queue.next_after(now).must_include event1
      queue.next_after(now).count.must_equal 1
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
      queue.remove([@event1.id])
      queue.events.values.wont_include @event1
      queue.events.count.must_equal 1
    end

    it 'removes multiple events from the queue' do
      queue.remove([@event1.id, @event2.id])
      queue.events.must_be_empty
    end
  end
end
