//
//  ViewController+ARSCNViewDelegate.swift
//  DrawingWithSCNLine
//
//  Created by Max Cobb on 12/15/18.
//  Copyright © 2018 Max Cobb. All rights reserved.
//

import ARKit

extension ViewController: ARSCNViewDelegate {
  func addSession() {
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()

    if #available(iOS 13.0, *), ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
      configuration.frameSemantics.insert(.personSegmentationWithDepth)
    }

    // Run the view's session
    sceneView.session.run(configuration)
  }
}
