import SwiftUI

struct GenreListView: View {
    @Environment(BrowseViewModel.self) private var viewModel
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            if viewModel.categories.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading genres...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.categories) { category in
                        NavigationLink(destination: GenreDetailView(category: category)) {
                            GenreCard(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .task {
            await viewModel.loadCategories()
        }
    }
}

struct GenreCard: View {
    let category: CategoryItem
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(categoryColor)
                .aspectRatio(1.6, contentMode: .fill)
            
            VStack {
                Spacer()
                HStack {
                    Text(category.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(12)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.gray.opacity(0.15), lineWidth: 1)
        )
    }
    
    var categoryColor: Color {
        Color(hex: category.color) ?? .pink
    }
}

struct GenreDetailView: View {
    let category: CategoryItem
    @Environment(BrowseViewModel.self) private var viewModel
    @Environment(PlayerViewModel.self) private var player
    @State private var results: SearchResults?
    
    var body: some View {
        ScrollView {
            if let results = results {
                LazyVStack(spacing: 4) {
                    ForEach(results.tracks) { apiTrack in
                        TrackRowView(track: apiTrack.toTrack(), onTap: {
                            let tracks = results.tracks.map { $0.toTrack() }
                            player.play(track: apiTrack.toTrack(), queue: tracks,
                                        startIndex: results.tracks.firstIndex(where: { $0.id == apiTrack.id }) ?? 0)
                        })
                    }
                }
                .padding(.horizontal, 16)
            } else {
                VStack {
                    ProgressView()
                    Text("Loading \(category.name)...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 80)
            }
        }
        .navigationTitle(category.name)
        .task {
            await viewModel.loadCategory(category.id)
            results = viewModel.categoryResults[category.id]
        }
    }
}

// MARK: - Color from Hex

extension Color {
    init?(hex: String) {
        let r, g, b: Double
        let start = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        
        guard start.count == 6,
              let hexNumber = Int(start, radix: 16) else { return nil }
        
        r = Double((hexNumber >> 16) & 0xFF) / 255
        g = Double((hexNumber >> 8) & 0xFF) / 255
        b = Double(hexNumber & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
}
