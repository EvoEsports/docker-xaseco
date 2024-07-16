#!/bin/bash

set -e

# Set xaseco operation mode, defaults to TM Forever
if [ "$2" = '/xaseco/aseco.php' ]; then
    set -- "$@" "${XASECO_MODE:-TMF}"
fi

# Extract xaseco into the volume. We sadly have to put the whole xaseco installation into the volume because of the crappy placement of the config files not allowing them being put in their own volume.
tar xf /tmp/xaseco.tar.gz -C /xaseco

# copy newinstall content if the files don't exist yet
[ ! -f /xaseco/access.xml  ] && cp /xaseco/newinstall/access.xml /xaseco/access.xml
[ ! -f /xaseco/adminops.xml ] && cp /xaseco/newinstall/adminops.xml /xaseco/adminops.xml
[ ! -f /xaseco/autotime.xml ] && cp /xaseco/newinstall/autotime.xml /xaseco/autotime.xml
[ ! -f /xaseco/bannedips.xml ] && cp /xaseco/newinstall/bannedips.xml /xaseco/bannedips.xml
[ ! -f /xaseco/config.xml ] && cp /xaseco/newinstall/config.xml /xaseco/config.xml
[ ! -f /xaseco/dedimania.xml ] && cp /xaseco/newinstall/dedimania.xml /xaseco/dedimania.xml
[ ! -f /xaseco/localdatabase.xml ] && cp /xaseco/newinstall/localdatabase.xml /xaseco/localdatabase.xml
[ ! -f /xaseco/matchsave.xml ] && cp /xaseco/newinstall/matchsave.xml /xaseco/matchsave.xml
[ ! -f /xaseco/plugins.xml ] && cp /xaseco/newinstall/plugins.xml /xaseco/plugins.xml
[ ! -f /xaseco/rasp.xml ] && cp /xaseco/newinstall/rasp.xml /xaseco/rasp.xml

[ ! -f /xaseco/includes/jfreu.config.php ] && cp /xaseco/newinstall/jfreu.config.php /xaseco/includes/jfreu.config.php
[ ! -f /xaseco/includes/rasp.settings.php ] && cp /xaseco/newinstall/rasp.settings.php /xaseco/includes/rasp.settings.php
[ ! -f /xaseco/includes/votes.config.php ] && cp /xaseco/newinstall/votes.config.php /xaseco/includes/votes.config.php

# config.xml
config=()
if [ "$XASECO_TMSERVER_LOGIN" ]; then config+=("/<tmserver>/,/<\/tmserver>/s|<login>.*</login>|<login>${XASECO_TMSERVER_LOGIN:-SuperAdmin}</login>|"); else echo "[!] TM server login not set! Use XASECO_TMSERVER_LOGIN to set it."; exit 1; fi
if [ "$XASECO_TMSERVER_PASSWORD" ]; then config+=("/<tmserver>/,/<\/tmserver>/s|<password>.*</password>|<password>${XASECO_TMSERVER_PASSWORD:-SuperAdmin}</password>|"); else echo "[!] TM server password not set! Use XASECO_TMSERVER_PASSWORD to set it."; exit 1; fi
if [ "$XASECO_TMSERVER_IP" ]; then config+=("/<tmserver>/,/<\/tmserver>/s|<ip>.*</ip>|<ip>${XASECO_TMSERVER_IP}</ip>|"); else echo "[!] TM server ip not set! Use XASECO_TMSERVER_IP to set it."; exit 1; fi
if [ "$XASECO_TMSERVER_PORT" ]; then config+=("/<tmserver>/,/<\/tmserver>/s|<port>.*</port>|<port>${XASECO_TMSERVER_PORT}</port>|"); else echo "[!] TM server port not set! Use XASECO_TMSERVER_PORT to set it."; exit 1; fi

for (( i = 0; i < ${#config[@]}; i++ )); do
        eval sed -i "'${config[$i]}'" /xaseco/config.xml
done

# localdatabase.xml
localdatabase=()
if [ "$XASECO_MYSQL_SERVER" ]; then localdatabase+=("/<settings>/,/<\/settings>/s|<mysql_server>.*</mysql_server>|<mysql_server>${XASECO_MYSQL_SERVER}</mysql_server>|"); else echo "[!] MySQL server ip not set! Use XASECO_MYSQL_SERVER to set it."; exit 1; fi
if [ "$XASECO_MYSQL_LOGIN" ]; then localdatabase+=("/<settings>/,/<\/settings>/s|<mysql_login>.*</mysql_login>|<mysql_login>${XASECO_MYSQL_LOGIN}</mysql_login>|"); else echo "[!] MySQL login not set! Use XASECO_MYSQL_LOGIN to set it."; exit 1; fi
if [ "$XASECO_MYSQL_PASSWORD" ]; then localdatabase+=("/<settings>/,/<\/settings>/s|<mysql_password>.*</mysql_password>|<mysql_password>${XASECO_MYSQL_PASSWORD}</mysql_password>|"); else echo "[!] MySQL password not set! Use XASECO_MYSQL_PASSWORD to set it."; exit 1; fi
if [ "$XASECO_MYSQL_DATABASE" ]; then localdatabase+=("/<settings>/,/<\/settings>/s|<mysql_database>.*</mysql_database>|<mysql_database>${XASECO_MYSQL_DATABASE}</mysql_database>|"); else echo "[!] MySQL database not set! Use XASECO_MYSQL_DATABASE to set it."; exit 1; fi

for (( i = 0; i < ${#localdatabase[@]}; i++ )); do
        eval sed -i "'${localdatabase[$i]}'" /xaseco/localdatabase.xml
done

# dedimania.xml
dedimania=()
if [ "$XASECO_DEDIMANIA_LOGIN" ]; then dedimania+=("/<masterserver_account>/,/<\/masterserver_account>/s|<login>.*</login>|<login>${XASECO_DEDIMANIA_LOGIN}</login>|"); else echo "[!] Dedimania login not set! Use XASECO_DEDIMANIA_LOGIN to set it."; exit 1; fi
if [ "$XASECO_DEDIMANIA_PASSWORD" ]; then dedimania+=("/<masterserver_account>/,/<\/masterserver_account>/s|<password>.*</password>|<password>${XASECO_DEDIMANIA_PASSWORD}</password>|"); else echo "[!] Dedimania password not set! Use XASECO_DEDIMANIA_PASSWORD to set it."; exit 1; fi
if [ "$XASECO_DEDIMANIA_NATION" ]; then dedimania+=("/<masterserver_account>/,/<\/masterserver_account>/s|<nation>.*</nation>|<nation>${XASECO_DEDIMANIA_NATION:-OTH}</nation>|"); else echo "[!] Dedimania nation not set! Use XASECO_DEDIMANIA_NATION to set it."; exit 1; fi

for (( i = 0; i < ${#dedimania[@]}; i++ )); do
        eval sed -i "'${dedimania[$i]}'" /xaseco/dedimania.xml
done

# Set masteradmins
for i in ${XASECO_MASTERADMINS//,/ }; do
    if ! grep -q "<tmlogin>$i</tmlogin>" /xaseco/config.xml; then
        sed -i "/<masteradmins>/ a\      <tmlogin>$i</tmlogin>" /xaseco/config.xml
    fi
done

# Launch XASECO
exec "$@"