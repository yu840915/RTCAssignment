## Prerequisites
* XCode
* [Cocoapods](https://guides.cocoapods.org/using/getting-started.html)
* Paid developer account 

Run following script before start.

```
pod install
```

Open `Oneplanet.xcworkspace`.

Change *Team* setting under *Signing & Capability* before running on device.

##Technical Notes

### Building project

Since there was no enough disk space on my computer, instead of following instructions on [official page](https://webrtc.org/native-code/ios/), I created an empty project and imported source files from [here](https://chromium.googlesource.com/external/webrtc/+/HEAD/examples/objc/AppRTCMobile/), then build and solved errors until successful build.

### Intercept video frame buffers for image processing

The WebRTC doesn't officially provide hooks to modify the camera feed, therefore, we have to break existing object links to inject our workflow, objects declaring public delegation interfaces provide such a chance (with caveats).

On iOS, apps usually rely on `AVCaptureVideoDataOutput` from `AVFoundation` APIs to capture video frame buffers on camera, which has `AVCaptureVideoDataOutputSampleBufferDelegate` to feed frame buffer. I make the `ARDCaptureController` object being the `sampleBufferDelegate` of the `AVCaptureVideoDataOutput` object, implemented an internal hook to add my own workflow and route the product of the workflow back to the capturer and outside display delegate.

### Managing visual effects

I chose `CoreImage` for visual effects for being less risky than `GPUImage` that hasn't updated for years for a 3-day project.
Visual effect commands can come from and go to either local and remote video workflow I built previously. I made a set of abstract interface for interaction (`VideoVisualEffectManaging`) with view controller objects, which provides a way to query available effects, current applied effects and request change effect. Then I implemented a controller `VideoVisualEffectManager` object to route both local and remote update command to `ARDCaptureController` object it also holds available `VisualEffect`s as the feature is still simple. For interaction with the peer, I implemented a proxy `RemoteVideoVisualEffectManagerProxy` object representing the `VideoVisualEffectManager` on remote side, which route send local command to remote and query remote states for display. `VisualEffectMessageChannel` and `VisualEffectMessage` implement how app-specific commands being packaged and transmitted over `RTCDataChannel` channels. `VideoVisualEffectManager` and `RemoteVideoVisualEffectManagerProxy` rely on `VisualEffectMessageChannel` for inter-communication.

`VisualEffectMessageChannel` and `VisualEffectMessage` can be generalized for other uses in the future, like carrying parameters, implementing request response pattern for management, but right now we only need them for visual effect messages.

### Video recording

I made `VideoRecordingSession` for handling video recording flow and comforming to `RTCVideoRenderer` protocol to receive decoded frame buffer from WebRTC. The video recording is rather standard and `RTCCVPixelBuffer` objects provide information for recording video including buffer `CVPixelBuffer`, metadata and timing. In this project, I haven't dealt with VP8 encoded frame. I also found that when running debug mode on an iPhone Xs that plugged into a computer can have trouble recording video, as it reports the encoder(s) is busy.

I made `SaveVideoTaskManager` to handle video saving on background or multiple saving tasks. 

The design make the video recording less coupled (still has alot of room for improvement) with life cycle of `ARDVideoCallViewController` object.