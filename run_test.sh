#!/bin/bash
echo "Iniciando bateria 1"
artillery run -e local longload25.yml
#echo "Iniciando bateria 1"
#artillery run -e local load25.yml
#echo "Aguardando proxima bateria"
#sleep 120
#echo "Iniciando bateria 2"
#artillery run -e local load50.yml
#echo "Aguardando proxima bateria"
#sleep 120
#echo "Iniciando bateria 3"
#artillery run -e local load100.yml
#echo "Aguardando proxima bateria"
#sleep 120
#echo "Iniciando bateria 4"
#artillery run -e local load1000.yml
#echo "Aguardando proxima bateria"
##sleep 120
#echo "Iniciando bateria 5"
#artillery run -e local load5000.yml
#echo "Teste concluído"
