require 'debouncer'

Debouncer.add_callback(:send) do |args|
  puts "Send: #{args}"
end

Debouncer.start_async

Debouncer.enqueue(0.1, :send, 12345678, {a: 1, b: 2})
Debouncer.enqueue(0.1, :send)
Debouncer.enqueue(0.1, :send, 12345678)
Debouncer.enqueue(0.1, :send, "abc1234567890")
Debouncer.enqueue(0.1, :send, {a: 1, b: 2})
Debouncer.enqueue(0.1, :send, 1, {a: 1, b: 2})
Debouncer.enqueue(0.1, :send, 2, {a: 1, b: 2})
Debouncer.enqueue(0.1, :send, 1, {a: 1, b: 2})

sleep 2
