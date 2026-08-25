import CoreGraphics

enum SyntheticEventIdentity {
    static let signature: Int64 = 0x4D_49_47_4D_4F_55_53_45 // "MIGMOUSE"

    static func mark(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: signature)
    }

    static func owns(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == signature
    }
}
