#!/usr/bin/env bash

eval_echo() {
    to_run=$1
    echo "[94m"
    echo $to_run
    echo "[0m"

    eval $to_run
}

echo "[93m"
for entry in $(cat ./.env)
do
  if [[ ! $entry == \#* ]]
  then
    export $entry
    echo "$entry"
  fi
done
echo "[0m"

parameter() {
    file=$1
    before=$2
    value=$3
    after=$4
    if [ "x$after" = "x" ]; then
        eol="\$"
    fi
    eval_echo "sed -i 's,\($before\).*$after$eol,\1$value$after,' $file"
    cat $file | grep "$before"
}

parameter ./config/nginx/domain.conf "server_name " $SERVER_IP ";"

if [ "x$DOMAIN" = "xfalse" ]; then
    SERVER_DOMAIN=$SERVER_IP
fi

parameter ./config/nginx/domain.conf "return 301 https\?://" $SERVER_DOMAIN "\\$"

parameter ./config/nginx/codenjoy-balancer.conf "server_name " $SERVER_DOMAIN ";"
parameter ./config/nginx/codenjoy-contest.conf "server_name " $SERVER_DOMAIN ";"
parameter ./config/nginx/wordpress.conf "server_name " $SERVER_DOMAIN ";"

comment() {
    file=$1
    marker=$2
    flag=$3
    if [ "x$flag" = "xtrue" ]; then
        eval_echo "sed -i '/$marker/s/^#\+//' $file"
    else
        eval_echo "sed -i '/$marker/s/^#\?/#/' $file"
    fi
    cat $file | grep $marker
}

ports() {
    file=$1
    comment $file "#P#" $OPEN_PORTS
}

ports ./docker-compose.yml
ports ./codenjoy.yml
ports ./balancer.yml

basic_auth() {
    file=$1
    comment $file "#A#" $BASIC_AUTH
}

basic_auth ./config/nginx/codenjoy-balancer.conf
basic_auth ./config/nginx/codenjoy-contest.conf

ssl() {
    file=$1
    comment $file "#S#" $SSL
    if [ "x$SSL" = "xtrue" ]; then
        NOT_SSL="false";
    else
        NOT_SSL="true";
    fi
    comment $file "#!S#" $NOT_SSL
}

ssl ./config/nginx/domain.conf
ssl ./config/nginx/codenjoy-balancer.conf
ssl ./config/nginx/codenjoy-contest.conf
ssl ./docker-compose.yml

parameter ./config/codenjoy/codenjoy-balancer.properties "database.name=" $CODENJOY_POSTGRES_NAME
parameter ./config/codenjoy/codenjoy-balancer.properties "database.user=" $CODENJOY_POSTGRES_USER
parameter ./config/codenjoy/codenjoy-balancer.properties "database.password=" $CODENJOY_POSTGRES_PASSWORD
parameter ./config/codenjoy/codenjoy-balancer.properties "admin.password=" $ADMIN_PASSWORD
parameter ./config/codenjoy/codenjoy-balancer.properties "email.hash=" $EMAIL_HASH
parameter ./config/codenjoy/codenjoy-balancer.properties "game.type=" $GAME
parameter ./config/codenjoy/codenjoy-balancer.properties "game.servers=" $GAME_SERVERS

parameter ./config/codenjoy/codenjoy-contest.properties "database.name=" $CODENJOY_POSTGRES_NAME
parameter ./config/codenjoy/codenjoy-contest.properties "database.user=" $CODENJOY_POSTGRES_USER
parameter ./config/codenjoy/codenjoy-contest.properties "database.password=" $CODENJOY_POSTGRES_PASSWORD
parameter ./config/codenjoy/codenjoy-contest.properties "admin.password=" $ADMIN_PASSWORD
parameter ./config/codenjoy/codenjoy-contest.properties "email.hash=" $EMAIL_HASH
parameter ./config/codenjoy/codenjoy-contest.properties "server.ip=" $SERVER_IP

database() {
    file=$1
    if [ "x$DATABASE_TYPE" = "xpostgre" ]; then
        POSTGRE="true";
        SQLITE="false";
    else
        POSTGRE="false";
        SQLITE="true";
    fi
    comment $file "#L#" $SQLITE
    comment $file "#!L#" $POSTGRE
    if [ "x$POSTGRE" = "xtrue" ] && [ "x$OPEN_PORTS" = "xtrue" ]; then
        comment $file "#!LP#" "true"
    else
        comment $file "#!LP#" "false"
    fi
}

database ./docker-compose.yml
database ./balancer.yml
database ./codenjoy.yml

domain() {
    file=$1
    comment $file "#D#" $DOMAIN
}

domain ./config/nginx/nginx.conf
domain ./config/nginx/codenjoy-balancer.conf
domain ./config/nginx/codenjoy-contest.conf