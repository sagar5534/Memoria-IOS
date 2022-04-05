//
//  PhotoView.swift
//  PhotoView
//
//  Created by Sagar on 2021-09-26.
//

import SwiftUI

struct HeroView: View {
    @Namespace var namespace
    
    @ObservedObject var photoGridData = PhotoGridData()
    @ObservedObject var autoUploadService = AutoUploadService()

    @State private var tabSelected = 0
    @State private var selectedItem: Media? = nil
    @State private var showShareSheet = false
    @State private var showModalToolbar = true
    @State private var modalScale = CGSize.zero
    @State private var modalOffset = CGSize.zero
    
    var body: some View {
        
        return ZStack {
            // --------------------------------------------------------
            // NavigationView with LazyVGrid
            // --------------------------------------------------------
            VStack(spacing: 0) {
                switch tabSelected {
                case 0:
                    NavigationView {
                        AllPhotosView(
                            namespace: namespace,
                            photoGridData: photoGridData,
                            selectedItem: selectedItem,
                            openModal: openModal
                        )
                        .toolbar {
                            ToolbarItemGroup(placement: .navigationBarTrailing) {
                                HStack(alignment: .center, spacing: 12.0) {
                                    if autoUploadService.running {
                                        Button(action: {}, label: {
                                            Image(systemName: "arrow.clockwise.icloud")
                                        })
                                        .foregroundColor(.primary)
                                    } else {
                                        Button(action: {
                                            autoUploadService.initiateAutoUpload {
                                                photoGridData.fetchAllMedia()
                                            }
                                        }, label: {
                                            Image(systemName: "checkmark.icloud")
                                        })
                                        .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }
                    .navigationViewStyle(.stack)
                case 1:
                    NavigationView {
                        Text("For You")
                    }
                case 2:
                    NavigationView {
                        Text("Search")
                    }
                case 3:
                    NavigationView {
                        Settings()
                    }
                default:
                    EmptyView()
                }
            
                Divider()
            
                CustomTabBar(tabSelected: $tabSelected)
            }
            .zIndex(1)
            
            // --------------------------------------------------------
            // Modal view
            // --------------------------------------------------------
            if self.selectedItem != nil {
                Group {
                    Color.black
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                        .onTapGesture(count: 1) {
                            withAnimation {
                                showModalToolbar.toggle()
                            }
                        }
                        .zIndex(2)
                    
                    GeometryReader { geo in
                        FullResImage(item: self.selectedItem!)
                            .matchedGeometryEffect(id: self.selectedItem!.id, in: namespace)
                            .scaledToFit()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .scaleEffect(
                                modalScale.height < 50 ?
                                    1 - ((modalScale.height / 100) / 3) :
                                    0.866
                            )
                            .animation(.linear(duration: 0.1), value: modalScale)
                            .offset(x: modalOffset.width, y: modalOffset.height)
                            .onTapGesture(count: 1) {
                                withAnimation {
                                    showModalToolbar.toggle()
                                }
                            }
                    }
                    
                    if showModalToolbar {
                        ModalToolbar(onCloseTap: closeModal, media: $selectedItem, showShareSheet: $showShareSheet)
                            .sheet(isPresented: $showShareSheet) {
                                ShareSheet(activityItems: [])
                            }
                            .transition(.opacity)
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if gesture.translation.height >= 0 {
                                self.modalScale = gesture.translation
                            }
                            self.modalOffset = gesture.translation
                        }
                        .onEnded { gesture in
                            if gesture.translation.height > 50 {
                                closeModal()
                            } else {
                                self.modalScale = .zero
                                self.modalOffset = .zero
                            }
                        }
                )
                .zIndex(3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func closeModal() {
        modalScale = .zero
        modalOffset = .zero
        showModalToolbar = true
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { self.selectedItem = nil }
    }
    
    private func openModal(_ item: Media) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { self.selectedItem = item }
    }
}
