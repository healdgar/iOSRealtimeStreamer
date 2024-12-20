// ViewModel.swift
import SwiftUI
import Combine
import AVFoundation
import WebRTC

class Config {
    static let shared = Config()

    private var secrets: [String: Any] = [:]

    private init() {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dictionary = NSDictionary(contentsOfFile: path) as? [String: Any] {
            self.secrets = dictionary
        } else {
            print("Secrets.plist file not found or invalid format.")
        }
    }

    func get(_ key: String) -> String? {
        return secrets[key] as? String
    }
}

class RealtimeViewModel: NSObject, ObservableObject, RTCPeerConnectionDelegate, RTCDataChannelDelegate {
    @Published var conversation: [ConversationItem] = []
    @Published var connectionStatus: String = "Disconnected"
    @Published var isMuted = false

    // TEMPORARY: Your standard API key here for local testing only.
    // DO NOT USE IN PRODUCTION.
    private var standardAPIKey = "KEYFORTESTINGONLY"

    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var peerConnection: RTCPeerConnection?
    private var dataChannel: RTCDataChannel?
    private var localAudioTrack: RTCAudioTrack?

    private let audioSession = AVAudioSession.sharedInstance()

    override init() {
        // Retrieve the API key from Secrets.plist
        if let apiKey = Config.shared.get("STANDARD_API_KEY") {
            self.standardAPIKey = apiKey
        } else {
            fatalError("API Key not found in Secrets.plist")
        }
        
        
        super.init()
        setupAudioSession()
        setupPeerConnectionFactory()
    }

    // MARK: - Setup
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func setupPeerConnectionFactory() {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
    }

    // MARK: - Connecting via WebRTC
    func connect() {
        connectionStatus = "Fetching ephemeral key..."
        fetchEphemeralKeyTemp { [weak self] ephemeralKey in
            guard let self = self, let ephemeralKey = ephemeralKey else {
                DispatchQueue.main.async {
                    self?.connectionStatus = "Error: Could not retrieve ephemeral key"
                }
                return
            }
            self.createPeerConnection()
            self.addLocalAudioTrack()
            self.createDataChannel()
            self.makeOffer(ephemeralKey: ephemeralKey)
        }
    }

    func disconnect() {
        connectionStatus = "Disconnected"
        peerConnection?.close()
        peerConnection = nil
    }

    // MARK: - Ephemeral Key (Temporary/Unsafe Method)
    private func fetchEphemeralKeyTemp(model: String = "gpt-4o-mini-realtime-preview",
                                       voice: String = "verse",
                                       completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/realtime/sessions") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(standardAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": model,
            "voice": voice
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            completion(nil)
            return
        }

        request.httpBody = bodyData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching ephemeral key: \(error)")
                completion(nil)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let clientSecret = json["client_secret"] as? [String: Any],
                  let ephemeralKey = clientSecret["value"] as? String else {
                print("Could not parse ephemeral key")
                completion(nil)
                return
            }

            completion(ephemeralKey)
        }
        task.resume()
    }

    private func createPeerConnection() {
        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = peerConnectionFactory.peerConnection(with: config, constraints: constraints, delegate: self)
    }

    private func addLocalAudioTrack() {
        let audioSource = peerConnectionFactory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
        localAudioTrack = peerConnectionFactory.audioTrack(with: audioSource, trackId: "audio0")

        let streamId = "stream0"
        if let track = localAudioTrack {
            peerConnection?.add(track, streamIds: [streamId])
        }
    }

    private func createDataChannel() {
        let config = RTCDataChannelConfiguration()
        config.isOrdered = true
        dataChannel = peerConnection?.dataChannel(forLabel: "oai-events", configuration: config)
        dataChannel?.delegate = self
    }

    private func makeOffer(ephemeralKey: String) {
        guard let pc = peerConnection else { return }

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        pc.offer(for: constraints) { [weak self] sdp, error in
            guard let self = self else { return }
            if let error = error {
                print("Error creating offer: \(error)")
                return
            }
            guard let sdp = sdp else { return }
            pc.setLocalDescription(sdp) { error in
                if let error = error {
                    print("Error setting local description: \(error)")
                    return
                }

                // Send SDP offer to OpenAI
                self.sendOfferToOpenAI(sdp: sdp.sdp, ephemeralKey: ephemeralKey)
            }
        }
    }

    private func sendOfferToOpenAI(sdp: String, ephemeralKey: String) {
        connectionStatus = "Connecting..."
        let baseUrl = "https://api.openai.com/v1/realtime"
        let model = "gpt-4o-realtime-preview-2024-12-17"
        guard let url = URL(string: "\(baseUrl)?model=\(model)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(ephemeralKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.httpBody = sdp.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("Error sending offer to OpenAI: \(error)")
                DispatchQueue.main.async {
                    self.connectionStatus = "Error"
                }
                return
            }

            guard let data = data, let answerSDP = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self.connectionStatus = "Error parsing answer"
                }
                return
            }

            let remoteDesc = RTCSessionDescription(type: .answer, sdp: answerSDP)
            self.peerConnection?.setRemoteDescription(remoteDesc) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error setting remote description: \(error)")
                        self.connectionStatus = "Error"
                    } else {
                        self.connectionStatus = "Connected"
                    }
                }
            }
        }.resume()
    }

    // MARK: - Server VAD Setup
    // Once the data channel is open, we can send a session.update event to enable server VAD.
    private func sendSessionUpdate() {
        let sessionUpdate: [String: Any] = [
            "type": "session.update",
            "session": [
                "turn_detection": [
                    "type": "server_vad",
                    "threshold": 0.5,
                    "prefix_padding_ms": 300,
                    "silence_duration_ms": 200
                ]
            ]
        ]
        sendJSON(jsonObject: sessionUpdate)
    }

    // MARK: - Mute/Unmute Logic
    func toggleMute() {
        isMuted.toggle()
        // If muted, disable the track; if unmuted, enable it
        localAudioTrack?.isEnabled = !isMuted
    }

    // MARK: - Sending and Receiving Data
    private func sendJSON(jsonObject: [String: Any]) {
        guard let dataChannel = dataChannel else { return }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            let buffer = RTCDataBuffer(data: jsonData, isBinary: false)
            dataChannel.sendData(buffer)
        } catch {
            print("Error serializing JSON: \(error)")
        }
    }

    // Example: You can still send response.create events if needed
    private func sendResponseCreate() {
        let responseCreate: [String: Any] = [
            "type": "response.create",
            "response": [
                "modalities": ["text", "audio"],
                "instructions": "Please assist the user."
            ]
        ]
        sendJSON(jsonObject: responseCreate)
    }

    // MARK: - Handling Incoming Events
    private func handleReceivedMessage(_ event: [String: Any]) {
        guard let type = event["type"] as? String else { return }
        switch type {
        case "session.created":
            // Session created - possibly send session.update here if the dataChannel is ready
            break
        case "session.updated":
            // Session updated with new configuration
            break
        case "conversation.item.created":
            // Handle new conversation item
            break
        case "response.text.delta":
            // Handle text delta
            break
        case "response.audio.delta":
            // Handle audio data delta
            break
        case "error":
            if let error = event["error"] as? [String: Any], let message = error["message"] as? String {
                print("API Error: \(message)")
            }
        default:
            print("Unhandled message type: \(type)")
        }
    }

    // MARK: - RTCPeerConnectionDelegate
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        // Data channel opened - can now send session.update event
        sendSessionUpdate()
    }

    // Handle incoming remote tracks (e.g., model's audio)
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd receiver: RTCRtpReceiver, streams: [RTCMediaStream]) {
        if let track = receiver.track as? RTCAudioTrack {
            // Handle remote audio, e.g. route to playback
        }
    }

    // MARK: - RTCDataChannelDelegate
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        if dataChannel.readyState == .open {
            print("Data channel open")
            // Once the channel is open, we can send the session.update
            sendSessionUpdate()
        }
    }

    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if !buffer.isBinary {
            do {
                if let event = try JSONSerialization.jsonObject(with: buffer.data, options: []) as? [String: Any] {
                    handleReceivedMessage(event)
                }
            } catch {
                print("Error parsing incoming event: \(error)")
            }
        }
    }
}
