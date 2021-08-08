# epicgames-freegames-node on Heroku for Free!
Deploy [epicgames-freegames-node](https://github.com/claabs/epicgames-freegames-node) in Heroku for free via Github!

![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/davidjameshowell/epicgames-freegames-heroku/EpicGamesFreeGamesDeploy/main?label=Deploy%20EpicGames-FreeGames-Node&style=for-the-badge)

![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/davidjameshowell/epicgames-freegames-heroku/EpicGamesFreeGamesRun/main?label=Run%20EpicGames-FreeGames-Node&style=for-the-badge)

![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/davidjameshowell/epicgames-freegames-heroku/EpicGamesFreeGamesUpdate/main?label=Update%20EpicGames-FreeGames-Node&style=for-the-badge)

![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/davidjameshowell/epicgames-freegames-heroku/EpicGamesFreeGamesResetCookie/main?label=Reset%20cookie%20EpicGames-FreeGames-Node&style=for-the-badge)

[![CodeFactor](https://www.codefactor.io/repository/github/davidjameshowell/epicgames-freegames-heroku/badge)](https://www.codefactor.io/repository/github/davidjameshowell/epicgames-freegames-heroku)

## Features
* Build and deploy customized EpicGames-FreeGames-node image from source to Heroku via Github Actions
* Persistent Login Cookie stored via Redis
* Reset stuck cookie via Github Actions
* Maintainable updates with Git Hash for future updates
* Easily extendable for future tweaks

## Usage

Usage is simply, fast, and user friendly! The application will run each hour after being deployed!

### Deployment

1. Create a fork of this project
2. Go to your forked repo Settings > Secrets and add secrets for:
  * HEROKU_API_KEY (your Heroku API key - can be found in **[Account Settings](https://dashboard.heroku.com/account)** -> API Keys)
  * APP_NAME (the name of the Heroku application, this must be unique across Heroku and will fail if it is not)
  * EMAIL_ADDRESS (your Epic Games email address)
  * EPIC_GAMES_PASSWORD (your Epic Games password)
  * TEMPORARY_EMAIL_COOKIE (a base64 encoded starting cookie, please see temporary cookie generation below)
  * TOTP_MFA (your Epic Games MFA string, not your MFA code, but the string used to generate the code)
4. Navigate to Github Actions and run the job EpicGamesFreeGamesDeploy workflow and begin deploying the app. This will take around 5-8 minutes.
5. Congrats, you now having a fully functional EpicGames-FreeGames-node instance in Heroku!

### Update

Updating is simple and can be done one of two ways:
* Running the workflow manually via Github Actions
* Making a commit to the main branch, forcing a Github Actions workflow to initiate an update workflow
 
Either one of these will force the Github Actions workflow to run and update the app. If you need to modify to enable/disable settings, you should re-run it as well.
 
### Temporary Cookie Generation and Reset Mechanism

You should be following the instructions listed [here](https://github.com/claabs/epicgames-freegames-node#cookie-import) up to and including step 4.

You will then take this cookie and [base64 encode it, suggested site attached](https://www.base64encode.org/). Then add this in as a secret in your Github forked repo.

Should you have any issues with your token in running the application, you can reset the token by doing the steps above and then running the EpicGamesFreeGamesResetCookie Github Actions workflow.

### Email CAPTCHA Support

Email captchas are supported with this mechanism and are supported by Mailgun. We are using Mailgun's sandboxed mode which requires you to manually verify your domain in order to prevent the service from being used as spam.

In order to verify your email address (the variable used for EMAIL_ADDRESS):
1. Go to your app dashboard in Heroku, find the Mailgun addon.
2. Click on the Mailgun addon to get SSO redirected to Mailgun dashboard.
3. Then find the "Sending" tab in Mailgun.
4. Click on the default domain (sandbox).
5. On the right hand side, you will see a field entitled "Authorized Recipients".
6. Enter your email address and Save Recipient.
7. Wait for an email to arrive - **THIS EMAIL WILL MOST LIKELY LAND IN YOUR SPAM BOX**.
8. Click the click in the email and then Yes on the webpage that is presented.
9. Captcha emails will now be delivered to your email, again **PLEASE CHECK IN YOUR SPAM FOLDER WHEN OUTPUT SPECIFIES CAPTCHA IS NEEDED**.

### Notes to consider
If you enable MFA on your Heroku account after deploying this process, you will need to regenerate the API key and update it within the Github secrets.
