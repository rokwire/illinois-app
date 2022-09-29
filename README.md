# Illinois App
The official mobile app of the University of Illinois. Powered by the [Rokwire Platform](https://rokwire.org/).

## Requirements

### [Flutter](https://flutter.dev/docs/get-started/install) v3.3.2

### [Android Studio](https://developer.android.com/studio) 2021.3.1+

### [xCode](https://apps.apple.com/us/app/xcode/id497799835) 13.2.1

### [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) 1.11.3+


## Build

### Clone this repo
```
git clone --recurse-submodules https://github.com/rokwire/illinois-app.git
```

### Make sure app flutter plugin persists
Rokwire app flutter plugin is used by the Illinois app. It should be located in the `plugin` subdirectory of the application's root project directory. If it does not exist you need to clone it manually.
```
cd illinois-app.git
git clone https://github.com/rokwire/app-flutter-plugin.git plugin
```

### Supply the following private configuration files:

#### • .travis.yml
Obsolete, not used after version 2.0 inclusive.

#### • secrets.tar.enc
Obsolete, not used after version 2.0 inclusive.

#### • assets/config.keys.json (for versions after 3.0 inclusive)
JSON data with the following format:
```
{
	"key":"...",
	"iv":"..."
}
```
`key` and `iv` fields contain strings that are base64 encoded randomly generated 16-bytes AES128 key and IV. These keys are used for decryption of `assets/configs.json.enc` from the application assets as well as for the decryption of `secretKeys` enctypted string in app config.

#### • assets/configs.json.enc
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
2. For versions prior to 3.0:
   - Generate random 16-bytes AES128 key.
   - AES encrypt the JSON string, CBC mode, PKCS7 padding, using the AES.
   - Create a data blob that contains the AES key at the beginning followed by the encrypted data.
   - Get a base64 encoded string of the data blob and save it as `assets/configs.json.enc`.

Alternatively, you can use AESCrypt.encode from /lib/utils/Crypt.dart to generate content of `assets/configs.json.enc`.

3. For versions after 3.0 inclusive:
   - AES encrypt the JSON string, CBC mode, PKCS7 padding, using the key and IV from `assets/config.keys.json`.
   - Get a base64 encoded string of the encryption result and save it as `assets/configs.json.enc`.

#### • ios/Runner/GoogleService-Info-Debug.plist
#### • ios/Runner/GoogleService-Info-Release.plist

The Firebase configuration file for iOS generated from Google Firebase console.

#### • android/keys.properties
Contains a GoogleMaps and Android Backup API keys.
```
googleMapsApiKey=XXXXXXXXXXXXXXXXXXXXXX-XXXXXXXXXXXXXXXX
androidBackupApiKey=XXXXXXXXXXXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXX
```

#### • android/app/src/debug/google-services.json
#### • android/app/src/release/google-services.json
#### • android/app/src/profile/google-services.json
The Firebase configuration file for Android generated from Google Firebase console.

### Build the project

```
$ flutter build apk --no-tree-shake-icons
$ flutter build ios --no-tree-shake-icons
```
NB: For versions prior to 4.2 you may omit the `no-tree-shake-icons` build parameter.
NB: You may need to update singing & capabilities content for Runner project by opening `ios/Runner.xcworkspace` from xCode

## Documentation

### [Illinois Application](https://github.com/rokwire/illinois-app/wiki) v3.2

### [Application Flutter Pluging](https://github.com/rokwire/app-flutter-plugin/wiki) v1.0.0
