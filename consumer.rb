require 'bunny'
require 'yaml'
require 'pp'
require 'thwait'

conn = Bunny.new(hostname: 'ME')
conn.start

ch = conn.create_channel
q = ch.queue("", exclusive: true)
x = ch.fanout("hello")
q.bind(x)

threads = []
stop = false

threads << Thread.new do
	q.subscribe(block:  true) do |delivery_info, properties, body|
		body = body.strip
		pp " [x] Received log: #{body}"
		pp YAML::load(body)
		ch.ack(delivery_info.delivery_tag)
		
		delivery_info.consumer.cancel if stop
	end
end

q2 = ch.queue("hello")

threads << Thread.new do
	q2.subscribe(ack: true, block:  true) do |delivery_info, properties, body|
		body = body.strip
		pp " [x] Received #{body}"
		pp YAML::load(body)
		ch.ack(delivery_info.delivery_tag)
		
		delivery_info.consumer.cancel if stop
	end
end

begin
	ThreadsWait.all_waits(threads)
rescue Interrupt => e
	stop = true
end
ch.close
conn.close