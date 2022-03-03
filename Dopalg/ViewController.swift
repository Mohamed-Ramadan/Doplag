//
//  ViewController.swift
//  Dopalg
//
//  Created by Mohamed Ramadan on 03/03/2022.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var playerView: UIView!
    
    // Movie name with extension
    let movie: (name: String, ext: String) = ("Ocean", "mov")
    var player: AVPlayer!
    var playerViewController: AVPlayerViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let videoURL = Bundle.main.url(forResource: movie.name, withExtension: movie.ext)!
        player = AVPlayer(url: videoURL)
        playerViewController = AVPlayerViewController()
        playerViewController.player = self.player
        playerViewController.view.frame = self.playerView.frame
        playerViewController.player?.pause()
        playerView.addSubview(playerViewController.view)
    }
    
    @IBAction func extractAudioAction(_ sender: UIButton) {
        self.extractAudio()
    }
    
    @IBAction func extractVideoAction(_ sender: UIButton) {
        self.extractVideo()
    }
    
    func extractAudio() {
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
                let activityViewController = UIActivityViewController(activityItems: [outputURL], applicationActivities: [])
                self.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    func extractVideo() {
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
                let activityViewController = UIActivityViewController(activityItems: [outputURL], applicationActivities: [])
                self.present(activityViewController, animated: true, completion: nil)
            }
        }
    }

}
