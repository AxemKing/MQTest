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
			@queue.pop
		end
	end

	def empty?
		@mutex.synchronize do
			@queue.empty?
		end
	end
end

class Consumer
	def initialize(bunny_connection)
		@ch = bunny_connection.create_channel
		@q = @ch.queue("hello")
		@do_ack = false
		@mutex = Mutex.new
		@queue = ConsumerQueue.new
	end

	def consume
		@q.subscribe(ack: true, block: true) do |delivery_info, properties, body|
			@queue.publish(body)
			if @do_ack
				@ch.ack(delivery_info.delivery_tag, true)
				@mutex.synchronize do
					@do_ack = false
				end
			end
		end
	end

	def ack
		@mutex.synchronize do
			@do_ack = true
		end
	end

	def with_queue
		yield @queue
	end
end	

conn = Bunny.new(hostname: 'ME')
conn.start
 
consumer = Consumer.new(conn)

threads = []
threads << Thread.new do
	while true
		consumer.with_queue do |queue|
			if !queue.empty?
				while !queue.empty? do
					puts "consuming"
					queue.consume
				end
			end
			consumer.ack
		end
	end
end
consumer.consume
