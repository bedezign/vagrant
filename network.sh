#!/usr/local/bin/bash
# Note: this script requires Bash4, because of the associative indexes. You can install it via homebrew

declare -A MAP
declare -A PORTS

# The base IP for the aliases
BASE=172.16.190.

# Last IP Byte -> Hostname
MAP[1]=myfirstsite.dev
MAP[2]=mysecondsite.dev
MAP[3]=mythirdsite.dev

# Ports to forward and the base port on the host (resulting port will be this base port + last IP byte)
PORTS[80]=2000          # Web
PORTS[22]=2010          # SSH
PORTS[3306]=2020        # MySQL
PORTS[27017]=2030       # MongoDB
PORTS[28017]=2040       # MongoDB - Management

# Max amount of "vhosts" (to cleanup the aliases) - If you use more than 10 you'll have to change the ports
MAX=10

echo "Cleanup..."

# Flush port forwards (firewall back to default)
sudo pfctl -Fa -f /etc/pf.conf
sudo ipfw -f flush

# Remove previous aliases
for i in `seq 1 $MAX`;
do
	sudo ifconfig lo0 $BASE$i delete 2>/dev/null
done

# "Reset" hosts file
sudo sed -i '' "/# VAGRANT HOST/d" /etc/hosts
echo
echo

echo "Adding hosts..."
# Add new hosts
for k in "${!MAP[@]}"
do
	HOST=${MAP[$k]}
	IP=$BASE$k
	echo ">>> $HOST: $IP"
	echo "* Adding alias"
	sudo ifconfig lo0 $IP alias
	echo "* Port forwards"
	for i in "${!PORTS[@]}"
	do
		DEST=$i
		SOURCE=${PORTS[$i]}
		SOURCE=`expr $SOURCE + $k`
		echo "  - $IP:$SOURCE -> localhost:$DEST"
		sudo ipfw add fwd 127.0.0.1,$SOURCE tcp from me to $IP dst-port $DEST
		# Should use pfctl here but can't find a cli version of this command
		# rdr pass on lo0 inet proto tcp from any to any port 80 -> 127.0.0.1 port 15021
	done

	echo "* Adding /etc/hosts entry"
	CMD='echo "'$IP'	'$HOST'		# VAGRANT HOST" >>/etc/hosts'
	sudo /bin/bash -c "$CMD"
	echo "<<< DONE"
	echo
done
