# illinois-app
[Repo under construction for open source] The official app of the University of Illinois. Powered by the Rokwire Platform.

## Requirements

### [Flutter](https://flutter.dev/docs/get-started/install) v1.17.5

### [Android Studio](https://developer.android.com/studio) 3.6+

### [xCode](https://apps.apple.com/us/app/xcode/id497799835) 11.5

### [CocoaPods]https://guides.cocoapods.org/using/getting-started.html) 1.9.3+


## Build


### Clone this repo

### Supply the following private configuration files:

• /.travis.yml
[No description available]


• /secrets.tar.enc
[No description available]

• /assets/configs.json.enc
1. JSON data with the following format:
```
{
  "production": {
    "config_url": "https://api.rokwire.illinois.edu/app/configs",
    "api_key": "XXXXXXXX-XXXX-XXXX-XXXXXXXXXXXXXXXXX"
  },
  "dev": {
    "config_url": "https://api-dev.rokwire.illinois.edu/app/configs",
    "api_key": "XXXXXXXX-XXXX-XXXX-XXXXXXXXXXXXXXXXX"
  },
  "test": {
    "config_url": "https://api-test.rokwire.illinois.edu/app/configs",
    "api_key": "XXXXXXXX-XXXX-XXXX-XXXXXXXXXXXXXXXXX"
  }
}
```
2. Generate random 16-bytes AES128 key.
3. AES encrypt the JSON string, CBC mode, PKCS7 padding, using the AES.
4. Create a data blob contains the AES key at the beginning followed by the encrypted data.
5. Get a base64 encoded string of the data blob and save it as /assets/configs.json.enc.

Alternatively, you can use AESCrypt.encode from /lib/utils/Crypt.dart to generate content of /assets/configs.json.enc.

• /ios/Runner/GoogleService-Info-Debug.plist
• /ios/Runner/GoogleService-Info-Release.plist

The Firebase configuration file for iOS generated from Google Firebase console.

• /android/keys.properties
Contains a GoogleMaps and Android Backup API keys.
```
googleMapsApiKey=XXXXXXXXXXXXXXXXXXXXXX-XXXXXXXXXXXXXXXX
androidBackupApiKey=XXXXXXXXXXXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXX
```

• /android/app/src/debug/google-services.json
• /android/app/src/release/google-services.json
• /android/app/src/profile/google-services.json
The Firebase configuration file for Android generated from Google Firebase console.

### Build the project

```
$ flutter build apk
$ flutter build ios
```
NB: You may need to update singing & capabilities content for Runner project by opening /ios/Runner.xcworkspace from xCode

