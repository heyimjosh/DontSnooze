//
//  DontSnoozeApp.swift
//  DontSnooze
//
//  Created by Josh Davis on 4/8/24.
//

//import SwiftUI
//import NearbyInteraction
//
//#if os(watchOS)
//import WatchKit
//#else
//import UIKit
//#endif
//
//@main
//struct DontSnoozeApp: App {
////    var body: some Scene {
////        WindowGroup {
////            ContentView()
////        }
////    }
//  
//  init() {
//    /// NearbyInteraction is only supported on devices with a U1 chip.
//    var isSupported: Bool
//    if #available(iOS 16.0, watchOS 9.0, *) {
//      isSupported = NISession.deviceCapabilities.supportsPreciseDistanceMeasurement
//    } else {
//      isSupported = NISession.isSupported
//    }
//    if isSupported {
//      print("Supported")
//      self.isSupported = true
//    }
//  }
//  
//  @State var isSupported = false
//  
////  @State var distance: Measurement<UnitLength>? {
////    willSet {
////      if let oldDistance = distance?.value, let newDistance = newValue?.value {
////        /// When the distance value changes, play a haptic feedback.
////        if oldDistance.rounded(.up) != newDistance.rounded(.up) {
////          playHaptic()
////        }
////      }
////    }
////  }
//  
//  var body: some Scene {
//    WindowGroup {
//      Group {
//        //if isSupported {
//          ContentView()
////            .onReceive(niManager.$distance) {
////              self.distance = $0?.converted(to: Helper.localUnits)
////            }
//        //} else {
//         // Text("NearbyInteraction is not supported on this device")
//        //}
//      }
//      .multilineTextAlignment(.center)
//      
//      /// Disable the screen timeout on iOS devices.
//#if os(iOS)
//      .onAppear {
//        UIApplication.shared.isIdleTimerDisabled = true
//      }
//      .onDisappear {
//        UIApplication.shared.isIdleTimerDisabled = false
//      }
//#endif
//    }
//  }
//  
//  func playHaptic() {
//#if os(watchOS)
//    WKInterfaceDevice.current().play(.click)
//#else
//    let generator = UIImpactFeedbackGenerator()
//    generator.impactOccurred()
//#endif
//  }
//}


import ComposableArchitecture
import SwiftUI

@main
struct DontSnoozeApp: App {
  let store = Store(initialState: AppFeature.State()) {
    AppFeature()
      ._printChanges()
  } withDependencies: {
//    if ProcessInfo.processInfo.environment["UITesting"] == "true" {
//      $0.dataManager = .mock()
    $0.dataManager = .liveValue
//    }
  }

  var body: some Scene {
    WindowGroup {
      // NB: This conditional is here only to facilitate UI testing so that we can mock out certain
      //     dependencies for the duration of the test (e.g. the data manager). We do not really
      //     recommend performing UI tests in general, but we do want to demonstrate how it can be
      //     done.
      if _XCTIsTesting {
        // NB: Don't run application when testing so that it doesn't interfere with tests.
        EmptyView()
      } else {
        AppView(store: store)
      }
    }
  }
}
