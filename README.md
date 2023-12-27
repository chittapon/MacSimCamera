# MacSimCamera

Use camera from your laptop when running on iOS Simulator when using AVFoundation.

## Features

- Recording Video
- Video capture frame
- Photo capture
- QRCode

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- iOS 12.0+
- Xcode 14.0+
- Swift 5.0+


## Installation

Add the following line to your Podfile:

```ruby
pod 'MacSimCamera', :git => 'https://github.com/chittapon/MacSimCamera.git', :configurations => ['Debug']
```

## Setup
- Open `Schema/Edit scheme...`
- Select Run action
- Select `Pre-Actions`
  - Add `New Run Script action`
  - `${BUILT_PRODUCTS_DIR}/MacSimCamera/MacSimCamera.bundle/start.sh`


That's it, zero line of code needed!


## Author

Chittapon Thongchim, papcoe@gmail.com

## License

MacSimCamera is available under the MIT license. See the LICENSE file for more info.
