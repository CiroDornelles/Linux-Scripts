evento=$1 
arquivo=$2
monitoredfolder=$3
bucket=$4
echo $arquivo | awk -F '/$monitoredfolder/' '{print $2}'

path=`echo $arquivo | rev | cut -d "/" -f2-900 | rev`


netsh interface portproxy add v4tov4 listenaddress=172.31.13.250 listenport=80 connectaddress=172.31.13.232 connectport=80

netsh interface portproxy add v4tov4 listenaddress=172.31.13.250 listenport=443 connectaddress=172.31.13.232 connectport=443