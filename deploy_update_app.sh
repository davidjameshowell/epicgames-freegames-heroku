#!/bin/bash 
set -euo pipefail

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
APP_NAME=" "
GIT_HASH="master"
EPICGAMES_FREEGAMES_FOLDER="epicgames-freegames-node"
STRATEGY_TYPE="deploy"

# Clean out any existing contents
rm -rf ./epicgames-freegames-node

function git_clone {
    GIT_HASH=$1
    printf "Clone current bitwarden_rs with depth 1"
    git clone --depth 1 https://github.com/claabs/epicgames-freegames-node.git
    cd ./${EPICGAMES_FREEGAMES_FOLDER}
    git checkout "${GIT_HASH}"
    cd ..
}

function sed_files {
    sed -i "$1" "$2"
}

function heroku_bootstrap {

    APP_NAME=$1

    printf "Logging into Heroku Container Registry to push the image (this will add an entry in your Docker config, if running locally)"
    heroku container:login

    printf "We must create a Heroku application to deploy to first."
    APP_NAME=$(heroku create "${APP_NAME}" --json | jq --raw-output '.name')

    printf "We will use MailGun Starter edition, which is free and sufficient for our SMTP purposes"
    heroku addons:create mailgun:starter -a "$APP_NAME"
    
    printf "We will use RedisToGo Nano edition, which is free and sufficient for our cookie purposes"
    heroku addons:create redistogo:nano -a "$APP_NAME"

    printf "Now we will configure all the required SMTP settings as well as email address "
    printf "Supressing output due to sensitive nature."
    heroku config:set SMTP_HOST="$(heroku config:get MAILGUN_SMTP_SERVER -a "${APP_NAME}")" -a "${APP_NAME}" > /dev/null
    heroku config:set SMTP_PORT="$(heroku config:get MAILGUN_SMTP_PORT -a "${APP_NAME}")" -a "${APP_NAME}" > /dev/null
    heroku config:set EMAIL_SENDER_ADDRESS="$(heroku config:get MAILGUN_SMTP_LOGIN -a "${APP_NAME}")" -a "${APP_NAME}" > /dev/null
    heroku config:set EMAIL_SENDER_NAME="[${APP_NAME}] Epic Games Free Captcha" -a "${APP_NAME}" > /dev/null
    heroku config:set EMAIL_RECIPIENT_ADDRESS="${EMAIL_ADDRESS:-$HEROKU_EMAIL}" -a "${APP_NAME}" > /dev/null
    heroku config:set SMTP_SECURE="false" -a "${APP_NAME}" > /dev/null
    heroku config:set SMTP_USERNAME="$(heroku config:get MAILGUN_SMTP_LOGIN -a "${APP_NAME}")" -a "${APP_NAME}" > /dev/null
    heroku config:set SMTP_PASSWORD="$(heroku config:get MAILGUN_SMTP_PASSWORD -a "${APP_NAME}")" -a "${APP_NAME}" > /dev/null
    heroku config:set EMAIL="${EMAIL_ADDRESS}" -a "${APP_NAME}" > /dev/null
    heroku config:set PASSWORD="${EPIC_GAMES_PASSWORD}" -a "${APP_NAME}" > /dev/null
    heroku config:set BASE_URL="${APP_NAME}.herokuapp.com" -a "${APP_NAME}" > /dev/null

    printf "Set run once parameters."
    heroku config:set RUN_ON_STARTUP="true" -a "${APP_NAME}"
    heroku config:set RUN_ONCE="true" -a "${APP_NAME}"
    
    printf "Add in initial cookie configuration for Redis, supress output"
    echo ${TEMPORARY_EMAIL_COOKIE} | redis-cli -u $(heroku config:get REDISTOGO_URL -a "${APP_NAME}") set -x EMAIL_COOKIE > /dev/null
}

function build_image {
    printf "Logging into Heroku Container Registry to push the image (this will add an entry in your Docker config)"
    heroku container:login

    printf "Now we will build the image to deploy to Heroku with the specified port changes"
    cd ./${EPICGAMES_FREEGAMES_FOLDER}
    heroku container:push web -a "${APP_NAME}"

    printf "Now we can release the app which will publish it"
    heroku container:release web -a "${APP_NAME}"
}

function help {
    printf "Welcome to help!\Use option -a for app name,\n -g to set a git hash to clone epicgames-freegames-node from,\n and -t to specify if deployment, run, or update!"
}

while getopts a:g:t: flag
do
    case "${flag}" in
        a) APP_NAME=${OPTARG};;
        g) GIT_HASH=${OPTARG};;
        t) STRATEGY_TYPE=${OPTARG};;
        *) HELP;;
    esac
done

function login_heroku {
printf "Modify netrc file to include Heroku details"
cat >~/.netrc <<EOF
machine api.heroku.com
    login ${HEROKU_EMAIL}
    password ${HEROKU_API_KEY}
machine git.heroku.com
    login ${HEROKU_EMAIL}
    password ${HEROKU_API_KEY}
EOF
}

login_heroku
printf "App_Name: $APP_NAME";
printf "Git Hash: $GIT_HASH";

git_clone "${GIT_HASH}"

cd "${SCRIPTPATH}"

printf "Heroku uses random ports for assignment with httpd services. We are modifying the SERVER_PORT in entrypoint for startup."

sed_files '2 a export SERVER_PORT=\$PORT\n' ./${EPICGAMES_FREEGAMES_FOLDER}/entrypoint.sh
sed_files '3 a touch /usr/app/config/'${EMAIL_ADDRESS}'-cookies.json' ./${EPICGAMES_FREEGAMES_FOLDER}/entrypoint.sh
sed_files '4 a redis-cli -u \$REDISTOGO_URL get EMAIL_COOKIE | base64 -d > /usr/app/config/'${EMAIL_ADDRESS}'-cookies.json' ./${EPICGAMES_FREEGAMES_FOLDER}/entrypoint.sh
sed_files '$a echo $(cat /usr/app/config/'${EMAIL_ADDRESS}'-cookies.json | base64) | redis-cli -u \$REDISTOGO_URL set -x EMAIL_COOKIE' ./${EPICGAMES_FREEGAMES_FOLDER}/entrypoint.sh

# Dockerfile manipulation to install redis
sed_files 's/jq tzdata/jq tzdata redis/g' ./${EPICGAMES_FREEGAMES_FOLDER}/Dockerfile

if [[ ${STRATEGY_TYPE} = "deploy" ]]
then
    printf "Run Heroku bootstrapping for app and Dyno creations."
    heroku_bootstrap "${APP_NAME}"
elif [[ ${STRATEGY_TYPE} = "run" ]]
then
    login_heroku
    heroku restart -a ${APP_NAME}
    printf "Check the logs in Heroku, as they may contain sensitive details we don't want to print here!"
    exit 0
else
    APP_NAME=${APP_NAME}
fi

build_image
printf "Congrats! Your new EpicGames FreeGames instance is ready to use! Since we are using Github actions, we can make sure we restart this process daily!"
