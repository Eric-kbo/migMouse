import SwiftUI

struct SettingsView: View {
    @ObservedObject var runtime: AppRuntime

    var body: some View {
        TabView {
            pointAndClick
                .tabItem { Label(L10n.text("point_and_click"), systemImage: "cursorarrow.click") }
            diagnostics
                .tabItem { Label(L10n.text("diagnostics"), systemImage: "waveform.path.ecg") }
        }
        .padding(20)
    }

    private var pointAndClick: some View {
        Form {
            Section {
                Toggle(L10n.text("tap_to_click"), isOn: binding(\.tapToClickEnabled))
                Toggle(L10n.text("secondary_tap"), isOn: binding(\.secondaryTapEnabled))

                Picker(L10n.text("secondary_tap"), selection: binding(\.secondaryTapMode)) {
                    ForEach(SecondaryTapMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .disabled(!runtime.configuration.secondaryTapEnabled)

                if runtime.configuration.secondaryTapMode == .rightZone {
                    valueSlider(
                        L10n.text("right_side_boundary"),
                        value: binding(\.rightZoneStart),
                        range: 0.4...0.8,
                        format: .percent
                    )
                }
            } header: {
                Text(L10n.text("gestures"))
            }

            Section {
                valueSlider(
                    L10n.text("maximum_tap_duration"),
                    value: binding(\.maximumTapDuration),
                    range: 0.12...0.45,
                    format: .milliseconds
                )
                valueSlider(
                    L10n.text("movement_tolerance"),
                    value: binding(\.maximumDisplacement),
                    range: 0.02...0.16,
                    format: .decimal
                )
                valueSlider(
                    L10n.text("minimum_contact"),
                    value: binding(\.minimumPeakContact),
                    range: 0...1.5,
                    format: .decimal
                )
            } header: {
                Text(L10n.text("recognition"))
            } footer: {
                Text(L10n.text("recognition_description"))
            }
        }
        .formStyle(.grouped)
    }

    private var diagnostics: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                statusBadge(
                    title: L10n.text("magic_mouse"),
                    ready: runtime.activeDeviceCount > 0,
                    detail: runtime.deviceStatus
                )
                statusBadge(
                    title: L10n.text("input_permissions"),
                    ready: runtime.permissionState.isReady,
                    detail: permissionDetail
                )
            }

            TouchSurfaceView(contacts: runtime.currentContacts)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Text(L10n.format("recognized_taps_format", runtime.recognizedTapCount))
                Text(L10n.format("posted_clicks_format", runtime.postedClickCount))
                    .foregroundStyle(.secondary)
                Spacer()
                if let tap = runtime.lastRecognizedTap {
                    Text(L10n.format("last_tap_format", tap.button.localizedTitle, tap.fingerCount))
                        .foregroundStyle(.secondary)
                }
            }

            if let reason = runtime.lastRejectionReason {
                Label(L10n.format("last_rejected_format", reason.localizedDescription), systemImage: "info.circle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button(L10n.text("request_permissions")) { runtime.requestPermissions() }
                Button(L10n.text("reconnect")) { runtime.restartDeviceDiscovery() }
                Button(L10n.text("test_left_click")) { runtime.sendTestClick() }
            }
        }
    }

    private var permissionDetail: String {
        L10n.format(
            "permission_detail_format",
            L10n.text(runtime.permissionState.canListen ? "yes" : "no"),
            L10n.text(runtime.permissionState.canPost ? "yes" : "no")
        )
    }

    private func statusBadge(title: String, ready: Bool, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Circle()
                    .fill(ready ? Color.green : Color.orange)
                    .frame(width: 9, height: 9)
                Text(title).font(.headline)
            }
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    private enum SliderFormat {
        case decimal
        case percent
        case milliseconds
    }

    private func valueSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        format: SliderFormat
    ) -> some View {
        HStack {
            Text(title)
            Slider(value: value, in: range)
            Text(formatted(value.wrappedValue, as: format))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 68, alignment: .trailing)
        }
    }

    private func formatted(_ value: Double, as format: SliderFormat) -> String {
        switch format {
        case .decimal:
            value.formatted(.number.precision(.fractionLength(2)))
        case .percent:
            value.formatted(.percent.precision(.fractionLength(0)))
        case .milliseconds:
            L10n.format("milliseconds_format", value * 1_000)
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<GestureConfiguration, Value>) -> Binding<Value> {
        Binding(
            get: { runtime.configuration[keyPath: keyPath] },
            set: { runtime.configuration[keyPath: keyPath] = $0 }
        )
    }
}
