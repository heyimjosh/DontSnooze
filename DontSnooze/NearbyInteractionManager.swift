/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The helper class that handles the transfer of discovery tokens between peers
 and maintains the Nearby Interaction session.
 */

import NearbyInteraction
import WatchConnectivity
import Combine
import os.log

class NearbyInteractionManager: NSObject, ObservableObject {
  
  /// The distance to the nearby object (the paired device) in meters.
  @Published var distance: Measurement<UnitLength>?
  
  private var didSendDiscoveryToken: Bool = false
  
  var isConnected: Bool {
    return distance != nil
  }
  
  @Published var session: NISession?
  
  var lastUpdateTime: Date?
  
  override init() {
//    super.init()
//
//    initializeNISession()
//
//    WCSession.default.delegate = self
//    WCSession.default.activate()
  }
  
  func initializeEverything() {
    initializeNISession()
    WCSession.default.delegate = self
    WCSession.default.activate()
  }
  
  func deinitializeEverything() {
    deinitializeNISession()
    for transfer in WCSession.default.outstandingFileTransfers {
        transfer.cancel()
    }
    WCSession.default.delegate = nil
    self.distance = nil
  }
  
  private func initializeNISession() {
      os_log("initializing the NISession")
      session = NISession()
      session?.delegate = self
      session?.delegateQueue = DispatchQueue.main
  }
  
  private func deinitializeNISession() {
    os_log("invalidating and deinitializing the NISession")
    session?.invalidate()
    session = nil
    didSendDiscoveryToken = false
  }
  
  func restartNISession() {
    os_log("restarting the NISession")
    if let config = session?.configuration {
      session?.run(config)
    }
    print("Restarting session, is it nil? \(self.session == nil)")
  }
  
  /// Send the local discovery token to the paired device
  private func sendDiscoveryToken() {
    guard let token = session?.discoveryToken else {
      os_log("NIDiscoveryToken not available")
      return
    }
    
    guard let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
      os_log("failed to encode NIDiscoveryToken")
      return
    }
    
    do {
      try WCSession.default.updateApplicationContext([Helper.discoveryTokenKey: tokenData])
      os_log("NIDiscoveryToken \(token) sent to counterpart")
      didSendDiscoveryToken = true
    } catch let error {
      os_log("failed to send NIDiscoveryToken: \(error.localizedDescription)")
    }
  }
  
  /// When a discovery token is received, run the session
  private func didReceiveDiscoveryToken(_ token: NIDiscoveryToken) {
    
    if session == nil { initializeNISession() }
    if !didSendDiscoveryToken { sendDiscoveryToken() }
    
    os_log("running NISession with peer token: \(token)")
    let config = NINearbyPeerConfiguration(peerToken: token)
    session?.run(config)
    
    // TODO: Nearby Interaction session is init'd -- sendMessage to watchOS to init distance to a value
    // TODO: this isn't working correctly
#if os(iOS)
    
//    Task {
//      do {
//        try await updateWatchWithDistance(self.distance)
//        // Update self.distance after the watch has been successfully notified.
//        os_log("Updated distance on init with the distance of: \(self.distance)")
//      } catch {
//        os_log("Failed to update watch with distance: %@", log: .default, type: .error, error.localizedDescription)
//      }
//    }
    
#endif
  }
}

// MARK: - NISessionDelegate

extension NearbyInteractionManager: NISessionDelegate {
  
  func sessionWasSuspended(_ session: NISession) {
    os_log("NISession was suspended")
    distance = nil
  }
  
  func sessionSuspensionEnded(_ session: NISession) {
    os_log("NISession suspension ended")
    restartNISession()
  }
  
  func session(_ session: NISession, didInvalidateWith error: Error) {
    os_log("NISession did invalidate with error: \(error.localizedDescription)")
    distance = nil
  }
  
  func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
    if let object = nearbyObjects.first, let distance = object.distance {
      let scale: Double = 10.0 // Use 10 for 1 decimal place, 100 for 2 decimal places, etc.
      // Round the distance up to 1 decimal place
      let roundedDistance = ceil(Double(distance) * scale) / scale
      let newDistance = Measurement(value: roundedDistance, unit: UnitLength.meters)
      if newDistance != self.distance {
        
        if let lastUpdate = self.lastUpdateTime, Date().timeIntervalSince(lastUpdate) < 1 {
          // Less than 1 second has passed; do not update
          os_log("Returning because less than 1 second has passed")
          return
        }
        
        // MARK: be careful with this... if someone is right on the edge and they try to move in, it will just ignore the update entirely
        let tolerance = 0.1
        if abs(newDistance.value - (self.distance?.value ?? 0.0)) < tolerance {
          os_log("Returning because the distance update isn't within tolerance, not meaningful")
          return
        }
        
#if os(watchOS)
        // TODO: Donny Wals image loader article to intercept and use an existing Task here
        Task {
          do {
            DispatchQueue.main.async {
              self.distance = newDistance
              self.lastUpdateTime = Date()
            }
            try await updateWatchWithDistance(newDistance)
            os_log("Distance updated successfully")
          } catch {
            os_log("Failed to update watch with distance: %@", log: .default, type: .error, error.localizedDescription)
          }
        }
#endif
      }
    }
  }
  
  
  private func updateWatchWithDistance(_ distance: Measurement<UnitLength>?) async throws {
    guard WCSession.default.isReachable else {
      os_log("WCSession isn't reachable")
      return
    }
    
    let distanceValue = distance?.value ?? -1 // Use -1 or similar to indicate no distance available
    let message = ["distance": distanceValue]
    
    do {
      let reply = try await WCSession.default.sendMessageAsync(message: message)
      // Handle the reply from the watch if needed
      os_log("Reply received: %@", log: .default, type: .debug, String(describing: reply))
    } catch {
      // Handle any errors
      os_log("Error sending distance update: %@", log: .default, type: .error, error.localizedDescription)
    }
  }
  
  
  func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
    switch reason {
    case .peerEnded:
      os_log("the remote peer ended the connection")
      //deinitializeNISession()
      deinitializeEverything()
    case .timeout:
      os_log("peer connection timed out")
      //restartNISession()
      deinitializeEverything()
    default:
      os_log("disconnected from peer for an unknown reason")
      deinitializeEverything()
    }
    //distance = nil
  }
}

// MARK: - WCSessionDelegate

extension NearbyInteractionManager: WCSessionDelegate {
  
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    guard error == nil else {
      os_log("WCSession failed to activate: \(error!.localizedDescription)")
      return
    }
    
    switch activationState {
    case .activated:
      os_log("WCSession is activated")
      if !didSendDiscoveryToken {
        sendDiscoveryToken()
      }
    case .inactive:
      os_log("WCSession is inactive")
    case .notActivated:
      os_log("WCSession is not activated")
    default:
      os_log("WCSession is in an unknown state")
    }
  }
  
#if os(iOS)
  func sessionDidBecomeInactive(_ session: WCSession) {
    os_log("WCSession did become inactive")
  }
  
  func sessionDidDeactivate(_ session: WCSession) {
    os_log("WCSession did deactivate")
  }
  
  func sessionWatchStateDidChange(_ session: WCSession) {
    os_log("""
            WCSession watch state did change:
              - isPaired: \(session.isPaired)
              - isWatchAppInstalled: \(session.isWatchAppInstalled)
            """)
  }
#endif
  
  func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
    // Handle the incoming message.
#if os(iOS)
    print("Received a message on iOS: \(message)")
#endif
    
#if os(watchOS)
    print("Received a message on watchOS: \(message)")
#endif
    
    if let distanceValue = message["distance"] as? Double {
      os_log("Received distance update: %f", log: .default, type: .info, distanceValue)
      
      DispatchQueue.main.async { [weak self] in
        self?.distance = Measurement(value: Double(distanceValue), unit: UnitLength.meters)
      }
      
      // Process the received distance value as needed, e.g., update the UI.
      
      // Optionally, send a reply
      replyHandler(["response": "Distance received"])
    }
  }
  
  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    print("received application context")
    if let tokenData = applicationContext[Helper.discoveryTokenKey] as? Data {
      if let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: tokenData) {
        os_log("received NIDiscoveryToken \(token) from counterpart")
        self.didReceiveDiscoveryToken(token)
      } else {
        os_log("failed to decode NIDiscoveryToken")
      }
    }
  }
}

extension WCSession {
  func sendMessageAsync(message: [String: Any]) async throws -> [String: Any] {
    return try await withCheckedThrowingContinuation { continuation in
      self.sendMessage(message, replyHandler: { reply in
        continuation.resume(returning: reply)
      }, errorHandler: { error in
        continuation.resume(throwing: error)
      })
    }
  }
}
