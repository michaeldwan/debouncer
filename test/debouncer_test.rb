require 'test_helper'

describe Debouncer do
  before do
    # This is nasty. Rethinking singleton...
    Debouncer.queue = nil
    Debouncer.clear_callbacks
  end

  describe "queue" do
    it "uses a MemoryQueue by default" do
      Debouncer.queue.must_be_kind_of Debouncer::MemoryQueue
    end
  end

  describe "enqueue" do
    it "pushes an event to the queue" do
      Time.stub(:now, Time.now) do
        Debouncer.queue = MiniTest::Mock.new
        expected_event = Debouncer::Event.new(:magic, nil, (Time.now + 1.5).to_f, nil)
        Debouncer.queue.expect(:push, nil, [expected_event])
        Debouncer.enqueue(1.5, :magic)
        Debouncer.queue.verify
      end
    end

    it "pushes an event with a key to the queue" do
      Time.stub(:now, Time.now) do
        Debouncer.queue = MiniTest::Mock.new
        expected_event = Debouncer::Event.new(:magic, "unique_key", (Time.now + 1.5).to_f, nil)
        Debouncer.queue.expect(:push, nil, [expected_event])
        Debouncer.enqueue(1.5, :magic, "unique_key")
        Debouncer.queue.verify
      end
    end

    it "pushes an event with callback arguments to the queue" do
      Time.stub(:now, Time.now) do
        Debouncer.queue = MiniTest::Mock.new
        expected_event = Debouncer::Event.new(:magic, nil, (Time.now + 1.5).to_f, {arguments: true})
        Debouncer.queue.expect(:push, nil, [expected_event])
        Debouncer.enqueue(1.5, :magic, {arguments: true})
        Debouncer.queue.verify
      end
    end

    it "pushes an event with a key and callback arguments to the queue" do
      Time.stub(:now, Time.now) do
        Debouncer.queue = MiniTest::Mock.new
        expected_event = Debouncer::Event.new(:magic, "unique_key", (Time.now + 1.5).to_f, {arguments: true})
        Debouncer.queue.expect(:push, nil, [expected_event])
        Debouncer.enqueue(1.5, :magic, "unique_key", {arguments: true})
        Debouncer.queue.verify
      end
    end
  end

  describe "enqueued?" do
    it "forwards the call to the queue" do
      Debouncer.queue = MiniTest::Mock.new
      Debouncer.queue.expect(:enqueued?, true, ["the_event_id"])
      Debouncer.enqueued?("the_event_id").must_equal true
      Debouncer.queue.verify
    end
  end

  describe "remove" do
    it "forwards the call to the queue" do
      Debouncer.queue = MiniTest::Mock.new
      Debouncer.queue.expect(:remove, nil, ["the_event_id"])
      Debouncer.remove("the_event_id")
      Debouncer.queue.verify
    end

    it "forwards the call to the queue" do
      Debouncer.queue = MiniTest::Mock.new
      Debouncer.queue.expect(:remove, nil, [["the_event_id", "another_event_id"]])
      Debouncer.remove(["the_event_id", "another_event_id"])
      Debouncer.queue.verify
    end
  end

  describe "peek" do
    it "forwards the call to the queue" do
      Debouncer.queue = MiniTest::Mock.new
      expected_event = Debouncer::Event.new
      Debouncer.queue.expect(:peek, expected_event, ["the_event_id"])
      Debouncer.peek("the_event_id").must_be_same_as expected_event
      Debouncer.queue.verify
    end
  end
end
