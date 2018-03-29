#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE="zaca.conf"
DEFAULTUSER="zaca-mn1"
DEFAULTPORT=48882
DEFAULTSSHPORT=22
BINARY_NAME="zacad"
BINARY_FILE="/usr/local/bin/$BINARY_NAME"
ZACA_DAEMON_ZIP="https://github.com/zacacoin/zacacoin/raw/2.0.0.1/src/zacad.zip"
GITHUB_REPO="https://github.com/zacacoin/zacacoin"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function checks() 
{
  if [[ $(lsb_release -d) != *16.04* ]]; then
    echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
    exit 1
  fi

  if [[ $EUID -ne 0 ]]; then
     echo -e "${RED}$0 must be run as root.${NC}"
     exit 1
  fi

  if [ -n "$(pidof $BINARY_NAME)" ]; then
    read -e -p "$(echo -e The ZACA daemon is already running.$YELLOW Do you want to add another master node? [Y/N] $NC)" NEW_NODE
    clear
  else
    NEW_NODE="new"
  fi
}

function prepare_system() 
{
  clear
  echo -e "Checking if swap space is required."
  PHYMEM=$(free -g | awk '/^Mem:/{print $2}')
  
  if [ "$PHYMEM" -lt "2" ]; then
    SWAP=$(swapon -s get 1 | awk '{print $1}')
    if [ -z "$SWAP" ]; then
      echo -e "${GREEN}Server is running without a swap file and less than 2G of RAM, creating a 2G swap file.${NC}"
      dd if=/dev/zero of=/swapfile bs=1024 count=2M
      chmod 600 /swapfile
      mkswap /swapfile
      swapon -a /swapfile
    else
      echo -e "${GREEN}Swap file already exists.${NC}"
    fi
  else
    echo -e "${GREEN}Server running with at least 2G of RAM, no swap file needed.${NC}"
  fi
  
  echo -e "${GREEN}Updating package manager${NC}."
  apt update
  
  echo -e "${GREEN}Upgrading existing packages, it may take some time to finish.${NC}"
  DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade 
  
  echo -e "${GREEN}Installing all dependencies for the ZACA coin master node, it may take some time to finish.${NC}"
  apt install -y software-properties-common
  apt-add-repository -y ppa:bitcoin/bitcoin
  apt update
  apt install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    make software-properties-common build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
    libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget pwgen curl \
    bsdmainutils libdb5.3-dev libdb5.3++-dev libminiupnpc-dev libgmp3-dev ufw fail2ban htop unzip
  clear
  
  if [ "$?" -gt "0" ]; then
      echo -e "${RED}Not all of the required packages were installed correctly.\n"
      echo -e "Try to install them manually by running the following commands:${NC}\n"
      echo -e "apt update"
      echo -e "apt -y install software-properties-common"
      echo -e "apt-add-repository -y ppa:bitcoin/bitcoin"
      echo -e "apt update"
      echo -e "apt install -y make software-properties-common build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
    libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget pwgen curl \
    bsdmainutils libdb5.3-dev libdb5.3++-dev libminiupnpc-dev libgmp3-dev ufw fail2ban htop unzip"
   exit 1
  fi

  clear
}

function deploy_binary() 
{
  if [ -f $BINARY_FILE ]; then
    echo -e "${GREEN}Zaca daemon binary file already exists, using binary from $BINARY_FILE.${NC}"
  else
    cd $TMP_FOLDER

    echo -e "${GREEN}Downloading $ZACA_DAEMON_ZIP and deploying the zaca service.${NC}"
    wget $ZACA_DAEMON_ZIP -O zaca.zip >/dev/null 2>&1

    unzip zaca.zip -d . >/dev/null 2>&1
    cp $BINARY_NAME /usr/local/bin/ >/dev/null 2>&1
    chmod +x $BINARY_FILE >/dev/null 2>&1

    cd
  fi
}

function check_compile_error()
{
  if [ "$?" -ne 0 ]; then
    echo -e "${RED}Failed to compile zaca service.${NC}"
    exit 1
  fi
}

function compile_binary()
{
  echo -e "${GREEN}Downloading zaca source code from $GITHUB_REPO.${NC}"

  git clone $GITHUB_REPO $TMP_FOLDER
  cd $TMP_FOLDER/src

  echo -e "${GREEN}Compiling the zaca source code, this will take about 10 minutes to finish.${NC}"
  make -f makefile.unix

  check_compile_error

  cp $BINARY_NAME /usr/local/bin/ >/dev/null 2>&1
  chmod +x $BINARY_FILE >/dev/null 2>&1

  clear
  cd
  echo -e "${GREEN}Zaca compilation finished.${NC}"
}

function enable_firewall() 
{
  echo -e "${GREEN}Installing fail2ban and setting up firewall to allow access on port $DAEMONPORT.${NC}"

  apt install ufw -y >/dev/null 2>&1

  ufw disable >/dev/null 2>&1
  ufw allow $DAEMONPORT/tcp comment "Zaca Masternode port" >/dev/null 2>&1
  ufw allow $[DAEMONPORT+1]/tcp comment "Zaca Masernode RPC port" >/dev/null 2>&1
  
  ufw allow $SSH_PORTNUMBER/tcp comment "Custom SSH port" >/dev/null 2>&1
  ufw limit $SSH_PORTNUMBER/tcp >/dev/null 2>&1

  ufw logging on >/dev/null 2>&1
  ufw default deny incoming >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1

  echo "y" | ufw enable >/dev/null 2>&1
  systemctl enable fail2ban >/dev/null 2>&1
  systemctl start fail2ban >/dev/null 2>&1
}

function add_daemon_service() 
{
  cat << EOF > /etc/systemd/system/$ZACAUSER.service
[Unit]
Description=Zaca deamon service
After=network.target
[Service]
Type=forking
User=$ZACAUSER
Group=$ZACAUSER
WorkingDirectory=$ZACAFOLDER
ExecStart=$BINARY_FILE -daemon -datadir=$ZACAFOLDER
ExecStop=$BINARY_FILE stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
  
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3

  echo -e "${GREEN}Starting the Zaca service from $BINARY_FILE on port $DAEMONPORT.${NC}"
  systemctl start $ZACAUSER.service >/dev/null 2>&1
  
  echo -e "${GREEN}Enabling the service to start on reboot.${NC}"
  systemctl enable $ZACAUSER.service >/dev/null 2>&1

  if [[ -z $(pidof $BINARY_NAME) ]]; then
    echo -e "${RED}The zaca masternode service is not running${NC}. You should start by running the following commands as root:"
    echo "systemctl start $ZACAUSER.service"
    echo "systemctl status $ZACAUSER.service"
    echo "less /var/log/syslog"
    exit 1
  fi
}

function ask_port() 
{
  read -e -p "$(echo -e $YELLOW Enter a port to run the zaca service on: $NC)" -i $DEFAULTPORT DAEMONPORT
}

function ask_user() 
{  
  read -e -p "$(echo -e $YELLOW Enter a new username to run the zaca service as: $NC)" -i $DEFAULTUSER ZACAUSER

  if [ -z "$(getent passwd $ZACAUSER)" ]; then
    useradd -m $ZACAUSER
    USERPASS=$(pwgen -s 12 1)
    echo "$ZACAUSER:$USERPASS" | chpasswd

    ZACAHOME=$(sudo -H -u $ZACAUSER bash -c 'echo $HOME')
    ZACAFOLDER="$ZACAHOME/.zaca"
        
    mkdir -p $ZACAFOLDER
    chown -R $ZACAUSER: $ZACAFOLDER >/dev/null 2>&1
  else
    clear
    echo -e "${RED}User already exists. Please enter another username.${NC}"
    ask_user
  fi
}

function check_port() 
{
  declare -a PORTS

  PORTS=($(netstat -tnlp | awk '/LISTEN/ {print $4}' | awk -F":" '{print $NF}' | sort | uniq | tr '\r\n'  ' '))
  ask_port

  while [[ ${PORTS[@]} =~ $DAEMONPORT ]] || [[ ${PORTS[@]} =~ $[DAEMONPORT+1] ]]; do
    clear
    echo -e "${RED}Port in use, please choose another port:${NF}"
    ask_port
  done
}

function ask_ssh_port()
{
  read -e -p "$(echo -e $YELLOW Enter a port for SSH connections to your VPS: $NC)" -i $DEFAULTSSHPORT SSH_PORTNUMBER

  sed -i "s/[#]\{0,1\}[ ]\{0,1\}Port [0-9]\{2,\}/Port ${SSH_PORTNUMBER}/g" /etc/ssh/sshd_config
  systemctl reload sshd
}

function create_config() 
{
  RPCUSER=$(pwgen -s 8 1)
  RPCPASSWORD=$(pwgen -s 15 1)
  cat << EOF > $ZACAFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
rpcport=$[DAEMONPORT+1]
listen=1
server=1
daemon=1
staking=1
port=$DAEMONPORT
EOF
}

function create_key() 
{
  read -e -p "$(echo -e $YELLOW Enter your master nodes private key. Leave it blank to generate a new private key.$NC)" ZACAPRIVKEY

  if [[ -z "$ZACAPRIVKEY" ]]; then
    sudo -u $ZACAUSER $BINARY_FILE -daemon -datadir=$ZACAFOLDER >/dev/null 2>&1
    sleep 5

    if [ -z "$(pidof $BINARY_NAME)" ]; then
    echo -e "${RED}zaca deamon couldn't start, could not generate a private key. Check /var/log/syslog for errors.${NC}"
    exit 1
    fi

    ZACAPRIVKEY=$(sudo -u $ZACAUSER $BINARY_FILE -datadir=$ZACAFOLDER masternode genkey) 
    sudo -u $ZACAUSER $BINARY_FILE -datadir=$ZACAFOLDER stop >/dev/null 2>&1
  fi
}

function update_config() 
{
  NODEIP=$(ip route get 1 | awk '{print $NF;exit}')
  cat << EOF >> $ZACAFOLDER/$CONFIG_FILE
logtimestamps=1
maxconnections=256
masternode=1
masternodeaddr=$NODEIP:$DAEMONPORT
masternodeprivkey=$ZACAPRIVKEY
EOF
  chown $ZACAUSER: $ZACAFOLDER/$CONFIG_FILE >/dev/null
}

function add_log_truncate()
{
  ZACALOGFILE="$ZACAFOLDER/debug.log";

  mkdir ~/.zaca >/dev/null 2>&1
  cat << EOF >> ~/.zaca/clearlog-$ZACAUSER.sh
/bin/date > $ZACALOGFILE
EOF

  chmod +x ~/.zaca/clearlog-$ZACAUSER.sh

  if ! crontab -l | grep "~/zaca/clearlog-$ZACAUSER.sh"; then
    (crontab -l ; echo "0 0 */2 * * ~/.zaca/clearlog-$ZACAUSER.sh") | crontab -
  fi
}

function show_output() 
{
 echo
 echo -e "================================================================================================================================"
 echo
 echo -e "Your ZACA coin master node is up and running." 
 echo -e " - it is running as user ${GREEN}$ZACAUSER${NC} and it is listening on port ${GREEN}$DAEMONPORT${NC} at your VPS address ${GREEN}$NODEIP."
 echo -e " - the ${GREEN}$ZACAUSER${NC} password is ${GREEN}$USERPASS${NC}"
 echo -e " - the ZACA configuration file is located at ${GREEN}$ZACAFOLDER/$CONFIG_FILE${NC}"
 echo -e " - the masternode privkey is ${GREEN}$ZACAPRIVKEY${NC}"
 echo
 echo -e "You can manage your ZACA service from the cmdline with the following commands:"
 echo -e " - ${GREEN}systemctl start $ZACAUSER.service${NC} to start the service for the given user."
 echo -e " - ${GREEN}systemctl stop $ZACAUSER.service${NC} to stop the service for the given user."
 echo
 echo -e "The installed service is set to:"
 echo -e " - auto start when your VPS is rebooted."
 echo -e " - clear the ${GREEN}$ZACALOGFILE${NC} log file every 2nd day."
 echo
 echo -e "You can run ${GREEN}htop${NC} if you want to verify the zaca service is running or to monitor your server."
 if [[ $SSH_PORTNUMBER -ne $DEFAULTSSHPORT ]]; then
 echo
 echo -e " ATTENTION: you have changed your SSH port, make sure you modify your SSH client to use port $SSH_PORTNUMBER so you can login."
 fi
 echo 
 echo -e "================================================================================================================================"
 echo
}

function setup_node() 
{
  ask_user
  ask_ssh_port
  check_port
  create_config
  create_key
  update_config
  enable_firewall
  add_daemon_service
  add_log_truncate
  show_output
}

clear

echo
echo -e "============================================================================================================="
echo -e "${GREEN}"
echo -e "                                      8888P    db    .d88b    db"
echo -e "                                        dP    d  b   8P      d  b"
echo -e "                                       dP    dPwwYb  8b     dPwwYb" 
echo -e "                                      d8888 dP    Yb \`Y88P dP    Yb" 
echo                          
echo -e "${NC}"
echo -e "This script will automate the installation of your ZACA coin masternode and server configuration by"
echo -e "performing the following steps:"
echo
echo -e " - Prepare your system with the required dependencies"
echo -e " - Obtain the latest Zaca masternode files from the Zaca GitHub repository"
echo -e " - Create a user and password to run the zaca masternode service"
echo -e " - Install the Zaca masternode service"
echo -e " - Update your system with a non-standard SSH port (optional)"
echo -e " - Add DDoS protection using fail2ban"
echo -e " - Update the system firewall to only allow; SSH, the masternode ports and outgoing connections"
echo -e " - Add some scheduled tasks for system maintenance"
echo
echo -e "The script will output ${YELLOW}questions${NC}, ${GREEN}information${NC} and ${RED}errors${NC}"
echo -e "When finished the script will show a summary of what has been done."
echo
echo -e "Script created by click2install"
echo -e " - GitHub: https://github.com/click2install"
echo -e " - Discord: click2install#9625"
echo -e " - ZACA: ZtugezqGy4mVZpTU4tPBjKY4t7YwDyuDA2"
echo 
echo -e "============================================================================================================="
echo
read -e -p "$(echo -e $YELLOW Do you want to continue? [Y/N] $NC)" CHOICE

if [[ ("$CHOICE" == "n" || "$CHOICE" == "N") ]]; then
  exit 1;
fi

checks

if [[ ("$NEW_NODE" == "y" || "$NEW_NODE" == "Y") ]]; then
  setup_node
  exit 0
elif [[ "$NEW_NODE" == "new" ]]; then
  prepare_system
  deploy_binary
  #compile_binary
  setup_node
else
  echo -e "${GREEN}ZACA daemon already running.${NC}"
  exit 0
fi
