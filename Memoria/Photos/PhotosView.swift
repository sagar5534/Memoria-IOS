//
//  PhotosView.swift
//  PhotosView
//
//  Created by Sagar on 2021-09-10.
//

import SwiftUI

struct PhotosView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Namespace private var PhotoView
    @ObservedObject var photoGridData = PhotoGridData()
    @State private var media: Media?
    @State private var details = false
    @State private var showShareSheet = false
    @State private var showToolbarButtons = true
    
    @State var lastScaleValue: CGFloat = 1.0
    @State private var scaler: CGFloat = 160
//    let columns = [GridItem(.adaptive(minimum: scaler), spacing: 2)]

    var body: some View {
        ZStack {
            // TODO: Might need to change to a parent
            switch horizontalSizeClass {
            case .compact:
                TabView {
                    ScrollGrid
                        .tabItem {
                            Label("Photos", systemImage: "photo.on.rectangle.angled")
                        }
                }
            default:
                ScrollGrid
            }

            if details {
                // --------------------------------------------------------
                // Backdrop to blur the grid while the modal is displayed
                // --------------------------------------------------------
                VisualEffectView(uiVisualEffect: UIBlurEffect(style: .systemThickMaterialDark))
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .onTapGesture(perform: toggleToolbar)

                MediaModal

                // --------------------------------------------------------
                // Toolbar View
                // --------------------------------------------------------
                if showToolbarButtons {
                    PhotosToolbar(onCloseTap: closeMedia, showShareSheet: $showShareSheet)
                        .sheet(isPresented: $showShareSheet) {
                            ShareSheet(activityItems: [])
                        }
                        .transition(.opacity)
                }
            }

        }.animation(.spring(response: 0.3, dampingFraction: 0.6), value: details)
    }

    @ViewBuilder
    var grid: some View {
        let columns = [GridItem(.adaptive(minimum: scaler), spacing: 2)]

        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(photoGridData.groupedMedia.indices, id: \.self) { i in
                Section(header: titleHeader(with: photoGridData.groupedMedia[i].first!.creationDate.toDate()!.toString())) {
                    ForEach(photoGridData.groupedMedia[i].indices, id: \.self) { index in
                        ZStack {
                            // Background
                            Color.clear

                            // Thumbnail
                            if media?.id != photoGridData.groupedMedia[i][index].id {
                                Thumbnail(item: photoGridData.groupedMedia[i][index])
                                    .onTapGesture {
                                        DispatchQueue.main.async {
                                            if !details {
                                                media = photoGridData.groupedMedia[i][index]
                                                details.toggle()
                                            }
                                        }
                                    }
                                    .scaledToFill()
                                    .layoutPriority(-1)
                            }

                            // Media Info
                            if photoGridData.groupedMedia[i][index].isFavorite && !details {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .resizable()
                                            .frame(width: 16, height: 16, alignment: .center)
                                            .foregroundColor(.white)
                                            .padding()
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .clipped()
                        .matchedGeometryEffect(id: photoGridData.groupedMedia[i][index].id, in: PhotoView, isSource: true)
                        .zIndex(media == photoGridData.groupedMedia[i][index] ? 100 : 1)
                        .aspectRatio(1, contentMode: .fit)
                        .id(photoGridData.groupedMedia[i][index].id)
                        .transition(.invisible)
                    }
                }
                .id(UUID())
            }
        }
    }

    @ViewBuilder
    var MediaModal: some View {
        ZStack {
            GeometryReader { geo in
                Thumbnail(item: media!)
                    .matchedGeometryEffect(id: media!.id, in: PhotoView)
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .onTapGesture(perform: toggleToolbar)
            }
            .transition(.modal)
        }
    }

    @ViewBuilder
    var ScrollGrid: some View {
        ScrollView {
            PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                photoGridData.fetchAllMedia()
            }
            Text("Memoria")
                .font(.title)
            grid
                .gesture(
                    MagnificationGesture()
                        .onChanged { val in
                            
                            let delta = val / self.lastScaleValue
                            self.lastScaleValue = val
                            let newScale = self.scaler * delta
                            
                            withAnimation {
                            self.scaler = newScale
                            }
//                            self.scaler = self.scaler + (1 * val)
                            print(newScale)
                        }
                        .onEnded({ val in
                            self.lastScaleValue = 1
                            print("Ended: \(val)")
                        })
                )
        }
        .coordinateSpace(name: "pullToRefresh")
    }

    private func closeMedia() {
        DispatchQueue.main.async {
            details.toggle()
            showToolbarButtons = true
        }
    }

    private func toggleToolbar() {
        DispatchQueue.main.async {
            withAnimation {
                showToolbarButtons.toggle()
            }
        }
    }
}

struct PhotosView_Previews: PreviewProvider {
    static var previews: some View {
        PhotosView()
    }
}
