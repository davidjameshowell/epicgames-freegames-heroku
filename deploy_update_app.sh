#!/bin/bash 
set -euo pipefail

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
APP_NAME=" "
GIT_HASH="master"
EPICGAMES_FREEGAMES_FOLDER="epicgames-freegames-node"
STRATEGY_TYPE="deploy"

# Clean out any existing contents
rm -rf ./${EPICGAMES_FREEGAMES_FOLDER}

function git_clone {
    GIT_HASH=$1
    printf "Clone current epicgames-freegames-node with depth 1\n"
    git clone --depth 1 https://github.com/claabs/epicgames-freegames-node.git
    cd ./${EPICGAMES_FREEGAMES_FOLDER}
    git checkout "${GIT_HASH}"
    cd ..
}

function sed_files {
    sed -i "$1" "$2"
}

function heroku_envar_bootstrap {
    printf "Now we will configure all the required SMTP settings as well as email address\n"
    printf "Supressing output due to sensitive nature.\n"
    heroku config:set SMTP_HOST="$(heroku config:get MAILGUN_SMTP_SERVER -a "${APP_NAME}")" -a "${APP_NAME}" > /dev/null
    heroku config:set SMTP_PORT="465" -a "${APP_NAME}" > /dev/null
    heroku config:set SMTP_SECURE="true" -a "${APP_NAME}" > /dev/null
    heroku config:set EMAIL_SENDER_ADDRESS="$(heroku config:get MAILGUN_SMTP_LOGIN -a "${APP_NAME}")" -a "${APP_NAME}" > /dev/null
    heroku config:set EMAIL_SENDER_NAME="[${APP_NAME}] Epic Games Free Captcha" -a "${APP_NAME}" > /dev/null
    heroku config:set EMAIL_RECIPIENT_ADDRESS="${EMAIL_ADDRESS}" -a "${APP_NAME}" > /dev/null
    #heroku config:set SMTP_USERNAME="$(heroku config:get MAILGUN_SMTP_LOGIN -a "${APP_NAME}")" -a "${APP_NAME}" > /dev/null
    #heroku config:set SMTP_PASSWORD="$(heroku config:get MAILGUN_SMTP_PASSWORD -a "${APP_NAME}")" -a "${APP_NAME}" > /dev/null
    heroku config:set EMAIL="${EMAIL_ADDRESS}" -a "${APP_NAME}" > /dev/null
    heroku config:set PASSWORD="${EPIC_GAMES_PASSWORD}" -a "${APP_NAME}" > /dev/null
    heroku config:set BASE_URL="https://${APP_NAME}.herokuapp.com/" -a "${APP_NAME}" > /dev/null
    heroku config:set PUPPETEER_PURCHASE="true" -a "${APP_NAME}"
    
    
    if [ ! -z "${TOTP_MFA}" ]
    then
        printf "Also adding in MFA OTP code to be solved.\n"
        printf "Supressing output due to sensitive nature.\n"
        heroku config:set TOTP="${TOTP_MFA}" -a "${APP_NAME}" > /dev/null
    fi

    if [ ! -z "${HCAPTCHA_ACCESSIBILITY_URL}" ]
    then
        printf "Also adding in HCAPTCHA Accessibility URL for better success.\n"
        printf "Supressing output due to sensitive nature.\n"
        heroku config:set HCAPTCHA_ACCESSIBILITY_URL="${HCAPTCHA_ACCESSIBILITY_URL}" -a "${APP_NAME}" > /dev/null
    fi


    if  [ -n "${APP_CONFIG}" ]
    then
        printf "Add app config to Redis.\n"
        redis-cli -u "$(heroku config:get REDISTOGO_URL -a "${APP_NAME}")" set APP_CONFIG "${APP_CONFIG}" > /dev/null
        heroku config:set APP_CONFIG="${APP_CONFIG}" -a "${APP_NAME}" > /dev/null
    fi

    printf "Set run once parameters.\n"
    heroku config:set RUN_ON_STARTUP="true" -a "${APP_NAME}"
    heroku config:set RUN_ONCE="true" -a "${APP_NAME}"
}

function heroku_bootstrap {

    APP_NAME=$1

    printf "Logging into Heroku Container Registry to push the image (this will add an entry in your Docker config, if running locally)\n"
    heroku container:login

    printf "We must create a Heroku application to deploy to first.\n"
    APP_NAME=$(heroku create "${APP_NAME}" --json | jq --raw-output '.name')

    printf "We will use MailGun Starter edition, which is free and sufficient for our SMTP purposes.\n"
    heroku addons:create mailgun:starter -a "$APP_NAME"
    
    printf "We will use RedisToGo Nano edition, which is free and sufficient for our cookie purposes.\n"
    heroku addons:create redistogo:nano -a "$APP_NAME"
    
    heroku_envar_bootstrap
    
    if  [ -n "${TEMPORARY_EMAIL_COOKIE}" ]
    then
        printf "Add in initial cookie configuration for Redis if configured, supress output.\n"
        redis-cli -u "$(heroku config:get REDISTOGO_URL -a "${APP_NAME}")" set EMAIL_COOKIE "${TEMPORARY_EMAIL_COOKIE}" > /dev/null
    fi
}

function build_image {
    git_clone "${GIT_HASH}"

    cd "${SCRIPTPATH}"
    printf "Logging into Heroku Container Registry to push the image (this will add an entry in your Docker config)\n"
    heroku container:login

    printf "Now we will build the image to deploy to Heroku with the specified port changes\n"
    cd ./${EPICGAMES_FREEGAMES_FOLDER}
    
    printf "Heroku uses random ports for assignment with httpd services. We are modifying the SERVER_PORT in entrypoint for startup.\n"
    printf "We are additionally adding logic to capture and set the Email Cookie for continued runs.\n"
    sed_files '2 a export SERVER_PORT=\$PORT\n' ./entrypoint.sh
    #sed_files '3 a if ! [ -z $(redis-cli -u \$REDISTOGO_URL get EMAIL_COOKIE) ]; then mkdir -p /usr/app/config && touch /usr/app/config/'${EMAIL_ADDRESS}'-cookies.json && redis-cli -u \$REDISTOGO_URL get EMAIL_COOKIE | base64 -d > /usr/app/config/'${EMAIL_ADDRESS}'-cookies.json; fi' ./entrypoint.sh
    #sed_files '4 a if ! [ -z $(redis-cli -u \$REDISTOGO_URL get APP_CONFIG) ]; then echo "Adding App Config from redis url \${REDISTOGO_URL}" && mkdir -p /usr/app/config && touch /usr/app/config/config.json && redis-cli -u \$REDISTOGO_URL get APP_CONFIG | base64 -d > /usr/app/config/config.json; fi' ./entrypoint.sh
    #sed_files '$a if [ -s /usr/app/config/'${EMAIL_ADDRESS}'-cookies.json ]; then echo $(cat /usr/app/config/'${EMAIL_ADDRESS}'-cookies.json | base64) | redis-cli -u \$REDISTOGO_URL -x set EMAIL_COOKIE; fi' ./entrypoint.sh
    sed_files '3 a if ! [ -z ${APP_CONFIG} ]; then echo "Adding App Config from env var" && mkdir -p /usr/app/config && touch /usr/app/config/config.json && echo ${APP_CONFIG} | base64 -d > /usr/app/config/config.json; fi' ./entrypoint.sh


    # Dockerfile manipulation to install redis
    sed_files 's/RUN npm ci \-\-only\=production/RUN npm ci \-\-only\=production \&\& apk add redis \-\-no\-cache/g' ./Dockerfile
    
    cat ./entrypoint.sh

    heroku container:push web -a "${APP_NAME}"

    printf "Now we can release the app which will publish it.\n"
    heroku container:release web -a "${APP_NAME}"
}

function help {
    printf "Welcome to help!\Use option -a for app name,\n -g to set a git hash to clone epicgames-freegames-node from,\n and -t to specify if deployment, run, or update,\n and -o for TOTP MFA string."
}

while getopts a:g:t:o: flag
do
    case "${flag}" in
        a) APP_NAME=${OPTARG};;
        g) GIT_HASH=${OPTARG};;
        t) STRATEGY_TYPE=${OPTARG};;
        o) TOTP_MFA=${OPTARG};;
        *) HELP;;
    esac
done

printf "App_Name: %s\n" "$APP_NAME";
printf "Git Hash: %s\n" "$GIT_HASH";

if [[ ${STRATEGY_TYPE} = "deploy" ]]
then
    printf "Run Heroku bootstrapping for app and Dyno creations.\n"
    heroku_bootstrap "${APP_NAME}"
    build_image
    printf "Congrats! Your new EpicGames FreeGames instance is ready to use! Since we are using Github actions, we can make sure we restart this process daily!\n"
elif [[ ${STRATEGY_TYPE} = "run" ]]
then
    heroku restart -a "${APP_NAME}"
    printf "Check the logs in Heroku, as they may contain sensitive details we don't want to print here!\n"
    exit 0
elif [[ ${STRATEGY_TYPE} = "cookie" ]]
then
    redis-cli -u "$(heroku config:get REDISTOGO_URL -a "${APP_NAME}")" set EMAIL_COOKIE "${TEMPORARY_EMAIL_COOKIE}" > /dev/null
    exit 0
else
    # Update
    heroku_envar_bootstrap
    build_image
    printf "Congrats! Your new EpicGames FreeGames instance is ready to use! Since we are using Github actions, we can make sure we restart this process hourly!\n"
fi
