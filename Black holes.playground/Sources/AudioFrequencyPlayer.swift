import AVFoundation

public class AudioFrequencyPlayer{
    // store persistent objects
    private var audioEngine = AVAudioEngine()
    private var player = AVAudioPlayerNode()
    private var mixer: AVAudioMixerNode {
        return audioEngine.mainMixerNode
    }
    
    private let preferredBufferDuration: TimeInterval = 0.3
    
    public init() {
        // setup audio engine
        audioEngine.attach(player)
        audioEngine.connect(player, to: mixer, format: player.outputFormat(forBus: 0))
        try? audioEngine.start()
    }
    
    public func play(frequency: Float, amplitude: Float = 1) {
        let fullPeriods = ceil(preferredBufferDuration * Double(frequency))
        let bufferDuration: TimeInterval = fullPeriods / Double(frequency)
        
        let sampleRate = mixer.outputFormat(forBus: 0).sampleRate
        let frameLength = AVAudioFrameCount(bufferDuration * sampleRate)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: player.outputFormat(forBus: 0), frameCapacity: frameLength)
        buffer.frameLength = frameLength
        
        let channelCount = mixer.outputFormat(forBus: 0).channelCount
        
        for i in 0..<frameLength {
            let signal = amplitude * sin(2 * .pi * frequency * Float(i * channelCount) / Float(sampleRate))
            
            buffer.floatChannelData?.pointee[Int(i * channelCount)] = signal
        }
        
        player.scheduleBuffer(buffer, at: AVAudioTime(hostTime: mach_absolute_time()), options: .loops, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }

    }
    
    public func stop() {
        player.stop()
    }
    
}
