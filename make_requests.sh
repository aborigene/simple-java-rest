#!/bin/bash
names=("Igor" "João" "Eliane" "Marcelo" "Paçoca" "Baleia" "Olavo" "Luiz" )
while [ 0 ]; do

	echo "Calling ${names[$(( $RANDOM % 7))]}"
	curl "127.0.0.1:8083/greeting?name=${names[$(( $RANDOM % 8))]}"
	sleep 1
done
