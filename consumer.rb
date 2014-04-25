require 'bunny'
require 'yaml'
require 'pp'

conn = Bunny.new(hostname: '192.168.0.7')
conn.start

ch = conn.create_channel
q = ch.queue("hello")

q.subscribe(:block => true) do |delivery_info, properties, body|
  body = body.strip
  pp " [x] Received #{body}"
  pp YAML::load(body)
end
