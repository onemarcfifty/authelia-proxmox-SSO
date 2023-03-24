#!/bin/bash

# ##########################################################
#
# This script installs Authelia with
# a template configuration like it is
# outlined in this video:
#
# a detailed description is also available
# on https://www.onemarcfifty.com/blog/Authelia_Proxmox/
#
# ##########################################################

# The script needs to be run as root!

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# ####################################
# ##### first we update apt 
# ##### and apt sources, 
# ##### then we install authelia
# ####################################

apt update
apt install -y curl gnupg apt-transport-https sudo
curl -s https://apt.authelia.com/organization/signing.asc | sudo apt-key add -
echo "deb https://apt.authelia.com/stable/debian/debian/ all main" >>/etc/apt/sources.list.d/authelia.list
apt-key export C8E4D80D | sudo gpg --dearmour -o /usr/share/keyrings/authelia.gpg
apt update
apt install -y authelia

# ####################################
# ##### Now we create the secrets 
# ##### and the systemd unit file
# ####################################

for i in .secrets .users .assets .db ; do mkdir /etc/authelia/$i ; done
for i in jwtsecret session storage smtp oidcsecret redis ; do tr -cd '[:alnum:]' < /dev/urandom | fold -w "64" | head -n 1 | tr -d '\n' > /etc/authelia/.secrets/$i ; done
openssl genrsa -out /etc/authelia/.secrets/oicd.pem 4096
openssl rsa -in /etc/authelia/.secrets/oicd.pem -outform PEM -pubout -out /etc/authelia/.secrets/oicd.pub.pem
(cat >/etc/authelia/secrets) <<EOF
AUTHELIA_JWT_SECRET_FILE=/etc/authelia/.secrets/jwtsecret
AUTHELIA_SESSION_SECRET_FILE=/etc/authelia/.secrets/session
AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE=/etc/authelia/.secrets/storage
AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE=/etc/authelia/.secrets/smtp
AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE=/etc/authelia/.secrets/oidcsecret
AUTHELIA_IDENTITY_PROVIDERS_OIDC_ISSUER_PRIVATE_KEY_FILE=/etc/authelia/.secrets/oicd.pem
EOF
chmod 600 -R /etc/authelia/.secrets/
chmod 600 /etc/authelia/secrets
(cat >/etc/systemd/system/authelia.service) <<EOF
[Unit]
Description=Authelia authentication and authorization server
After=multi-user.target

[Service]
Environment=AUTHELIA_SERVER_DISABLE_HEALTHCHECK=true
EnvironmentFile=/etc/authelia/secrets
ExecStart=/usr/bin/authelia --config /etc/authelia/configuration.yml
SyslogIdentifier=authelia

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

# ####################################
# ##### Now we create a user yaml
# ##### file with 4 demo users 
# ##### bob, alice, dave and frank
# ####################################

echo "users:" > /etc/authelia/.users/users_database.yml
for user in bob alice dave frank ; do
  randompassword=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w "64" | head -n 1 | tr -d '\n')
  encryptedpwd=$(authelia hash-password --no-confirm   -- $randompassword  | cut -d " " -f 2)
  ( 
    echo "  ${user}:" 
    echo '    displayname: "First Last"'
    echo "    password: $encryptedpwd"
    echo "    email: ${user}@example.com"
  ) >> /etc/authelia/.users/users_database.yml
done
chmod 600 -R /etc/authelia/.users/

# ####################################
# ##### Next, we pull the skeleton of
# ##### the authelia config file from
# ##### Marc's Github Repo
# ####################################

cd /etc/authelia
# save the old version of the file
if [ -e configuration.yml ] ; then
  mv configuration.yml configuration.yml.old
fi
# Now let's use Marc's version of Florian's Template File for the new config:
wget https://raw.githubusercontent.com/onemarcfifty/cheat-sheets/main/templates/authelia/configuration.yml
chmod 600 configuration.yml

# ##### Now let's try and start Authelia

systemctl enable authelia
systemctl start authelia

# ####################################
# ##### Next we install NGINX
# ##### It will probably not start 
# ##### without valid certificates
# ##### we'll handle this later
# ####################################

# install nginx
apt install -y nginx
# stop NGINX
systemctl stop nginx
# remove the default site
rm /etc/nginx/sites-enabled/*
# download the templates from Marc's cheat sheets
wget https://raw.githubusercontent.com/onemarcfifty/cheat-sheets/main/templates/nginx/authelia/siteconf -O /etc/nginx/sites-available/authelia.conf
wget https://raw.githubusercontent.com/onemarcfifty/cheat-sheets/main/templates/nginx/authelia/proxy-snippet -O /etc/nginx/snippets/proxy.conf
wget https://raw.githubusercontent.com/onemarcfifty/cheat-sheets/main/templates/nginx/authelia/ssl-snippet -O /etc/nginx/snippets/ssl.conf
# link back the authelia site as enabled to NGINX 
ln -s /etc/nginx/sites-available/authelia.conf /etc/nginx/sites-enabled/authelia.conf

