#require 'bunny'
require 'march_hare'
require 'yaml'
require 'pp'
require 'thwait'

class ConsumerQueue
	def initialize
		@queue = Queue.new
		@mutex = Mutex.new
		@last_tag = -1
	end

	def publish(buffer)
		@mutex.synchronize do
			buffer.each do |item|
				@queue.push(item)
			end
		end
	end

	def consume
		@mutex.synchronize do
			while !@queue.empty?
				item = @queue.pop
				yield item[:data]
				@last_tag = item[:tag]
			end
		end
	end

	def last_tag
		@last_tag
	end
end

class Consumer
	def initialize(bunny_connection)
		@ch = bunny_connection.create_channel
		#@ch.prefetch(1000)
		@ch.prefetch = 1000
		@q = @ch.queue("hello")
		@ack_tag = -1
		@queue = ConsumerQueue.new
	end
	
	def consume
		mutex = Mutex.new
		queue_buf = []
		last_tag = -1
		#@q.subscribe(ack: true, block: false) do |delivery_info, properties, body|
		@q.subscribe(:manual_ack => true, block: false) do |metadata, body|
			mutex.synchronize do
				#queue_buf << { data: body, tag: delivery_info.delivery_tag }
				queue_buf << { data: body, tag: metadata.delivery_tag }
			end
		end
		while true
			sleep 0.1
			mutex.synchronize do
				@queue.publish(queue_buf)
				queue_buf = []
			end
			if @ack_tag != -1 && @ack_tag.tag > last_tag
				@ch.ack(@ack_tag, true)
				#last_tag = @ack_tag
				last_tag = @ack_tag.tag
			end
		end
	end

	def ack(tag)
		@ack_tag = tag
	end

	def ack_tag
		@ack_tag
	end

	def with_queue
		yield @queue
	end
end	

#conn = Bunny.new(hostname: 'ME', user: "admin", pass: "admin")
#conn.start
conn = MarchHare.connect(hostname: 'ME', user: 'admin', pass: 'admin')
 
consumer = Consumer.new(conn)

Thread.new do
	while true
		sleep 0.1
		consumer.with_queue do |queue|
			queue.consume do |data|
				data = data.strip
				cls = YAML::load(data)
			end
		end
	end
end

Thread.new do
	while true
		sleep 0.1
		consumer.with_queue do |queue|
			last_tag = queue.last_tag
			consumer.ack(last_tag)
		end
	end
end

consumer.consume

while true do
	sleep 1
end
