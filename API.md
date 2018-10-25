# Sharecuts API

**NOTE: the service is currently in beta, expect the API to change frequently at this early stage. We'll try to keep the documentation up to date as much as possible.**

TIP: If you'd like to explore the API, you can use the [Paw][1] project [available here][2]. Configure the environments with your credentials and start making some API calls.

TIP 2: If you're writing a client in Swift, you can grab the models from the `Models/API` folder and parse them using `JSONDecoder` 😉 

**The base URL for the API is `https://sharecuts.app/api`.**

## Authentication

All API calls listed here with a 🔐 next to their title require authentication.

To authenticate a user with the api, make a `POST` request to `users/authenticate`. This request should have an HTTP basic auth header containing the username and password of the user to be authenticated. The response will be `200` if the authentication was successful or `401` if the user couldn’t be authenticated.

**Request**

`POST https://sharecuts.app/api/users/authenticate`

**Request headers**

`Authorization: Basic (base64-encoded username:password)`

**Response**

```json
{
  "id": "3F5CCA64-4702-489A-ABC3-4E4FA588B0BA",
  "token": "<authentication token will be here>",
  "userID": "B9C79A2E-D778-4D77-AE26-D2DCB47E6530"
}
```

After getting the authentication token, all authenticated requests should include the `Authorization` header with Bearer authentication, using the token.

## Shortcuts

### Get homepage contents

Returns the same content that can be seen in the Sharecuts website home page, including detailed information for the user, deep link and color information. Note that there can be a delay between a new shortcut being published and this endpoint receiving the update since it's cached.

**Request**

`GET https://sharecuts.app/api/shortcuts/home`

**Response**

```json
{
    "count": 41,
    "results": [
        {
            "shortcut": {
                "id": "B35C554D-75FF-4FF8-92D2-058F58FBE4B7",
                "updatedAt": "2018-10-23T21:44:07Z",
                "userID": "D1DFA276-9DDA-4928-A797-D2F971E1E947",
                "fileHash": "1aff9b6917b52552dadc6baa3a726ee3",
                "tagID": "11A8CEDA-8625-407B-A9D3-1088BF550FA8",
                "actionIdentifiers": [
                    "is.workflow.actions.gettext",
                    "is.workflow.actions.setvariable",
                    "is.workflow.actions.gettext",
                    "is.workflow.actions.setvariable",
                    "is.workflow.actions.gettext",
                    "is.workflow.actions.setvariable",
                    "is.workflow.actions.gettext",
                    "is.workflow.actions.setvariable",
                    "is.workflow.actions.gettext",
                    "is.workflow.actions.speaktext",
                    "is.workflow.actions.url",
                    "is.workflow.actions.downloadurl",
                    "is.workflow.actions.getvalueforkey",
                    "is.workflow.actions.setvariable",
                    "is.workflow.actions.gettext",
                    "is.workflow.actions.speaktext"
                ],
                "downloads": 4,
                "title": "Trigger Bitrise Build",
                "color": 463140863,
                "summary": "Trigger a Bitrise build. This shortcut is configured to trigger a build using the Bitrise app slug, Bitrise API access token, git branch and workflow identifier. You can extend it by adding a passphrase check to prevent triggering unwanted builds or adding additional info to specify build parameters to Bitrise.",
                "filePath": "trigger-bitrise-buildA3B9A634-45E5-423C-8683-A4268772D50F.shortcut",
                "actionCount": 16,
                "fileID": "4_z775fd4fd45c276586c490e1f_f10999b01e66dbf68_d20181023_m214407_c001_v0001105_t0049",
                "createdAt": "2018-10-23T21:44:07Z",
                "votes": 4
            },
            "voted": false,
            "actionCountSuffix": "actions",
            "downloadLink": "https:\/\/sharecuts.app\/download\/B35C554D-75FF-4FF8-92D2-058F58FBE4B7.shortcut",
            "colorCode": "1B9AF7",
            "deepLink": "shortcuts:\/\/import-workflow?url=https:\/\/sharecuts.app\/download\/B35C554D-75FF-4FF8-92D2-058F58FBE4B7.shortcut&name=Trigger%20Bitrise%20Build",
            "colorName": "lightBlue",
            "creator": {
                "username": "yigit",
                "id": "D1DFA276-9DDA-4928-A797-D2F971E1E947",
                "name": "Yigit Yurtsever",
                "url": "https:\/\/www.twitter.com\/ygtyurtsever"
            }
        },
	...
}
```

### Search

Searches for a specific word or phrase. The response is equivalent to the home response. Keep in mind search is currently limited to the titles and the query must be at least 3 characters long.

**Request**

`GET https://sharecuts.app/api/shortcuts/search?query=[TERM]`

**Response**

```json
{
    "count": 41,
    "results": [
        {
            "shortcut": {
                "id": "B35C554D-75FF-4FF8-92D2-058F58FBE4B7",
                "updatedAt": "2018-10-23T21:44:07Z",
                "userID": "D1DFA276-9DDA-4928-A797-D2F971E1E947",
                "fileHash": "1aff9b6917b52552dadc6baa3a726ee3",
                "tagID": "11A8CEDA-8625-407B-A9D3-1088BF550FA8",
                "actionIdentifiers": [
                    "is.workflow.actions.gettext",
                    "is.workflow.actions.setvariable",
                    "is.workflow.actions.gettext",
                    "is.workflow.actions.setvariable",
                    "is.workflow.actions.gettext",
                    "is.workflow.actions.setvariable",
                    "is.workflow.actions.gettext",
                    "is.workflow.actions.setvariable",
                    "is.workflow.actions.gettext",
                    "is.workflow.actions.speaktext",
                    "is.workflow.actions.url",
                    "is.workflow.actions.downloadurl",
                    "is.workflow.actions.getvalueforkey",
                    "is.workflow.actions.setvariable",
                    "is.workflow.actions.gettext",
                    "is.workflow.actions.speaktext"
                ],
                "downloads": 4,
                "title": "Trigger Bitrise Build",
                "color": 463140863,
                "summary": "Trigger a Bitrise build. This shortcut is configured to trigger a build using the Bitrise app slug, Bitrise API access token, git branch and workflow identifier. You can extend it by adding a passphrase check to prevent triggering unwanted builds or adding additional info to specify build parameters to Bitrise.",
                "filePath": "trigger-bitrise-buildA3B9A634-45E5-423C-8683-A4268772D50F.shortcut",
                "actionCount": 16,
                "fileID": "4_z775fd4fd45c276586c490e1f_f10999b01e66dbf68_d20181023_m214407_c001_v0001105_t0049",
                "createdAt": "2018-10-23T21:44:07Z",
                "votes": 4
            },
            "voted": false,
            "actionCountSuffix": "actions",
            "downloadLink": "https:\/\/sharecuts.app\/download\/B35C554D-75FF-4FF8-92D2-058F58FBE4B7.shortcut",
            "colorCode": "1B9AF7",
            "deepLink": "shortcuts:\/\/import-workflow?url=https:\/\/sharecuts.app\/download\/B35C554D-75FF-4FF8-92D2-058F58FBE4B7.shortcut&name=Trigger%20Bitrise%20Build",
            "colorName": "lightBlue",
            "creator": {
                "username": "yigit",
                "id": "D1DFA276-9DDA-4928-A797-D2F971E1E947",
                "name": "Yigit Yurtsever",
                "url": "https:\/\/www.twitter.com\/ygtyurtsever"
            }
        },
	...
}
```

### Get the latest shortcuts

Returns the latest shortcuts.

**Request**

`GET https://sharecuts.app/api/shortcuts/latest`

**Response**

```json
{
    "count": 1,
    "results": [
        {
            "summary": "Get information about the latest iOS and watchOS betas",
            "userID": "9B5658E5-072E-4851-9E83-ECE288156A8B",
            "fileID": "4_z775fd4fd45c276586c490e1f_f102d15df4dc32755_d20180708_m162523_c001_v0001103_t0010",
            "id": "C8D9E9C0-8BD5-4067-AEF6-ED408D665E0D",
            "actionIdentifiers": [
                "is.workflow.actions.gettext",
                "is.workflow.actions.downloadurl",
                "is.workflow.actions.setvariable",
                "is.workflow.actions.getvalueforkey",
                "is.workflow.actions.getvalueforkey",
                "is.workflow.actions.setvariable",
                "is.workflow.actions.getvariable",
                "is.workflow.actions.getvalueforkey",
                "is.workflow.actions.getvalueforkey",
                "is.workflow.actions.setvariable",
                "is.workflow.actions.gettext",
                "is.workflow.actions.speaktext"
            ],
            "title": "Apple Betas",
            "updatedAt": "2018-07-08T16:25:23Z",
            "createdAt": "2018-07-08T16:25:23Z",
            "filePath": "betas52A058A3-7309-4987-830F-B20B99A034D3.shortcut",
            "actionCount": 12
        }
    ]
}
```
---
---
---

### Get shortcut details and deep link

Returns details for the shortcut specified, including full user profile, download link and a deep link to open it directly in Shortcuts.

**Request**

`GET https://sharecuts.app/api/shortcuts/SHORTCUT_ID`

**Parameter**: The ID of the shortcut.

**Response**

```json
{
    "shortcut": {
        "summary": "Restart Springboard on a jailbroken iOS device",
        "userID": "B9C79A2E-D778-4D77-AE26-D2DCB47E6530",
        "fileID": "4_z775fd4fd45c276586c490e1f_f102881e2d27df2e5_d20180708_m161310_c001_v0001102_t0021",
        "id": "AFD6417C-FE65-4A21-B363-ADCCE53617F3",
        "actionIdentifiers": [
            "is.workflow.actions.runsshscript"
        ],
        "title": "Respring",
        "updatedAt": "2018-07-08T16:13:10Z",
        "createdAt": "2018-07-08T16:13:10Z",
        "filePath": "respring6738E741-69BD-41AE-A60E-91132BB1BE16.shortcut",
        "actionCount": 1
    },
    "deepLink": "shortcuts://import-workflow?url=https://sharecuts.app/download/AFD6417C-FE65-4A21-B363-ADCCE53617F3.shortcut&name=Respring",
    "download": "https://sharecuts.app/download/AFD6417C-FE65-4A21-B363-ADCCE53617F3.shortcut",
    "user": {
        "username": "_inside",
        "id": "B9C79A2E-D778-4D77-AE26-D2DCB47E6530",
        "name": "Guilherme Rambo",
        "url": "https://twitter.com/_inside"
    }
}
```

---
---
---

### Upload a shortcut 🔐

Uploads a shortcut to the service. Uploading requires an authenticated user with upload permissions.

**Request**

`POST https://sharecuts.app/api/shortcuts`

**Request body**

The body should be encoded as `multipart/form-data` with the following parameters:

`title: String`: The short title for the shortcut

`summary: String`: A brief description of the shortcut

`shortcut: File`: The .shortcut file

**Response**

#### **`200`**: Success

```json
{
    "id": "B37997A2-18A0-4B6F-8B26-009EC99A4979",
    "error": false
}
```

`id`: The identifier of the shortcut that's been created

`error`: Always `false` when the response is `200`

---

**Error Responses**


```json
{
    "error": true,
    "reason": "No multipart part named 'shortcut' was found."
}
```

`error`: Always `true` in case of error

`reason`: An explanation of what went wrong

**Common errors**

#### **`500`**: Server Error

This will happen if any of the required body parameters is missing.

---

#### **`403`**: Forbidden

This means the api key is missing or invalid.

---

#### **`400`**: Bad Request

This means the shortcut file provided is not a valid shortcut file. The service validates the shortcut file to make sure it's in the correct format. Empty shortcuts with no actions also trigger this error.

---
---
---

### Delete a shortcut 🔐

**Request**

`DELETE https://sharecuts.app/api/shortcuts/SHORTCUT_ID`

**Parameter**: The ID of the shortcut to be deleted.

**Response**

#### **`200`**: Success

```json
{
    "id": "B37997A2-18A0-4B6F-8B26-009EC99A4979",
    "error": false
}
```

`id`: The identifier of the shortcut that's been deleted

`error`: Always `false` when the response is `200`

---

**Error Responses**


```json
{
    "error": true,
    "reason": "No multipart part named 'shortcut' was found."
}
```

`error`: Always `true` in case of error

`reason`: An explanation of what went wrong

**Common errors**

#### **`403`**: Forbidden

This means the api key is missing or invalid, or the shortcut doesn't belong to the owner of the api key provided.

---

#### **`404`**: Not Found

This means the shortcut with the provided ID can't be found.

### List tags

**Request**

`GET https://sharecuts.app/api/tags`

**Response**

```json
{
  "count": 8,
  "results": [
    {
      "id": "11A8CEDA-8625-407B-A9D3-1088BF550FA8",
      "slug": "developer",
      "emoji": "📲",
      "name": "Developer"
    },
    ...
  ]
}
```

### Shortcuts by tag

**Request**

`GET https://sharecuts.app/api/tags/[tag_slug]`

Example:  `GET https://sharecuts.app/api/tags/developer`

**Response**

```json
{
  "count": 1,
  "results": [
    {
      "id": "B37997A2-18A0-4B6F-8B26-009EC99A4979",
      "updatedAt": "2018-07-08T18:18:01Z",
      "userID": "B9C79A2E-D778-4D77-AE26-D2DCB47E6530",
      "tagID": "11A8CEDA-8625-407B-A9D3-1088BF550FA8",
      "actionIdentifiers": [
        "is.workflow.actions.runsshscript"
      ],
      "title": "Respring",
      "summary": "Restart Springboard on a jailbroken iOS device",
      "filePath": "respring13E5526C-9713-42F3-9D9D-2F1CE25AAF38.shortcut",
      "actionCount": 1,
      "fileID": "4_z775fd4fd45c276586c490e1f_f103c07e9d312640f_d20180708_m181801_c001_v0001093_t0029",
      "createdAt": "2018-07-08T18:18:01Z",
      "votes": 4
    }
  ],
  "error": false
}
```

---
---
---

## Users

### Get a user's profile

**Request**

`GET https://sharecuts.app/api/users/USER_ID`

**Parameter**: The ID of the user

**Response**

#### **`200`**: Success

```json
{
    "username": "_inside",
    "id": "B9C79A2E-D778-4D77-AE26-D2DCB47E6530",
    "name": "Guilherme Rambo",
    "url": "https://twitter.com/_inside"
}
```

---

**Error Responses**


```json
{
    "error": true,
    "reason": "Not Found"
}
```

`error`: Always `true` in case of error

`reason`: An explanation of what went wrong

**Common errors**

#### **`404`**: Not Found

This means a user can't be found with the ID provided.

[1]:	https://paw.cloud
[2]:	./Sharecuts_PUBLIC.paw