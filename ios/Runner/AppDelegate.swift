import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let downloadsChannel = "classpluse/downloads"
  private let appFolderName = "ClassPluse"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: downloadsChannel,
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "saveToClassPluse" else {
          result(FlutterMethodNotImplemented)
          return
        }

        guard
          let self,
          let args = call.arguments as? [String: Any],
          let typedData = args["bytes"] as? FlutterStandardTypedData
        else {
          result(FlutterError(
            code: "INVALID_ARGS",
            message: "Missing downloaded file bytes.",
            details: nil
          ))
          return
        }

        let fileName = args["fileName"] as? String ?? "lesson-document"
        let isImage = args["isImage"] as? Bool ?? false

        self.saveToClassPluse(
          data: typedData.data,
          fileName: fileName,
          isImage: isImage,
          result: result
        )
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func saveToClassPluse(
    data: Data,
    fileName: String,
    isImage: Bool,
    result: @escaping FlutterResult
  ) {
    do {
      let fileURL = try writeToClassPluseFolder(data: data, fileName: fileName)

      if isImage, let image = UIImage(data: data) {
        saveImageToPhotos(image) { error in
          if let error {
            result(FlutterError(
              code: "PHOTO_SAVE_FAILED",
              message: error.localizedDescription,
              details: fileURL.path
            ))
            return
          }

          result("Saved to Photos and Files > \(self.appFolderName)")
        }
        return
      }

      result("Saved to Files > \(appFolderName)")
    } catch {
      result(FlutterError(
        code: "SAVE_FAILED",
        message: error.localizedDescription,
        details: nil
      ))
    }
  }

  private func writeToClassPluseFolder(data: Data, fileName: String) throws -> URL {
    let documentsURL = try FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let folderURL = documentsURL.appendingPathComponent(appFolderName, isDirectory: true)

    try FileManager.default.createDirectory(
      at: folderURL,
      withIntermediateDirectories: true
    )

    let fileURL = folderURL.appendingPathComponent(fileName)
    try data.write(to: fileURL, options: .atomic)
    return fileURL
  }

  private func saveImageToPhotos(
    _ image: UIImage,
    completion: @escaping (Error?) -> Void
  ) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        guard status == .authorized || status == .limited else {
          completion(NSError(
            domain: "ClassPluseDownloads",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Photo library access was denied."]
          ))
          return
        }

        self.saveImageToClassPluseAlbum(image, completion: completion)
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        guard status == .authorized else {
          completion(NSError(
            domain: "ClassPluseDownloads",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Photo library access was denied."]
          ))
          return
        }

        self.saveImageToClassPluseAlbum(image, completion: completion)
      }
    }
  }

  private func saveImageToClassPluseAlbum(
    _ image: UIImage,
    completion: @escaping (Error?) -> Void
  ) {
    ensureClassPluseAlbum { album, error in
      if let error {
        completion(error)
        return
      }

      guard let album else {
        completion(NSError(
          domain: "ClassPluseDownloads",
          code: 2,
          userInfo: [NSLocalizedDescriptionKey: "Could not create the ClassPluse album."]
        ))
        return
      }

      PHPhotoLibrary.shared().performChanges {
        let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
        guard let placeholder = assetRequest.placeholderForCreatedAsset,
              let albumRequest = PHAssetCollectionChangeRequest(for: album)
        else {
          return
        }
        albumRequest.addAssets([placeholder] as NSArray)
      } completionHandler: { _, error in
        completion(error)
      }
    }
  }

  private func ensureClassPluseAlbum(
    completion: @escaping (PHAssetCollection?, Error?) -> Void
  ) {
    if let album = fetchClassPluseAlbum() {
      completion(album, nil)
      return
    }

    var placeholder: PHObjectPlaceholder?
    PHPhotoLibrary.shared().performChanges {
      let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
        withTitle: self.appFolderName
      )
      placeholder = request.placeholderForCreatedAssetCollection
    } completionHandler: { _, error in
      if let error {
        completion(nil, error)
        return
      }

      if let identifier = placeholder?.localIdentifier {
        let collection = PHAssetCollection.fetchAssetCollections(
          withLocalIdentifiers: [identifier],
          options: nil
        ).firstObject
        completion(collection, nil)
        return
      }

      completion(self.fetchClassPluseAlbum(), nil)
    }
  }

  private func fetchClassPluseAlbum() -> PHAssetCollection? {
    let options = PHFetchOptions()
    options.predicate = NSPredicate(format: "title = %@", appFolderName)
    return PHAssetCollection.fetchAssetCollections(
      with: .album,
      subtype: .albumRegular,
      options: options
    ).firstObject
  }
}
