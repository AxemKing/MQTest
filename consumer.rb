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

threads << Thread.new do
	begin
	  q.subscribe(block:  true) do |delivery_info, properties, body|
		body = body.strip
		pp " [x] Received log: #{body}"
		pp YAML::load(body)
		ch.ack(delivery_info.delivery_tag)
	  end
	rescue Interrupt => e
	  ch.close
	end
end

ch2 = conn.create_channel
q2 = ch2.queue("true")

threads << Thread.new do
	begin
	  q2.subscribe(ack: true, block:  true) do |delivery_info, properties, body|
		body = body.strip
		pp " [x] Received #{body}"
		pp YAML::load(body)
		ch2.ack(delivery_info.delivery_tag)
	  end
	rescue Interrupt => e
	  ch2.close
	end
end

ThreadsWait.all_waits(threads)
conn.close