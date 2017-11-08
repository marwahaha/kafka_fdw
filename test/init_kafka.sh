#!/bin/bash
: ${PG_PORT:=5432}
: ${KAFKA_PRODUCER:="/usr/local/bin/kafka-console-producer"}
: ${KAFKA_TOPICS:="/usr/local/bin/kafka-topics"}

topic_part4="contrib_regress4"
simple_topic="contrib_regress"
prod_topic="contrib_regress_prod"
out_sql="SELECT i, 'It''s some text, that is for number '||i, ('2015-01-01'::date + (i || ' seconds')::interval)::date, ('2015-01-01'::date + (i || ' seconds')::interval)::timestamp FROM generate_series(1,1e6::int, 10) i ORDER BY i"
kafka_cmd="$KAFKA_PRODUCER --broker-list localhost:9092 --topic"

# delete topic if it might exist
for t in $simple_topic $topic_part4 $prod_topic; do
    $KAFKA_TOPICS --zookeeper localhost:2181 --delete --topic ${t}
done
sleep 2

# create topic with 4 partitions
$KAFKA_TOPICS --zookeeper localhost:2181 --create --topic ${simple_topic} --partitions 1 --replication-factor 1
$KAFKA_TOPICS --zookeeper localhost:2181 --create --topic ${topic_part4} --partitions 4 --replication-factor 1
$KAFKA_TOPICS --zookeeper localhost:2181 --create --topic ${prod_topic} --partitions 4 --replication-factor 1

# write some test data to topicc
for t in $simple_topic $topic_part4; do
	psql -c "COPY(${out_sql}) TO STDOUT (FORMAT CSV);" -d postgres -p $PG_PORT -o "| ${kafka_cmd} ${t}" >/dev/null
done;