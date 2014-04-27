require 'bunny'
require 'yaml'
require 'pp'
require 'thwait'

conn = Bunny.new(hostname: 'ME')
conn.start

mutex = Mutex.new

threads = []
stop = false

threads << Thread.new do
	ch = conn.create_channel
	q = ch.queue("", exclusive: true)
	x = ch.fanout("logs")
	q.bind(x)
	
	q.subscribe(block: true) do |delivery_info, properties, body|
		mutex.synchronize do
			pp " [x] Received log: #{body}"
		end
		
		delivery_info.consumer.cancel if stop
	end
	ch.close
end

threads << Thread.new do
	ch2 = conn.create_channel
	q2 = ch2.queue("hello")
	
	q2.subscribe(ack: true, block:  true) do |delivery_info, properties, body|
		body = body.strip
		mutex.synchronize do
			pp YAML::load(body)
		end
		ch2.ack(delivery_info.delivery_tag)
		
		delivery_info.consumer.cancel if stop
	end
	ch2.close
end

begin
	threads.each do |thread| thread.join end
rescue Interrupt => e
	threads.each do |thread| thread.join end
end
stop = true
conn.close
