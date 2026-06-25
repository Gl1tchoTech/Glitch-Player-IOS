import SwiftUI

struct FolderBrowserView: View {
    @State private var viewModel = FolderViewModel()
    @Environment(PlayerViewModel.self) private var player
    @State private var showFilePicker: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Breadcrumbs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(viewModel.breadcrumbs.enumerated()), id: \.offset) { index, url in
                            if index > 0 {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            
                            Button(action: { viewModel.navigateToBreadcrumb(at: index) }) {
                                Text(url.lastPathComponent)
                                    .font(.system(size: 13, weight: index == viewModel.breadcrumbs.count - 1 ? .semibold : .regular))
                                    .foregroundColor(index == viewModel.breadcrumbs.count - 1 ? .primary : .gray)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // File List
                if viewModel.contents.isEmpty {
                    emptyFolderView
                } else {
                    List {
                        ForEach(viewModel.contents) { item in
                            FileRow(item: item) {
                                if item.isDirectory {
                                    viewModel.navigateTo(item.url)
                                } else if item.isAudio {
                                    let track = Track(
                                        id: item.id,
                                        name: item.name,
                                        durationMs: 0,
                                        fileURL: item.url.absoluteString,
                                        isDownloaded: true,
                                        source: "local"
                                    )
                                    player.play(track: track, queue: [track])
                                }
                            }
                        }
                        .onDelete(perform: deleteFiles)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Files")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showFilePicker = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.audio, .mp3, .wav, .mpeg4Audio],
                allowsMultipleSelection: true
            ) { result in
                viewModel.importFromPicker(result: result)
            }
            .onAppear {
                viewModel.refresh()
            }
        }
    }
    
    var emptyFolderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Files")
                .font(.system(size: 18, weight: .semibold))
            
            Text("Tap + to import audio files")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Button(action: { showFilePicker = true }) {
                Label("Import Files", systemImage: "square.and.arrow.down")
                    .font(.system(size: 15, weight: .medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.pink)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.top, 80)
    }
    
    private func deleteFiles(at offsets: IndexSet) {
        for index in offsets {
            try? viewModel.deleteFile(at: viewModel.contents[index].url)
        }
    }
}

struct FileRow: View {
    let item: FileItemView
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 20))
                    .foregroundColor(item.iconColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        if !item.isDirectory {
                            Text(item.fileSizeFormatted)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Text("•")
                                .foregroundColor(.gray)
                            Text(item.extension.uppercased())
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                if item.isDirectory {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
