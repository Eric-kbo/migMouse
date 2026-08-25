import Foundation

struct GestureConfiguration: Codable, Equatable, Sendable {
    var tapToClickEnabled = true
    var secondaryTapEnabled = true
    var secondaryTapMode = SecondaryTapMode.twoFingers
    var maximumTapDuration = 0.28
    var maximumDisplacement = 0.075
    var maximumPathLength = 0.13
    var minimumPeakContact = 0.75
    var edgeInset = 0.025
    var rightZoneStart = 0.58
    var scrollSuppressionWindow = 0.20
    var physicalClickSuppressionWindow = 0.16

    static let `default` = GestureConfiguration()
}
