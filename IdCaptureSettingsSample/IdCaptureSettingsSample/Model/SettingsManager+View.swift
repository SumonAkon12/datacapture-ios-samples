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

import ScanditIdCapture

extension SettingsManager {

    // MARK: Logo

    var logoAnchor: Anchor {
        get {
            return captureView.logoAnchor
        }
        set {
            captureView.logoAnchor = newValue
        }
    }

    var logoOffset: PointWithUnit {
        get {
            return captureView.logoOffset
        }
        set {
            captureView.logoOffset = newValue
        }
    }

    // MARK: Gestures

    var tapToFocus: Bool {
        get {
            return captureView.focusGesture != nil
        }
        set {
            captureView.focusGesture = newValue ? TapToFocus() : nil
        }
    }

    var swipeToZoom: Bool {
        get {
            return captureView.zoomGesture != nil
        }
        set {
            captureView.zoomGesture = newValue ? SwipeToZoom() : nil
        }
    }
}
