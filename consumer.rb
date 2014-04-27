require 'bunny'
require 'yaml'
require 'pp'
require 'thwait'

class Consumer
	def initialize(bunny_connection)
		@ch = bunny_connection.create_channel
		@q = @ch.queue("hello")
	end

	def consume
		@q.subscribe(ack: true, block: true) do |delivery_info, properties, body|
			@ch.ack(delivery_info.delivery_tag, true)
		end
	end
end

conn = Bunny.new(hostname: 'ME')
conn.start

consumers = []
3.times do 
	consumers << Consumer.new(conn)
end

threads = []
consumers.each do |consumer|
	threads << Thread.new do
		consumer.consume
	end
end

ThreadsWait.all_waits(threads)
