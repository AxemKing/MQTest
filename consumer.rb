require 'bunny'
require 'yaml'
require 'pp'
require 'thwait'

conn = Bunny.new(hostname: 'ME')
conn.start

ch = conn.create_channel
threads = []
stop = false

threads << Thread.new do
	q = ch.queue("", exclusive: true)
	x = ch.fanout("hello")
	q.bind(x)
	
	q.subscribe(block:  true) do |delivery_info, properties, body|
		pp " [x] Received log: #{body}"
		ch.ack(delivery_info.delivery_tag)
		
		delivery_info.consumer.cancel if stop
	end
	ch.close
end

threads << Thread.new do
	ch2 = conn.create_channel
	q2 = ch2.queue("hello")
	
	q2.subscribe(ack: true, block:  true) do |delivery_info, properties, body|
		body = body.strip
		pp YAML::load(body)
		ch2.ack(delivery_info.delivery_tag)
		
		delivery_info.consumer.cancel if stop
	end
	ch2.close
end

begin
	ThreadsWait.all_waits(threads)
rescue Interrupt => e
	stop = true
end
conn.close