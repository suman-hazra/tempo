import SwiftUI
import PhotosUI
import SwiftData

struct PhotoCaptureView: View {
    let log: DayLog?

    @Environment(\.modelContext) private var context
    @State private var isLoading: [PhotoAngle: Bool] = [:]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(PhotoAngle.allCases, id: \.self) { angle in
                photoSlot(angle: angle)
            }
        }
    }

    // MARK: - Slot

    @ViewBuilder
    private func photoSlot(angle: PhotoAngle) -> some View {
        let existing = log?.photos.first { $0.angle == angle }

        PhotosPicker(
            selection: photoPickerBinding(angle: angle),
            matching: .images,
            photoLibrary: .shared()
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)

                if let data = existing?.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if isLoading[angle] == true {
                    ProgressView()
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "camera")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text(angle.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .contextMenu {
            if existing != nil {
                Button(role: .destructive) {
                    removePhoto(angle: angle)
                } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Bindings

    private func photoPickerBinding(angle: PhotoAngle) -> Binding<PhotosPickerItem?> {
        Binding(
            get: { nil },
            set: { item in
                guard let item else { return }
                loadAndSave(item: item, angle: angle)
            }
        )
    }

    // MARK: - Photo processing

    private func loadAndSave(item: PhotosPickerItem, angle: PhotoAngle) {
        guard let log else { return }
        isLoading[angle] = true

        Task {
            defer { Task { @MainActor in isLoading[angle] = false } }

            guard
                let data = try? await item.loadTransferable(type: Data.self),
                let uiImage = UIImage(data: data),
                let processed = processPhoto(uiImage)
            else { return }

            await MainActor.run {
                // Enforce one photo per angle per DayLog
                log.photos.filter { $0.angle == angle }.forEach { context.delete($0) }
                let photo = ProgressPhoto(angle: angle, imageData: processed, dayLog: log)
                context.insert(photo)
                try? context.save()
            }
        }
    }

    // Downscale to max 1080px long edge, JPEG 0.7 — keeps storage and sync light
    private func processPhoto(_ image: UIImage) -> Data? {
        let maxDimension: CGFloat = 1080
        let size = image.size
        let longEdge = max(size.width, size.height)
        let scale: CGFloat = longEdge > maxDimension ? maxDimension / longEdge : 1.0

        guard scale < 1.0 else {
            return image.jpegData(compressionQuality: 0.7)
        }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return scaled.jpegData(compressionQuality: 0.7)
    }

    private func removePhoto(angle: PhotoAngle) {
        log?.photos.filter { $0.angle == angle }.forEach { context.delete($0) }
        try? context.save()
    }
}
