# Contributing

Sharecuts is written in Swift and it uses the [Vapor](https://vapor.codes) framework.

## Production stack

The app is hosted on a Mac Mini in [MacStadium](https://macstadium.com), running macOS High Sierra. It uses PostgreSQL as its database and [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html) to store the shortcuts files.

In production, the app listens on a local port and is started by a launch daemon, to expose the app to the internet, Nginx is used as a proxy. All access to the website and API goes through [CloudFlare](https://cloudflare.com) which is used as a DNS provider, cache, CDN and to protect the app from abuse.

## Setting up the environment

Building and running Sharecuts locally requires the following environment:

- macOS High Sierra
- Xcode 9 or 10
- Swift 4.1.2 (I recommend using [SwiftEnv](https://github.com/kylef/swiftenv))
- [B2 command line tool](https://www.backblaze.com/b2/docs/quick_command_line.html)
- PostgreSQL (I recommend using [Postgres.app](http://postgresapp.com))

## Environment variables

A `.env` file should be placed in the app's working directory to configure some aspects of the app, here's a brief explanation of the environment variables:

`DB_HOST`: The Postgres database host (required)

`DB_PORT`: The Postgres database port (required)

`DB_USER`: The Postgres user name (required)

`DB_NAME`: The Postgres database name (required)

`DB_PWD`: The Postgres password (optional, default is empty in development)

`MASTER_KEY`: The master API key that can be used to perform administrative tasks such as creating new users (optional, there's a default key for development that can be found in `configure.swift`)

`B2_BUCKET_NAME`: The name of the B2 bucket where the files should be stored (required)

`B2_BUCKET_BASE_URL`: The base URL for the B2 bucket (required)

`B2_EXECUTABLE_PATH`: The path to the B2 executable (required)

`B2_INFO_PATH`: The path where B2 should look for the authentication database (optional)

`CF_ZONE_ID`: The ID of the CloudFlare zone for the website (optional)

`CF_EMAIL`: The CloudFlare login e-mail (optional)

`CF_KEY`: The CloudFlare API key (optional)

`CF_APP_URL`: The base URL for the app in CloudFlare (optional)

`CF_ENABLED`: `1` = enable CloudFlare `2` = disable CloudFlare