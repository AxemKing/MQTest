require 'bunny'
require 'ox'

conn = Bunny.new(hostname: '192.168.0.7')
conn.start

ch = conn.create_channel
q = ch.queue("hello")

q.subscribe(:block => true) do |delivery_info, properties, body|
  message = Ox.parse_obj(body)
  puts " [x] Received #{message}"
end
