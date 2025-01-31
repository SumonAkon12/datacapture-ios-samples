/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import ScanditBarcodeCapture

extension DataCaptureContext {
	// There is a Scandit sample license key set below here.
	// This license key is enabled for sample evaluation only.
	// If you want to build your own application,
    // get your license key by signing up for a trial at https://ssl.scandit.com/dashboard/sign-up?p=test
    private static let licenseKey = "Aa2k0xbKMtvDJWNgLU02Cr8aLxUjNtOuqXCjHUxVAUf/d66Y5Tm74sJ+8L0rGQUZ20e52VlMY9I7YW4W13kWbvp36R8jbqQy6yZUGS50G5n4fRItJD6525RcbTYZQjoIGHQqle9jj08ra19ZUy9RliVlOn3hHz4WrGO8vORyATmFXJpULzk0I5RpiT84ckXhG2Ri8jtIzoISX3zsoiLtXVRGjjrkbuGZzGbKA180JKEpdfSQwVyupLti5yNYHAeKihS6IOklCTz8CM1BfRC4zBdIDjbVEJPFgAsLvMU0rTyJhHkB5Ds4wfHbKNFhW0T2XkYLKkvZ7X/HnEVD5oz9Kl4T4rtRkepJfsXUWHUgVugjLO5vqwhMcHNV5XpK2Pk/SLrzGF1PDRu8f4ZhBLrWKknWq+5TSK8GWi4wmGpVvbxqHhLljzOzplYs8I5TtphZ3otJNLs10lhk1YN9cmdaxpdUuF4k0WDU1Qfco75p5G+MBlsAVVFrs0xMF9fSMJkQ+4UU+G+py5781HPkpw4kaGwmJhGrzA/Lbhf4tL+XfynseLw42oygpfVabYEYRHSQx+1j5RpFSR6V9t4jlKsJu2xgYz0A96I82gIHItRRxZkT2oEsZCgYlgCiQsFcsFdo9N9bzDL9mVR5Nj0RPIVvKc01AVtKvXLx86g2rNPv45eBaJFrdsWmv97V8+Pv6M9d+Wr1qcTeT1BY8fvWUEDmU1HF6eCJ1A6cDAM+Nq4sAP9D2lH7D6rHwK+x07F56bMZibLeDoGKanE8PhhamhxBVemE/ByCoMoItBtSbpeBubHVsSHlGF3/AAKi6flY6j0htptgPOM8eOwGXx6YvVxu3KOMF+2RBIQai8LP0YEuhVJ0ST7WX5seeVSu5RMKUx/euHoQB6qID+ydzkXGzYZLTPPskmJSWqrboJQPIjZ/ruCtJepZ/+Lr7g5nCyb01w=="

    // Get a licensed DataCaptureContext.
    static var licensed: DataCaptureContext {
        return DataCaptureContext(licenseKey: licenseKey)
    }
}

class ViewController: UIViewController {

    private var context: DataCaptureContext!
    private var camera: Camera?
    private var barcodeCount: BarcodeCount!
    private var barcodeCountView: BarcodeCountView!
    private var shouldCameraStandby = true

    private var allRecognizedBarcodes: [TrackedBarcode] = []
    private var previouslyScannedBarcodes: [Barcode] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "MatrixScan Count"
        setupRecognition()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make sure that Barcode Count mode is enabled after going back from the list screen
        barcodeCountView.prepareScanning(with: context)

        // Switch camera on to start streaming frames. The camera is started asynchronously and will take some time to
        // completely turn on. To be notified when the camera is completely on, pass non nil block as completion to
        // camera?.switch(toDesiredState:completionHandler:)
        camera?.switch(toDesiredState: .on)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Switch camera to stanby to stop streaming frames. The camera is stopped asynchronously and will take
        // some time to completely turn off.
        // To be notified when the camera is completely stopped, pass a non nil block as completion to
        // camera?.switch(toDesiredState:completionHandler:)
        if shouldCameraStandby {
            camera?.switch(toDesiredState: .standby)
        }

        if isMovingFromParent {
            // Stop the mode when dismissed
            barcodeCountView.stopScanning()
        }
    }

    func setupRecognition() {
        // Create data capture context using your license key.
        context = DataCaptureContext.licensed

        // Use the world-facing (back) camera and set it as the frame source of the context. The camera is off by
        // default and must be turned on to start streaming frames to the data capture context for recognition.
        // See viewWillAppear and viewDidDisappear above.
        camera = Camera.default
        context.setFrameSource(camera, completionHandler: nil)

        // Use the recommended camera settings for the BarcodeCount mode.
        let recommendedCameraSettings = BarcodeCount.recommendedCameraSettings
        camera?.apply(recommendedCameraSettings)

        // The barcode counting process is configured through barcode count settings
        // and are then applied to the barcode count instance that manages barcode recognition.
        let settings = BarcodeCountSettings()

        // The settings instance initially has all types of barcodes (symbologies) disabled. For the purpose of this
        // sample we enable a very generous set of symbologies. In your own app ensure that you only enable the
        // symbologies that your app requires as every additional enabled symbology has an impact on processing times.
        settings.set(symbology: .ean13UPCA, enabled: true)
        settings.set(symbology: .ean8, enabled: true)
        settings.set(symbology: .upce, enabled: true)
        settings.set(symbology: .code39, enabled: true)
        settings.set(symbology: .code128, enabled: true)

        // Create new barcode count mode with the settings from above.
        barcodeCount = BarcodeCount(context: context, settings: settings)

        // Register self as a listener to monitor the barcode count session.
        barcodeCount.addListener(self)

        // To visualize the Barcode Count UI you need to create a BarcodeCountView and add it to the view hierarchy.
        // BarcodeCountView is designed to be displayed full screen.
        barcodeCountView = BarcodeCountView(frame: view.bounds, context: context, barcodeCount: barcodeCount)
        barcodeCountView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(barcodeCountView)
        barcodeCountView.delegate = self
        barcodeCountView.uiDelegate = self
    }

    /// Creates  an array of ScannedItem from TrackedBarcode so that it can be displayed by the ListViewController
    private func prepareScannedItemsList(trackedBarcodes: [TrackedBarcode],
                                         previousBarcodes: [Barcode]) -> [ScannedItem] {
        var tempMap: [String: ScannedItem] = [:]
        var allBarcodes = trackedBarcodes.compactMap { $0.barcode }
        allBarcodes.append(contentsOf: previousBarcodes)
        for barcode in allBarcodes {
            guard let barcodeData = barcode.data else {
                continue
            }
            if var item = tempMap[barcodeData] {
                item.quantity += 1
                tempMap[barcodeData] = item
            } else {
                let newItem = ScannedItem(symbology: barcode.symbology.description.uppercased(),
                                          data: barcodeData,
                                          quantity: 1)
                tempMap[barcodeData] = newItem
            }
        }

        return Array(tempMap.values)
    }

    @objc
    private func showList(isOrderCompleted: Bool) {
        self.shouldCameraStandby = false
        // Get a list of ScannedItem to display
        let scannedItems = prepareScannedItemsList(trackedBarcodes: allRecognizedBarcodes,
                                                   previousBarcodes: previouslyScannedBarcodes)
        let listController = ListViewController(scannedItems: scannedItems, isOrderCompleted: isOrderCompleted)
        // Listen to the user actions
        listController.delegate = self
        // Show the list
        self.navigationController?.pushViewController(listController, animated: true)
    }

    @objc func didEnterBackground() {
        let currentlyTrackedBarcodes = allRecognizedBarcodes.compactMap({ trackedBarcode in
            return trackedBarcode.barcode
        })
        previouslyScannedBarcodes.append(contentsOf: currentlyTrackedBarcodes)
        allRecognizedBarcodes.removeAll()
        barcodeCount.reset()
    }

    @objc func willEnterForeground() {
        barcodeCount.setAdditionalBarcodes(previouslyScannedBarcodes)
    }

    private func resetMode() {
        barcodeCount.setAdditionalBarcodes([])
        barcodeCount.reset()
        allRecognizedBarcodes.removeAll()
        previouslyScannedBarcodes.removeAll()
    }
}

extension ViewController: BarcodeCountListener {
    func barcodeCount(_ barcodeCount: BarcodeCount,
                      didScanIn session: BarcodeCountSession,
                      frameData: FrameData) {
        // Gather all the recognized barcodes
        let allRecognizedBarcodes = session.recognizedBarcodes.map({ $0.value })
        // This method is invoked from a recognition internal thread.
        // Dispatch to the main thread to update the internal barcode list.
        DispatchQueue.main.async {
            // Update the internal list
            self.allRecognizedBarcodes = allRecognizedBarcodes
        }
    }
}

extension ViewController: ListViewControllerDelegate {
    func listViewController(_ listViewController: ListViewController,
                            didFinishWithIntent intent: ListViewController.Intent) {
        switch intent {
        case .restartScanning:
            resetMode()
            self.shouldCameraStandby = true
            self.navigationController?.popViewController(animated: true)
        case .resumeScanning:
            self.shouldCameraStandby = true
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension ViewController: BarcodeCountViewDelegate {
    func barcodeCountView(_ view: BarcodeCountView,
                          brushForRecognizedBarcode trackedBarcode: TrackedBarcode) -> Brush? {
        // Return the default brush
        return BarcodeCountView.defaultRecognizedBrush
    }

    func barcodeCountView(_ view: BarcodeCountView,
                          brushForUnrecognizedBarcode trackedBarcode: TrackedBarcode) -> Brush? {
        // Return the default brush
        return BarcodeCountView.defaultUnrecognizedBrush
    }

    func barcodeCountView(_ view: BarcodeCountView,
                          brushForRecognizedBarcodeNotInList trackedBarcode: TrackedBarcode) -> Brush? {
        // Return the default brush
        return BarcodeCountView.defaultNotInListBrush
    }

    func barcodeCountView(_ view: BarcodeCountView,
                          didTapRecognizedBarcode trackedBarcode: TrackedBarcode) {
        // Not used
    }

    func barcodeCountView(_ view: BarcodeCountView,
                          didTapUnrecognizedBarcode trackedBarcode: TrackedBarcode) {
        // Not used
    }

    func barcodeCountView(_ view: BarcodeCountView,
                          didTapRecognizedBarcodeNotInList trackedBarcode: TrackedBarcode) {
        // Not used
    }

    func barcodeCountView(_ view: BarcodeCountView,
                          didTapFilteredBarcode trackedBarcode: TrackedBarcode) {
        // Not used
    }
}

extension ViewController: BarcodeCountViewUIDelegate {
    func listButtonTapped(for view: BarcodeCountView) {
        // Show the current progress but the order is not completed
        showList(isOrderCompleted: false)
    }

    func exitButtonTapped(for view: BarcodeCountView) {
        // The order is completed
        showList(isOrderCompleted: true)
    }
}
