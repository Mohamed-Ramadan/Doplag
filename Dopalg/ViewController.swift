//
//  ViewController.swift
//  Dopalg
//
//  Created by Mohamed Ramadan on 03/03/2022.
//

import UIKit
import AVFoundation
import AVKit
import AssetsLibrary

class ViewController: UIViewController {
    
    @IBOutlet weak var playerView: UIView!
    
    // Movie name with extension
    let movie: (name: String, ext: String) = ("Ocean", "mov")
    let voidoverAudio1: (name: String, ext: String) = ("VoisOverAudio1", "m4a")
    let voidoverAudio2: (name: String, ext: String) = ("VoisOverAudio2", "m4a")
    var player: AVPlayer!
    var playerViewController: AVPlayerViewController!
    lazy var movieURL: URL = {
        return Bundle.main.url(forResource: movie.name, withExtension: movie.ext)!
    }()
     
    lazy var voisoverAudio1URL: URL = {
        return Bundle.main.url(forResource: voidoverAudio1.name, withExtension: voidoverAudio1.ext)!
    }()
    
    lazy var voisoverAudio2URL: URL = {
        return Bundle.main.url(forResource: voidoverAudio2.name, withExtension: voidoverAudio2.ext)!
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupPlayer(with: movieURL)
    }
    
    func setupPlayer(with url: URL, startPlay: Bool = false) {
        if let player = player, let playerViewController = playerViewController {
            player.pause()
            playerViewController.player = nil
        }
        
        player = AVPlayer(url: url)
        playerViewController = AVPlayerViewController()
        playerViewController.view.frame = self.playerView.bounds
        playerViewController.player = player

        DispatchQueue.main.async {
            self.addChild(self.playerViewController)
            self.view.addSubview(self.playerViewController.view)
            self.playerViewController.didMove(toParent: self)
        }
         
        if startPlay {
            player.play()
        }
    }
     
    
    func extractAudio(complation: ((_ audioURL: URL?)-> Void)? = nil) {
        // Create a composition
        let composition = AVMutableComposition()
        do {
            let sourceUrl = Bundle.main.url(forResource: movie.name, withExtension: movie.ext)!
            let asset = AVURLAsset(url: sourceUrl)
            guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { return }
            guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
            try audioCompositionTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: CMTime.zero)
        } catch {
            print(error)
        }

        // Get url for audio output
        let audioOutputUrl = URL(fileURLWithPath: NSTemporaryDirectory() + "\(movie.name)_audio.m4a")
        if FileManager.default.fileExists(atPath: audioOutputUrl.path) {
            try? FileManager.default.removeItem(atPath: audioOutputUrl.path)
        }

        // Create an export session
        let exportAudioSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
        exportAudioSession.outputFileType = AVFileType.m4a
        exportAudioSession.outputURL = audioOutputUrl

        // Export file
        exportAudioSession.exportAsynchronously {
            guard case exportAudioSession.status = AVAssetExportSession.Status.completed else { return }

            DispatchQueue.main.async {
                // Present a UIActivityViewController to share audio file
                guard let outputURL = exportAudioSession.outputURL else { return }
                if let complation = complation {
                    complation(outputURL)
                }
                // Uncomment this to save save audio to device
                //let activityViewController = UIActivityViewController(activityItems: [outputURL], applicationActivities: [])
                //self.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    func extractVideo(complation: ((_ videoURL: URL?)-> Void)? = nil) {
        // Create a composition
        let composition = AVMutableComposition()
        do {
            let sourceUrl = Bundle.main.url(forResource: movie.name, withExtension: movie.ext)!
            let asset = AVURLAsset(url: sourceUrl)
            guard let videoAssetTrack = asset.tracks(withMediaType: AVMediaType.video).first else { return }
            guard let videoCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
            try videoCompositionTrack.insertTimeRange(videoAssetTrack.timeRange, of: videoAssetTrack, at: CMTime.zero)
        } catch {
            print(error)
        }
        
        // Get url for vedio output
        let videoOutputUrl = URL(fileURLWithPath: NSTemporaryDirectory() + "\(movie.name)_video.m4a")
        if FileManager.default.fileExists(atPath: videoOutputUrl.path) {
            try? FileManager.default.removeItem(atPath: videoOutputUrl.path)
        }

        // Create an export session
        let exportVideoSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
        exportVideoSession.outputFileType = AVFileType.mov
        exportVideoSession.outputURL = videoOutputUrl

        // Export file
        exportVideoSession.exportAsynchronously {
            guard case exportVideoSession.status = AVAssetExportSession.Status.completed else { return }
            
            DispatchQueue.main.async {
                // Present a UIActivityViewController to share audio file
                guard let outputURL = exportVideoSession.outputURL else { return }
                if let complation = complation {
                    complation(outputURL)
                }
                
                // Uncomment this to save save audio to device
                //let activityViewController = UIActivityViewController(activityItems: [outputURL], applicationActivities: [])
                //self.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    /// Merges video and sound while keeping sound of the video too
    ///
    /// - Parameters:
    ///   - videoUrl: URL to video file
    ///   - audioUrl: URL to audio file
    ///   - shouldFlipHorizontally: pass True if video was recorded using frontal camera otherwise pass False
    ///   - completion: completion of saving: error or url with final video
    func mergeVideoAndAudio(videoUrl: URL,
                            audioUrl: URL,
                            shouldFlipHorizontally: Bool = false,
                            completion: @escaping (_ error: Error?, _ url: URL?) -> Void) {

        let mixComposition = AVMutableComposition()
        var mutableCompositionVideoTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioOfVideoTrack = [AVMutableCompositionTrack]()

        //start merge

        let aVideoAsset = AVAsset(url: videoUrl)
        let aAudioAsset = AVAsset(url: audioUrl)

        let compositionAddVideo = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                       preferredTrackID: kCMPersistentTrackID_Invalid)

        let compositionAddAudio = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                     preferredTrackID: kCMPersistentTrackID_Invalid)

        let compositionAddAudioOfVideo = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                            preferredTrackID: kCMPersistentTrackID_Invalid)

        let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let aAudioOfVideoAssetTrack: AVAssetTrack? = aVideoAsset.tracks(withMediaType: AVMediaType.audio).first
        let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]

        // Default must have tranformation
        compositionAddVideo?.preferredTransform = aVideoAssetTrack.preferredTransform

        if shouldFlipHorizontally {
            // Flip video horizontally
            var frontalTransform: CGAffineTransform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            frontalTransform = frontalTransform.translatedBy(x: -aVideoAssetTrack.naturalSize.width, y: 0.0)
            frontalTransform = frontalTransform.translatedBy(x: 0.0, y: -aVideoAssetTrack.naturalSize.width)
            compositionAddVideo?.preferredTransform = frontalTransform
        }

        mutableCompositionVideoTrack.append(compositionAddVideo!)
        mutableCompositionAudioTrack.append(compositionAddAudio!)
        mutableCompositionAudioOfVideoTrack.append(compositionAddAudioOfVideo!)

        do {
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero,
                                                                                duration: aVideoAssetTrack.timeRange.duration),
                                                                of: aVideoAssetTrack,
                                                                at: CMTime.zero)

            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero,
                                                                                duration: aVideoAssetTrack.timeRange.duration),
                                                                of: aAudioAssetTrack,
                                                                at: CMTime.zero)

            // adding audio (of the video if exists) asset to the final composition
            if let aAudioOfVideoAssetTrack = aAudioOfVideoAssetTrack {
                try mutableCompositionAudioOfVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero,
                                                                                           duration: aVideoAssetTrack.timeRange.duration),
                                                                           of: aAudioOfVideoAssetTrack,
                                                                           at: CMTime.zero)
            }
        } catch {
            print(error.localizedDescription)
        }

        // Exporting
        let savePathUrl: URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/newVideo.mp4")
        do { // delete old video
            try FileManager.default.removeItem(at: savePathUrl)
        } catch { print(error.localizedDescription) }

        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = true

        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
            case AVAssetExportSession.Status.completed:
                print("success")
                completion(nil, savePathUrl)
            case AVAssetExportSession.Status.failed:
                print("failed \(assetExport.error?.localizedDescription ?? "error nil")")
                completion(assetExport.error, nil)
            case AVAssetExportSession.Status.cancelled:
                print("cancelled \(assetExport.error?.localizedDescription ?? "error nil")")
                completion(assetExport.error, nil)
            default:
                print("complete")
                completion(assetExport.error, nil)
            }
        }

    }
    
    
    //MARK: - Button Actions
    @IBAction func extractAudioAction(_ sender: UIButton) {
        self.extractAudio { audioURL in
            guard let audioURL = audioURL else { return }
            self.setupPlayer(with: audioURL, startPlay: true)
        }
    }
    
    @IBAction func extractVideoAction(_ sender: UIButton) {
        self.extractVideo { videoURL in
            guard let videoURL = videoURL else { return }
            self.setupPlayer(with: videoURL, startPlay: true)
        }
    }
    
    @IBAction func videoAndAudioAction() {
        self.setupPlayer(with: movieURL, startPlay: true)
    }
    
    @IBAction func videoOnlyWithVoisover1Action() {
        self.extractVideo { videoURL in
            guard let videoURL = videoURL else { return }
            self.mergeVideoAndAudio(videoUrl: videoURL, audioUrl: self.voisoverAudio1URL) { error, url in
                guard error == nil, let url = url else {return}
                self.setupPlayer(with: url, startPlay: true)
            }
            
        }
    }
    
    @IBAction func videoOnlyWithVoisover2Action() {
        self.extractVideo { videoURL in
            guard let videoURL = videoURL else { return }
            self.mergeVideoAndAudio(videoUrl: videoURL, audioUrl: self.voisoverAudio2URL) { error, url in
                guard error == nil, let url = url else {return}
                self.setupPlayer(with: url, startPlay: true)
            }
            
        }
    }

}
