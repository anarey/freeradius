HOME="/app"
FREERADIUS_PATH_TEST=$HOME"/src/tests/test-kafka/"

cp $FREERADIUS_PATH_TEST/conf/radiusd-4.conf $HOME/raddb/
cp $FREERADIUS_PATH_TEST/conf/radiusd-4.conf $HOME/raddb/
cp $FREERADIUS_PATH_TEST/conf/kafka_log_4.conf $HOME/raddb/
cp $FREERADIUS_PATH_TEST/conf/kafka_log_4.conf $HOME/raddb/

VALGRIND="valgrind --tool=callgrind --collect-jumps=yes --simulate-cache=yes --combine-dumps=yes "

CALLGRIND_OUT=callgrind.out.4.final
OUTPUT="--callgrind-out-file=callgrind.out.4.final "
RADIUSD_FILE="radiusd-4"
FREERADIUS=$HOME"/src/main/radiusd -d "$HOME"/raddb -n "$RADIUSD_FILE" -l freeradius.log -f"

# debbug mode:
#cgdb --args ~/freeradius/src/main/.libs/radiusd -d /home/devel/freeradius/raddb -n radiusd -l  /tmp/aaadd -f

ldconfig
echo "==============================================="
echo "Freeradius server"
echo $VALGRIND$OUTPUT$FREERADIUS
echo "==============================================="
$VALGRIND$OUTPUT$FREERADIUS &


## Notas:
#
# radiusd-1 (Es sin topic, tiene que fallar en el arranque.
# radiusd-2 (sin broker, no van a llegar)
# radiusd-3 y 4 es el mismo caso.
# radiusd-5 Con texto de enriquecimiento.

sleep 20

# kafkacat:

KAFKACAT_PATH="/kafkacat"
JSON_OUT='kafka_json_messages4.log'

IP_KAFKA="172.16.238.11"
echo "==============================================="
echo "Kafkacat. Get the json messages. output: 'json_out_kafka.log' "
echo $KAFKACAT_PATH/kafkacat -C -c 3 -o beggining -b $IP_KAFKA -t radius4
echo "==============================================="
$KAFKACAT_PATH/kafkacat -C -c 3 -o beggining -b $IP_KAFKA -t radius4 > $JSON_OUT &


TEST_USER=$HOME"/src/main/radclient localhost:1813 acct testing123 -d "$HOME"/raddb -f "$HOME"/src/tests/test-kafka/"
USER1="radclient-twodot.txt"
USER2="radclient-without.txt"
USER3="radclient.txt"

echo "==============================================="
echo $TEST_USER$USER1
echo $TEST_USER$USER2
echo $TEST_USER$USER3
echo "==============================================="
$TEST_USER$USER1
$TEST_USER$USER2
$TEST_USER$USER3
$KAFKACAT_PATH/kafkacat -L -b $IP_KAFKA -t radius4

echo "==============================================="
cat freeradius.log
echo "==============================================="

sleep 10

# Stop freeradius and kafkacat
if ps aux | grep -v "grep" | grep "valgrind" 1> /dev/null
then
    echo "Valgrind is running. Send SIGINT to valgrind"
    for i in `ps aux | grep -v "grep"|grep "valgrind"|awk '{print $2}'|uniq`; do kill -SIGINT $i; done
else
   echo "Valgrind is stopped"
fi

sleep 5
if ps aux | grep -v "grep" | grep "kafkacat" 1> /dev/null
then
    echo "kafkacat is running. Kill it."
    for i in `ps aux | grep -v "grep"|grep "kafkacat"|awk '{print $2}'|uniq`; do kill -SIGINT $i; done
else
   echo "kafkacat is stopped"
fi

rm $HOME/raddb/radiusd-4.conf
rm $HOME/raddb/kafka_log_4.conf

## Check the json file send to kafka

# test4
PYCHECKJSON="/bin/checkjson.py"
JSON_CHECK_TEMPLATE="template-4.json"
#DEBUG=" -d"
DEBUG=""
echo "==============================================="
echo $PYCHECKJSON -t $FREERADIUS_PATH_TEST$JSON_CHECK_TEMPLATE -j $JSON_OUT$DEBUG
echo "==============================================="
$PYCHECKJSON -t $FREERADIUS_PATH_TEST$JSON_CHECK_TEMPLATE -j $JSON_OUT$DEBUG

## Coverage system:

CALLGRIND_PATH="/callgrind/callgrind_coverage/cg_coverage"
CALLGRIND_OUT="callgrind-out-4.log"
$CALLGRIND_PATH callgrind.out.final $HOME"/src/modules/rlm_kafka/rlm_kafka_log.c" > $CALLGRIND_OUT
echo "==============================================="
echo $CALLGRIND_PATH callgrind.out.final $HOME"/src/modules/rlm_kafka/rlm_kafka_log.c"
echo "==============================================="
echo "Callgrind file: " $CALLGRIND_OUT

cat callgrind.out.final
