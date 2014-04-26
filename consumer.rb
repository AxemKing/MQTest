require 'bunny'
require 'yaml'
require 'pp'

conn = Bunny.new(hostname: 'ME')
conn.start

ch = conn.create_channel
q = ch.queue("hello")

q.subscribe(ack: true, block:  true) do |delivery_info, properties, body|
  body = body.strip
  pp " [x] Received #{body}"
  pp YAML::load(body)
  ch.ack(delivery_info.delivery_tag)
end
