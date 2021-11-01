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

import ScanditCaptureCore

class LogoDataSource: DataSource {
    weak var delegate: DataSourceDelegate?

    init(delegate: DataSourceDelegate) {
        self.delegate = delegate
    }

    // MARK: - Sections

    lazy var sections: [Section] = {
        return [
            Section(rows: [
                Row.choice(title: "Anchor",
                           options: Anchor.allCases,
                           getValue: { SettingsManager.current.logoAnchor },
                           didChangeValue: { SettingsManager.current.logoAnchor = $0 },
                           dataSourceDelegate: self.delegate)
            ]),
            Section(rows: [
                Row.choice(title: "Style",
                           options: LogoStyle.allCases,
                           getValue: { SettingsManager.current.logoStyle },
                           didChangeValue: { SettingsManager.current.logoStyle = $0 },
                           dataSourceDelegate: self.delegate)
            ]),
            Section(title: "Offset", rows: [
                Row.valueWithUnit(title: "X",
                                  getValue: { SettingsManager.current.logoOffset.x },
                                  didChangeValue: { SettingsManager.current.logoOffset.x = $0 },
                                  dataSourceDelegate: self.delegate),

                Row.valueWithUnit(title: "Y",
                                  getValue: { SettingsManager.current.logoOffset.y },
                                  didChangeValue: { SettingsManager.current.logoOffset.y = $0 },
                                  dataSourceDelegate: self.delegate)
                ])
        ]
    }()
}
