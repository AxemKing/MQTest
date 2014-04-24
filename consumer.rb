require 'bunny'

conn = Bunny.new(hostname: '192.168.0.7')
conn.start

ch = conn.create_channel
q = ch.queue("hello")

q.subscribe(:block => true) do |delivery_info, properties, body|
  puts " [x] Received #{body}"

  # cancel the consumer to exit
  delivery_info.consumer.cancel
end
