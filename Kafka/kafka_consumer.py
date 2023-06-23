from kafka import KafkaConsumer

# Kafka broker address
bootstrap_servers = 'localhost:9092'

# Create Kafka consumer instance
consumer = KafkaConsumer('NeoGames', bootstrap_servers=bootstrap_servers)

# Consume messages from the 'NeoGames' topic
for message in consumer:
    print(message.value.decode('utf-8'))

# Close the consumer
consumer.close()
