from kafka import KafkaProducer

# Kafka broker address
bootstrap_servers = 'localhost:9092'

# Create Kafka producer instance
producer = KafkaProducer(bootstrap_servers=bootstrap_servers)

# Topic to produce messages to
topic = 'NeoGames'

# Produce messages
messages = [
    'Hello, NeoGames!',
    'Welcome to the task from Ruslan Serdiuk.',
    'Enjoy your gaming experience!'
]

for message in messages:
    producer.send(topic, message.encode('utf-8'))

# Wait for all messages to be sent
producer.flush()

# Close the producer
producer.close()
