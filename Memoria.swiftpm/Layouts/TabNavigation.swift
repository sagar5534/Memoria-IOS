//
//  TabNavigation.swift
//  TabNavigation
//
//  Created by Sagar on 2021-09-03.
//

import SwiftUI

struct TabNavigation: View {
    var body: some View {
        PhotosView(showTabbar: true)
    }
}

struct TabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        TabNavigation()
    }
}