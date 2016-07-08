# Iniciar el servidor de freeradius. Esto creará un fichero callgrind.out.1234
#  --combine-dumps=no|yes
#  --callgrind-out-file=<f> 

HOME="/home/devel/freeradius"
VALGRIND="sudo valgrind --tool=callgrind --collect-jumps=yes --simulate-cache=yes --combine-dumps=yes "
FREERADIUS_PATH_TEST=$HOME"/src/tests/test-kafka/"

CALLGRIND_OUT=callgrind.out.final
OUTPUT="--callgrind-out-file=callgrind.out.final "
RADIUSD_FILE="radiusd-4"
FREERADIUS=$HOME"/src/main/.libs/radiusd -d "$HOME"/raddb -n "$RADIUSD_FILE" -l /tmp/aaadd -f"

# debbug mode:
#sudo cgdb --args ~/freeradius/src/main/.libs/radiusd -d /home/devel/freeradius/raddb -n radiusd -l  /tmp/aaadd -f

echo "==============================================="
echo "Freeradius server"
echo $VALGRIND$OUTPUT$FREERADIUS
echo "==============================================="
sudo $VALGRIND$OUTPUT$FREERADIUS & 1>&2 > ./valgrind-out.log

## Notas:
#
# radiusd-1 (Es sin topic, tiene que fallar en el arranque.
# radiusd-2 (sin broker, no van a llegar)
# radiusd-3 y 4 es el mismo caso.
# radiusd-5 Con texto de enriquecimiento.

sleep 20

# kafkacat:

KAFKACAT_PATH="/home/devel/freeradius/src/tests/kafkacat-debian-1.3.0-1"
JSON_OUT='kafka_json_messages4.log'

echo "==============================================="
echo "Kafkacat. Get the json messages. output: 'json_out_kafka.log' "
echo $KAFKACAT_PATH/kafkacat -C -c 3 -o beggining -b 10.0.30.89 -t radius4
echo "==============================================="
$KAFKACAT_PATH/kafkacat -C -c 3 -o beggining -b 10.0.30.89 -t radius4 > $JSON_OUT &


TEST_USER=$HOME"/src/main/.libs/radclient localhost:1813 acct testing123 -f "$HOME"/src/tests/test-kafka/"
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

sleep 10
if ps aux | grep -v "grep" | grep "valgrind" 1> /dev/null
then
    echo "Valgrind is running. Send SIGINT to valgrind"
    for i in `ps aux | grep -v "grep"|grep "valgrind"|awk '{print $2}'|uniq`; do sudo kill -SIGINT $i; done
else
   echo "Valgrind is stopped"
fi

sudo chown devel: callgrind.out.final
 
## Comprobar los json enviados a kafka.
sleep 5
if ps aux | grep -v "grep" | grep "kafkacat" 1> /dev/null
then
    echo "kafkacat is running. Kill it."
    for i in `ps aux | grep -v "grep"|grep "kafkacat"|awk '{print $2}'|uniq`; do sudo kill -SIGINT $i; done
else
   echo "kafkacat is stopped"
fi

# test4
PYCHECKJSON="/usr/bin/checkjson.py"
JSON_CHECK_TEMPLATE="template-4.json"
#DEBUG=" -d"
DEBUG=""
echo "==============================================="
echo $PYCHECKJSON -t $FREERADIUS_PATH_TEST$JSON_CHECK_TEMPLATE -j $JSON_OUT$DEBUG
echo "==============================================="
$PYCHECKJSON -t $FREERADIUS_PATH_TEST$JSON_CHECK_TEMPLATE -j $JSON_OUT$DEBUG


## Coverage system:

CALLGRIND_PATH="/home/devel/tools/callgrind_tools/callgrind_coverage/cg_coverage"
CALLGRIND_OUT="callgrind-out-4.log"
$CALLGRIND_PATH callgrind.out.final $HOME"/src/modules/rlm_kafka/rlm_kafka_log.c" > $CALLGRIND_OUT
echo "==============================================="
echo $CALLGRIND_PATH callgrind.out.final $HOME"/src/modules/rlm_kafka/rlm_kafka_log.c"
echo "==============================================="
echo "Callgrind file: " $CALLGRIND_OUT
