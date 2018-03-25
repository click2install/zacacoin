# ZacaCoin

Shell script to install a [ZacaCoin Masternode](https://bitcointalk.org/index.php?topic=2988037.0) on a Linux server running Ubuntu 16.04.

&nbsp;


## Installation
```
wget -q https://github.com/click2install/zacacoin/master/install-zaca.sh  
chmod +x install-zaca.sh
bash install-zaca.sh
```
&nbsp;


## Multiple Master Nodes on one server
The script allows for multiple nodes to be setup. During the execution of the script you have the opportunity to decide on a port and rpc port to use for the node. Each node runs under are different user account which the script creates for you.

&nbsp;


## Running the script
When you run the script it will tell you what it will do on your system. Once completed there is a summary of the information you need to be aware of regarding your node setup which you can copy/paste to your local PC.

If you want to run the script before setting up the node in your cold wallet the script will generate a priv key for you to use, otherwise you can supply the privkey during the script execution.

&nbsp;

## Security
The script allows for a custom SSH port to be specified as well as setting up the required firewall rules to only allow inbound SSH and node communications, whilst blocking all other inbound ports and all outbound ports.

The [fail2ban](https://www.fail2ban.org/wiki/index.php/Main_Page) package is also used to mitigate DDoS attempts on your server.



