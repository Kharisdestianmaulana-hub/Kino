//
//  ContentView.swift
//  Kino
//
//  Created by Kharis Destian Maulana on 15/09/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainWorkspaceView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WorkspaceState())
    }
}
