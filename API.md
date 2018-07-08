# Sharecuts API

**NOTE: the service is currently in beta, expect the API to change frequently at this early stage. We'll try to keep the documentation up to date as much as possible.**

TIP: If you'd like to explore the API, you can use the [Paw](https://paw.cloud) project [available here](./Sharecuts_PUBLIC.paw). Configure the environments with your credentials and start making some API calls.

TIP 2: If you're writing a client in Swift, you can grab the models from the `Models` folder and parse them using `JSONDecoder` 😉 

**The base URL for the API is `https://sharecuts.app/api`.**

## Shortcuts

### Get the latest shortcuts

Returns the latest shortcuts, the same collection that shows on the website's home page.

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

Uploads a shortcut to the service. Uploading requires an user API Key which we're giving to a limited number of users at the moment.

**Request**

`POST https://sharecuts.app/api/shortcuts`

**Request headers**

`X-Shortcuts-Key`: The user's API Key. Alternatively, this can be sent in the query parameter `apiKey`.

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
