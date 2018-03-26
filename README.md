# ZacaCoin

Shell script to install a [ZacaCoin Masternode](https://bitcointalk.org/index.php?topic=2988037.0) on a Linux server running Ubuntu 16.04.


## Installation
```
wget -q https://raw.githubusercontent.com/click2install/zacacoin/master/install-zaca.sh  
bash install-zaca.sh
```
This script is intended to be used on a clean server, or a server that has used this script to install previous nodes as it has expectations about where files are located. If you use this script after installing a node using another method, you will most likely end up having problems with your nodes, they may not start/stop correctly or receive rewards.

There is a [manual installation](https://medium.com/@click2install.moore/definitive-guide-to-setting-up-a-zacacoin-masternode-319d7c99d419) guide that you can use if you have already installed nodes on your server that have not used this script.

Donations for the creation and maintenance of this script are welcome at:
&nbsp;

ZACA: ZtugezqGy4mVZpTU4tPBjKY4t7YwDyuDA2

&nbsp;


## Multiple master nodes on one server
The script allows for multiple nodes to be setup on the same server, using the same IP address and different ports. 

During the execution of the script you have the opportunity to decide on a port and rpc port to use for the node. Each node runs under are different user account which the script creates for you.

At this stage the script auto detects the IP address of the server and uses it, without asking for user interaction. If you have multiple IP addresses you may want to adjust the configuration file that is generated after the script is finished. It resides in `/home/[username]/.zaca/zaca.conf`.

&nbsp;


## Running the script
When you run the script it will tell you what it will do on your system. Once completed there is a summary of the information you need to be aware of regarding your node setup which you can copy/paste to your local PC.

If you want to run the script before setting up the node in your cold wallet the script will generate a priv key for you to use, otherwise you can supply the privkey during the script execution.

&nbsp;

## Security
The script allows for a custom SSH port to be specified as well as setting up the required firewall rules to only allow inbound SSH and node communications, whilst blocking all other inbound ports and all outbound ports.

The [fail2ban](https://www.fail2ban.org/wiki/index.php/Main_Page) package is also used to mitigate DDoS attempts on your server.

Despite this script needing to run as `root` you should secure your Ubuntu server as normal with the following precautions:

 - disable password authentication
 - disable root login
 - enable SSH certificate login only

If the above precautions are taken you will need to `su root` before running the script.

&nbsp;

## Disclaimer
Whilst effort has been put into maintaining and testing this script, it will automatically modify settings on your Ubuntu server - use at your own risk. By downloading this script you are accepting all responsibility for any actions it performs on your server.

&nbsp;






