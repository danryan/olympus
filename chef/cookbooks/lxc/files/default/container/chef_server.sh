sudo bash -c 'echo "127.0.0.1 chef.lxc.doloreslabs.com" >>/etc/hosts'

bash -c '

#
# Bootstrap a new Chef server
#
# This script will:
# * Install build dependencies for Ruby
# * Install latest stable Ruby 1.8 from APT
# * Install latest Chef 0.9.x via APT
# * Create Chef configuration files needed for bootstrapping
# * Bootstrap the Chef server installation process
#


# Setup our default values and overrides:

cat >/tmp/selections <<EOF
chef-server-webui   chef-server-webui/admin_password    password    123dolores
# New password for the "chef" AMQP user in the RabbitMQ vhost "/chef":
chef-solr      chef-solr/amqp_password  password        123dolores
# URL of Chef Server (e.g., http://chef.example.com:4000):
chef  chef/chef_server_url  string  http://chef.lxc.doloreslabs.com:4000
rabbitmq-server             rabbitmq-server/upgrade_previous note
EOF

sudo debconf-set-selections /tmp/selections

# Configure Opscode APT repo and key

echo "deb http://apt.opscode.com/ `lsb_release -cs` main" | sudo tee /etc/apt/sources.list.d/opscode.list
sudo mkdir -p /etc/apt/trusted.gpg.d
gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
gpg --export packages@opscode.com | sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
sudo apt-get update
sudo apt-get install opscode-keyring

# Get updates on essential libraries
yes | sudo apt-get update
yes | sudo apt-get install ruby rubygems ruby-dev libssl-dev libreadline5-dev zlib1g-dev libxml2-dev libcurl4-openssl-dev build-essential git-core
yes | sudo apt-get install chef chef-server

# Configure the CLI knife client
mkdir -p ~/.chef
sudo cp /etc/chef/validation.pem /etc/chef/webui.pem ~/.chef
sudo knife configure --initial -yes --defaults --repository ~/.chef
sudo chown -R ubuntu ~/.chef
'

cat >/tmp/compact_couch <<EOF
###########################
#
# Here's a quick reference for the crontab syntax:  http://adminschoice.com/crontab-quick-reference
#
#  *     *     *   *    *        command to be executed
#  -     -     -   -    -
#  |     |     |   |    |
#  |     |     |   |    +----- day of week (0 - 6) (Sunday=0)
#  |     |     |   +------- month (1 - 12)
#  |     |     +--------- day of month (1 - 31)
#  |     +----------- hour (0 - 23)
#  +------------- min (0 - 59)
#
########

# Compact couch every 3 hours
* */3 * * * curl -H "Content-Type: application/json" -X POST http://localhost:5984/chef/_compact
EOF

sudo crontab /tmp/compact_couch
