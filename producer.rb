require "bunny"

conn = Bunny.new(hostname: "ME")
conn.start
ch = conn.create_channel
q = ch.queue("hello")
begin
	while true do
		ch.default_exchange.publish("Hello World1", routing_key: q.name)
	end
rescue Interrupt => int
end

conn.close
