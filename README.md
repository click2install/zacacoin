# ZacaCoin

Shell script to install a [ZacaCoin Masternode](https://bitcointalk.org/index.php?topic=2988037.0) on a Linux server running Ubuntu 16.04.


## Installation
```
wget -q https://raw.githubusercontent.com/click2install/zacacoin/master/install-zaca.sh  
bash install-zaca.sh
```
This script is intended to be used on a clean server, or a server that has used this script to install 1 or more previous nodes. 

If you use this script to install a masternode on a server that has existing zaca masternodes installed by other means you will end up with two different zaca daemons running. This will not cause an issue, but if a daemon update is required at some time in the future you will need to update more than one daemon.

There is a [manual installation](https://medium.com/@click2install.moore/definitive-guide-to-setting-up-a-zacacoin-masternode-319d7c99d419) guide that you can use as an alternative to this script.

Donations for the creation and maintenance of this script are welcome at:
&nbsp;

ZACA: ZtugezqGy4mVZpTU4tPBjKY4t7YwDyuDA2

&nbsp;

## How to setup your masternode with this script and a cold wallet on your PC
The script assumes you are running a cold wallet on your local PC and this script will execute on a Ubuntu Linux VPS (server). The steps involved are:

 1. Run this script as the instructions detail below
 2. When you are finished this process you will get some infomration on what has been done as well as some important information you will need for your cold wallet setup
 3. Copy/paste the output of this script into a text file and keep it safe.

You are now ready to configure your local wallet and finish the masternode setup

 1. Make sure you have downloaded the latest wallet from https://github.com/devzaca/zacacoin/releases
 2. Install the wallet on your local PC
 3. Start the wallet and let if completely synchronize to the network - this will take some time
 4. Make sure you have at least 7500.00004 ZACA in your wallet
 5. Open your wallet debug console by going to Help > Debug Window
 6. In the console type: `getnewaddress [address-name]` - e.g. `getnewaddress mn1`
 7. In the console type: `sendtoaddress [output from #6] 1000`
 8. Wait for the transaction from #7 to be fully confirmed. Look for a tick in the first column in your transactions tab
 9. Once confirmed, type in your console: `masternode outputs`
 10. Open your masternode configuration file which will be located in your data directory which can be accessed by entering `%appdata%\zaca` into your Windows, Start > Run dialog
 11. In your masternodes.conf file add an entry that looks like: `[address-name from #6] [ip:port of your VPS] [privkey from script output] output index [txid from from #9] [output index from #9]` - 
 12. Your masternodes.conf file entry should look like: `MN-1 127.0.0.2:48882 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg 2bcd3c84c84f87eaa86e4e56834c92927a07f9e18718810b92e0d0324456a67c 0`
 13. Save and close your masternodes.conf file
 14. Close your wallet and restart
 15. Go to Masternodes > My MasterNodes
 16. Click the row for the masternode you just added
 17. Right click > Start Alias
 18. Your node should now be running successfully.

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






