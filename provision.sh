#!/bin/sh

set -e

if [ `whoami` = "root" ]; then
    echo 'You are root'
    exit 1
fi

REPO_URL="https://crashcube@bitbucket.org/crashcube/smqu-client.git"
INSTALL_PATH="$HOME/smqdrv"

sudo apt-get update
sudo apt-get install -y curl git build-essential vim

# nodejs
if [ ! -f /usr/local/bin/node ]; then
    sudo wget https://nodejs.org/dist/v10.15.0/node-v10.15.0-linux-armv6l.tar.xz -O /tmp/node.tar.xz
    sudo tar --strip-components 1 -xf /tmp/node.tar.xz -C /usr/local
    sudo rm /tmp/node.tar.gz
fi

# repo
mkdir -p "$HOME/.ssh"
ssh-keyscan -t rsa bitbucket.org > "$HOME/.ssh/known_hosts"
test -d "$INSTALL_PATH/.git" || git clone $REPO_URL $INSTALL_PATH
cd $INSTALL_PATH && git fetch origin && git reset --hard origin/master

# install driver
cp -n .env.sample .env
npm install

# run service
cat <<EOT > /etc/systemd/system/smqu-client.service
[Unit]
Description=PM2 process manager
Documentation=https://pm2.keymetrics.io/
After=network.target

[Service]
Type=forking
User=pi
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Environment=PATH=/usr/local/bin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
Environment=PM2_HOME=/home/pi/.pm2
PIDFile=/home/pi/.pm2/pm2.pid

ExecStart=/usr/local/lib/node_modules/pm2/bin/pm2 resurrect
ExecReload=/usr/local/lib/node_modules/pm2/bin/pm2 reload all
ExecStop=/usr/local/lib/node_modules/pm2/bin/pm2 kill

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl daemon-reload
sudo systemctl enable smqu-client.service
sudo systemctl restart smqu-client.service

echo "Done!"
