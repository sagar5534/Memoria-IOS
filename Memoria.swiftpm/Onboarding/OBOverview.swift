//
//  Onboarding_Overview.swift
//  Memoria
//
//  Created by Sagar R Patel on 2021-10-03.
//

import SwiftUI

struct OnboardingModel: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let asset: String
}

struct OBOverview: View {
    @State private var selectedPage = 0

    var body: some View {
        NavigationView {
            ZStack {
                Image("TEST2")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: UIScreen.main.bounds.width
                    )
                    .clipped()
                    .overlay(
                        LinearGradient(gradient: Gradient(
                            colors: [
                                Color(UIColor.systemBackground).opacity(0.3),
                                Color(UIColor.systemBackground).opacity(0.6),
                                Color(UIColor.systemBackground).opacity(0.8),
                                Color(UIColor.systemBackground).opacity(1),
                            ]
                        ), startPoint: .top, endPoint: .bottom)
                    )

                VStack {
                    TabView(selection: $selectedPage.animation()) {
                        OBOverview_Main()
                            .tag(0)
                        OBOverview_Features()
                            .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                    VStack(alignment: .center) {
                        PageControl(currentPage: $selectedPage, numberOfPages: 2)
                            .frame(width: 40)
                            .padding()

                        NavigationLink(
                            destination: Login(),
                            label: {
                                Text("Get Started")
                                    .bold()
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(
                                        width: UIScreen.main.bounds.width - 150
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 50)
                                            .foregroundColor(.white)
                                    )
                            }
                        )
                        .foregroundColor(.secondary)

                        Text("Create an account using the web interface")
                            .padding(3)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top)
                }
            }
            .edgesIgnoringSafeArea(.top)
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
        }
        .accentColor(.white)
    }
}

private struct OBOverview_Main: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 15.0) {
                Text("Your \nphotos, \nin your hands.")
                    .bold()
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 50))
                    .lineSpacing(-10)

                Text("Memoria brings together all the media that matters to you. Your personal collection in a single app, on any device, no matter where you are.")
                    .multilineTextAlignment(.leading)
                    .font(.body)
            }
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.bottom)
    }
}

private struct OBOverview_Features: View {
    private var threeColumnGrid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    private var symbols = ["photo", "video", "livephoto", "slowmo", "desktopcomputer", "airplayvideo"]
    private var label = ["Photos", "Videos", "Live Photos", "Slow Motions", "Web Access", "Share"]

    var body: some View {
        VStack(alignment: .leading, spacing: 15.0) {
            Text("Features")
                .bold()
                .multilineTextAlignment(.leading)
                .font(.system(size: 50))
                .lineSpacing(-10)
                .padding()

            LazyVGrid(columns: threeColumnGrid, spacing: 20) {
                ForEach(symbols.indices, id: \.self) { index in
                    VStack(alignment: .center) {
                        Image(systemName: symbols[index])
                            .font(.system(size: 30))
                            .frame(width: 50, height: 50)
                            .cornerRadius(10)
                        Text(label[index])
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .padding()
    }
}

struct Onboarding_Overview_Previews: PreviewProvider {
    static var previews: some View {
        OBOverview()
        OBOverview_Main()
        OBOverview_Features()
    }
}