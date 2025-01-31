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

import UIKit
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

class ScanningViewController: UIViewController {
    var results: [String: Barcode] = [:]

    @IBOutlet private weak var showResultsButton: UIButton!

    private var context: DataCaptureContext!
    private var camera: Camera?
    private var barcodeTracking: BarcodeTracking!
    private var captureView: DataCaptureView!
    private var overlay: BarcodeTrackingBasicOverlay!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupRecognition()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        results = [:]

        // Switch camera on to start streaming frames. The camera is started asynchronously and will take some time to
        // completely turn on.
        barcodeTracking.isEnabled = true
        camera?.switch(toDesiredState: .on)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Switch camera off to stop streaming frames. The camera is stopped asynchronously and will take some time to
        // completely turn off. Until it is completely stopped, it is still possible to receive further results, hence
        // it's a good idea to first disable barcode tracking as well.
        barcodeTracking.isEnabled = false
        camera?.switch(toDesiredState: .off)
    }

    func setupRecognition() {
        // Create data capture context using your license key.
        context = DataCaptureContext.licensed

        // Use the world-facing (back) camera and set it as the frame source of the context. The camera is off by
        // default and must be turned on to start streaming frames to the data capture context for recognition.
        // See viewWillAppear and viewDidDisappear above.
        camera = Camera.default
        context.setFrameSource(camera, completionHandler: nil)

        // Use the recommended camera settings for the BarcodeTracking mode as default settings.
        // The preferred resolution is automatically chosen, which currently defaults to HD on all devices.
        // Setting the preferred resolution to full HD helps to get a better decode range.
        let cameraSettings = BarcodeTracking.recommendedCameraSettings
        cameraSettings.preferredResolution = .fullHD
        camera?.apply(cameraSettings, completionHandler: nil)

        // The barcode tracking process is configured through barcode tracking settings
        // and are then applied to the barcode tracking instance that manages barcode tracking.
        let settings = BarcodeTrackingSettings()

        // The settings instance initially has all types of barcodes (symbologies) disabled. For the purpose of this
        // sample we enable a very generous set of symbologies. In your own app ensure that you only enable the
        // symbologies that your app requires as every additional enabled symbology has an impact on processing times.
        settings.set(symbology: .ean13UPCA, enabled: true)
        settings.set(symbology: .ean8, enabled: true)
        settings.set(symbology: .upce, enabled: true)
        settings.set(symbology: .code39, enabled: true)
        settings.set(symbology: .code128, enabled: true)

        // Create new barcode tracking mode with the settings from above.
        barcodeTracking = BarcodeTracking(context: context, settings: settings)

        // Register self as a listener to get informed of tracked barcodes.
        barcodeTracking.addListener(self)

        // To visualize the on-going barcode tracking process on screen, setup a data capture view that renders the
        // camera preview. The view must be connected to the data capture context.
        captureView = DataCaptureView(context: context, frame: view.bounds)
        captureView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(captureView)
        view.sendSubviewToBack(captureView)

        // Add a barcode tracking overlay to the data capture view to render the tracked barcodes on top of the video
        // preview. This is optional, but recommended for better visual feedback. The overlay is automatically added
        // to the view.
        overlay = BarcodeTrackingBasicOverlay(barcodeTracking: barcodeTracking, view: captureView, style: .frame)
        overlay.brush = .accepted
        overlay.delegate = self
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let resultsViewController = segue.destination as? ResultsViewController else {
            return
        }

        resultsViewController.results = Array(results.values)
    }
}

// MARK: - Barcode extension

fileprivate extension Barcode {
    var isRejected: Bool {
        return data?.first == "7"
    }
}

// MARK: - BarcodeTrackingListener

extension ScanningViewController: BarcodeTrackingListener {
    // This function is called whenever objects are updated and it's the right place to react to the tracking results.
    func barcodeTracking(_ barcodeTracking: BarcodeTracking,
                         didUpdate session: BarcodeTrackingSession,
                         frameData: FrameData) {
        let barcodes = session.trackedBarcodes.values.compactMap { $0.barcode }
        DispatchQueue.main.async {
            barcodes.forEach { barcode in
                // The `isRejected` property is for illustrative purposes only, not part of the official API.
                if let data = barcode.data, !data.isEmpty, !barcode.isRejected {
                    self.results[data] = barcode
                }
            }
        }
    }
}

// MARK: - Brush extension

fileprivate extension Brush {
    static let rejected: Brush = {
        let defaultBrush = BarcodeTrackingBasicOverlay.defaultBrush(forStyle: .frame)
        guard let brushBorderColor = UIColor(sdcHexString: "#FA4446FF") else {
            return .transparent
        }
        return Brush(fill: defaultBrush.fillColor,
                     stroke: brushBorderColor,
                     strokeWidth: defaultBrush.strokeWidth)
    }()

    static let accepted: Brush = {
        let defaultBrush = BarcodeTrackingBasicOverlay.defaultBrush(forStyle: .frame)
        guard let brushBorderColor = UIColor(sdcHexString: "#26D381FF") else {
            return .transparent
        }
        return Brush(fill: defaultBrush.fillColor,
                     stroke: brushBorderColor,
                     strokeWidth: defaultBrush.strokeWidth)
    }()
}

// MARK: - BarcodeTrackingBasicOverlayDelegate

extension ScanningViewController: BarcodeTrackingBasicOverlayDelegate {
    // This function is called to get the brush to be used for tracked barcodes, for example to visualize rejected ones.
    // Note that modifying a barcode's brush color requires the MatrixScan AR add-on.
    func barcodeTrackingBasicOverlay(_ overlay: BarcodeTrackingBasicOverlay,
                                     brushFor trackedBarcode: TrackedBarcode) -> Brush? {
        // The `isRejected` property is for illustrative purposes only, not part of the official API.
        if trackedBarcode.barcode.isRejected {
            return .rejected
        } else {
            return overlay.brush
        }
    }

    func barcodeTrackingBasicOverlay(_ overlay: BarcodeTrackingBasicOverlay,
                                     didTap trackedBarcode: TrackedBarcode) {
    }
}
