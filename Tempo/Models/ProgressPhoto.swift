import Foundation
import SwiftData

@Model
final class ProgressPhoto {
    var id: UUID
    var angle: PhotoAngle
    @Attribute(.externalStorage) var imageData: Data  // external storage required for efficient CloudKit sync
    var dayLog: DayLog?  // optional for CloudKit; never nil in practice

    init(angle: PhotoAngle, imageData: Data, dayLog: DayLog) {
        self.id = UUID()
        self.angle = angle
        self.imageData = imageData
        self.dayLog = dayLog
    }
}
