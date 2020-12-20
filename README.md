# epicgames-freegames-node on Heroku for Free!
Deploy [epicgames-freegames-node](https://github.com/claabs/epicgames-freegames-node) in Heroku for free via Github1

![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/davidjameshowell/epicgames-freegames-heroku/EpicGamesFreeGamesDeploy/main?label=Deploy%20EpicGames-FreeGames-Node&style=for-the-badge)

![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/davidjameshowell/epicgames-freegames-heroku/EpicGamesFreeGamesRun/main?label=Run%20EpicGames-FreeGames-Node&style=for-the-badge)

![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/davidjameshowell/epicgames-freegames-heroku/EpicGamesFreeGamesUpdate/main?label=Update%20EpicGames-FreeGames-Node&style=for-the-badge)

![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/davidjameshowell/epicgames-freegames-heroku/EpicGamesFreeGamesResetCookie/main?label=Reset%20cookie%20EpicGames-FreeGames-Node&style=for-the-badge)

[![CodeFactor](https://www.codefactor.io/repository/github/davidjameshowell/epicgames-freegames-heroku/badge)](https://www.codefactor.io/repository/github/davidjameshowell/epicgames-freegames-heroku)

## Features
* Build and deploy cutomized EpicGames-FreeGames-node image from source to Heroku via Github Actions
* Presistent Login Cookie stored via Redis
* Reset stuck cookie via Github Actions
* Maintanable updates with Git Hash for future updates
* Easily extendable for future tweaks

## Usage

Usage is simply, fast, and user friendly! The application will run each hour after being deployed!

### Deployment

1. Create a fork of this project
2. Go to your forked repo Settings > Secrets and add secrets for:
  * HEROKU_EMAIL (the email you used to sign up for Heroku)
  * HEROKU_API_KEY (yoru Heroku API key - can be found in **[Account Setings](https://dashboard.heroku.com/account)** -> APi Keys)
  * APP_NAME (the name of the Heroku application, this must be unqiue across Heroku and will fail if it is not)
  * EMAIL_ADDRESS (your Epic Games email address)
  * EPIC_GAMES_PASSWORD (your Epic Games password)
  * TEMPORARY_EMAIL_COOKIE (a base64 encoded starting cookie, please see temporary cookie generation below)
4. Navigate to Github Actions and run the job EpicGamesFreeGamesDeploy workflow and begin deploying the app. This will take around 5-8 minutes.
5. Congrats, you now having a fully functional EpicGames-FreeGames-node instance in Heroku!
 
### Temporary Cookie Generation and Reset Mechanism

You should be following the instructions listed [here](https://github.com/claabs/epicgames-freegames-node#cookie-import) up to and including step 4.

You will then take this cookie and [base64 encode it, suggested site attached](https://www.base64encode.org/). Then add this in as a secret in your Github forked repo.

Should you have any issues with your token in running the application, you can reset the token by doing the steps above and then running the EpicGamesFreeGamesResetCookie Github Actions workflow.
 
### Update

Updating is simple and can be done one of two ways:
* Running the workflow manually via Github Actions
* Making a commit to the main branch, forcing a Github Actions workflow to initiate an update workflow
 
Either one of these will force the Github Actions workflow to run and update the app. If you need to modify to enable/disable settings, you should re-run it as well.

# Notes to consider

Currently this was tested with both 2FA disabled and enabled, but it appears as long as you have the cookies refreshed periodically, it does not prompt for 2FA. It may be the current games offered do not currently require 2FA.

The other concern is around the captcha support. The application is setup for captcha email support, but requires additional configuration with Mailgun to add your email address as an approved sender (due to sandboxed mode).