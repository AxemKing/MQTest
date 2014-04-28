require 'bunny'
require 'yaml'
require 'pp'
require 'thwait'

class ConsumerQueue
	def initialize
		@queue = Queue.new
		@mutex = Mutex.new
	end

	def publish(data)
		@mutex.synchronize do
			@queue.push(data)
		end
	end

	def consume
		@mutex.synchronize do
			while !@queue.empty?
				item = @queue.pop
				yield item
			end
		end
	end
end

class Consumer
	def initialize(bunny_connection)
		@ch = bunny_connection.create_channel
		@ch.prefetch(1000)
		@q = @ch.queue("hello")
		@do_ack = false
		@queue = ConsumerQueue.new
	end
	
	def consume
		last_tag = nil
		@q.subscribe(ack: true, block: false) do |delivery_info, properties, body|
			@queue.publish(body)
			last_tag = delivery_info.delivery_tag
		end
		while true
			sleep 0.1
			if @do_ack && last_tag
				@ch.ack(last_tag, true)
				last_tag = nil
			end
		end
	end

	def ack
		@do_ack = true
	end

	def unack
		@do_ack = false
	end

	def with_queue
		yield @queue
	end
end	

conn = Bunny.new(hostname: 'ME')
conn.start
 
consumer = Consumer.new(conn)

Thread.new do
	while true
		sleep 1
		consumer.unack
		consumer.with_queue do |queue|
			queue.consume do
			end
		end
		consumer.ack
	end
end

consumer.consume

while true do
	sleep 1
end
