//
//  ViewController.swift
//  ARCharts
//
//  Created by Bobo on 7/5/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

import ARCharts
import ARKit
import SceneKit
import UIKit


class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var barChart: ARBarChart!
    private let arKitColors = [
        UIColor(colorLiteralRed: 238.0 / 255.0, green: 109.0 / 255.0, blue: 150.0 / 255.0, alpha: 1.0),
        UIColor(colorLiteralRed: 70.0  / 255.0, green: 150.0 / 255.0, blue: 150.0 / 255.0, alpha: 1.0),
        UIColor(colorLiteralRed: 134.0 / 255.0, green: 218.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0),
        UIColor(colorLiteralRed: 237.0 / 255.0, green: 231.0 / 255.0, blue: 254.0 / 255.0, alpha: 1.0),
        UIColor(colorLiteralRed: 0.0   / 255.0, green: 110.0 / 255.0, blue: 235.0 / 255.0, alpha: 1.0),
        UIColor(colorLiteralRed: 193.0 / 255.0, green: 193.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0),
        UIColor(colorLiteralRed: 84.0  / 255.0, green: 204.0 / 255.0, blue: 254.0 / 255.0, alpha: 1.0)
    ]
    
    var session: ARSession {
        get {
            return sceneView.session
        }
    }
    
    var screenCenter: CGPoint?
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.showsStatistics = true
        sceneView.antialiasingMode = .multisampling4X
        sceneView.automaticallyUpdatesLighting = false
        sceneView.contentScaleFactor = 1.0
        sceneView.preferredFramesPerSecond = 60
        DispatchQueue.main.async {
            self.screenCenter = self.sceneView.bounds.mid
        }
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
        
        setupFocusSquare()
        setupRotationGesture()
        setupTapGesture()
        // TODO: setupLongPressGesture()
        
        addLightSource(ofType: .omni)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.configuration?.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
        sceneView.delegate = self
        
        screenCenter = self.sceneView.bounds.mid
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK - Setups
    
    var focusSquare = FocusSquare()
    
    func setupFocusSquare() {
        focusSquare.isHidden = true
        focusSquare.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(focusSquare)
    }
    
    private func constructBarChart(at position: SCNVector3) {
        if barChart != nil {
            barChart.removeFromParentNode()
            barChart = nil
        }
        
        let values = generateRandomNumbers(withRange: 0..<10, numberOfRows: 10, numberOfColumns: 10)
        
        let dataSeries = ARDataSeries(withValues: values)
        dataSeries.seriesLabels = Array(0..<values.count).map({ "Series \($0)" })
        dataSeries.indexLabels = Array(0..<values.first!.count).map({ "Index \($0)" })
        dataSeries.barColors = arKitColors
        
        self.barChart = ARBarChart(dataSource: dataSeries, delegate: dataSeries, size: SCNVector3(0.3, 0.3, 0.3))
        self.barChart.position = position
        self.barChart.animationType = .progressiveGrow
        self.barChart.drawGraph()
        self.sceneView.scene.rootNode.addChildNode(self.barChart)
    }
    
    private func addLightSource(ofType type: SCNLight.LightType, at position: SCNVector3? = nil) {
        let light = SCNLight()
        light.color = UIColor.white
        light.type = type
        light.intensity = 1500 // Default SCNLight intensity is 1000
        
        let lightNode = SCNNode()
        lightNode.light = light
        if let lightPosition = position {
            // Fix the light source in one location
            lightNode.position = lightPosition
            self.sceneView.scene.rootNode.addChildNode(lightNode)
        } else {
            // Make the light source follow the camera position
            self.sceneView.pointOfView?.addChildNode(lightNode)
        }
    }
    
    private func setupRotationGesture() {
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        self.view.addGestureRecognizer(rotationGestureRecognizer)
    }
    
    private func setupTapGesture() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // TODO: Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // TODO: Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // TODO: Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    // MARK: - Actions
    
    @IBAction func handleTapAddButton(_ sender: Any) {
        guard let lastPosition = focusSquare.lastPosition else {
            return
        }
        
        self.constructBarChart(at: lastPosition)
    }
    
    private var startingRotation: Float = 0.0
    
    @objc func handleRotation(rotationGestureRecognizer: UIRotationGestureRecognizer) {
        guard let barChart = barChart,
            let pointOfView = sceneView.pointOfView,
            sceneView.isNode(barChart, insideFrustumOf: pointOfView) == true else {
            return
        }
        
        if rotationGestureRecognizer.state == .began {
            startingRotation = self.barChart.eulerAngles.y
        } else if rotationGestureRecognizer.state == .changed {
            self.barChart.eulerAngles.y = startingRotation - Float(rotationGestureRecognizer.rotation)
        }
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }
        
        let longPressLocation = gestureRecognizer.location(in: self.view)
        if let barNode = self.sceneView.hitTest(longPressLocation, options: nil).first?.node as? ARBar {
            barChart.highlightBar(atIndex: barNode.index, forSeries: barNode.series, withAnimationStyle: .dropAway, withAnimationDuration: 0.3)
            
            let tapToUnhighlight = UITapGestureRecognizer(target: self, action: #selector(handleTapToUnhighlight(_:)))
            self.view.addGestureRecognizer(tapToUnhighlight)
        }
    }
    
    @objc func handleTapToUnhighlight(_ gestureRecognizer: UITapGestureRecognizer) {
        barChart.unhighlight()
        self.view.removeGestureRecognizer(gestureRecognizer)
    }
    
    // MARK: - Helper Functions
    
    func updateFocusSquare() {
        guard let screenCenter = screenCenter else {
            return
        }
        
        focusSquare.isHidden = false
        focusSquare.unhide()
        let (worldPos, planeAnchor, _) = worldPositionFromScreenPosition(screenCenter, objectPos: focusSquare.position)
        if let worldPos = worldPos {
            focusSquare.update(for: worldPos, planeAnchor: planeAnchor, camera: self.session.currentFrame?.camera)
        }
    }
    
    var dragOnInfinitePlanesEnabled = false
    
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }
        
        if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
            
            let pointOnPlane = objectPos ?? SCNVector3Zero
            
            let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
    
}
