//
//  ContentView.swift
//  BLETrack
//
//  Created by Daniel Günther on 29.03.20.
//  Copyright © 2020 Daniel Günther. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @State private var mode = false
    @ObservedObject var viewModel = listViewData
    
    var body: some View {
        VStack {
            HStack {
                Text("BLETrack")
                    .font(.title)
                    .foregroundColor(Color.purple)
                Text(" - ")
                    .font(.title)
                    .foregroundColor(Color.black).bold()
                Text("COVID-19")
                    .font(.title)
                    .foregroundColor(Color.red)
            }
            Spacer().frame(height:30)
            if !mode {
                Button(action: {
                    self.mode.toggle()
                    bl_broadcast.dewIt();
                }) {
                    Text("Go Online")
                        .font(.title)
                        .fontWeight(.semibold)
                }
            }
            if mode {
                Button(action: {
                    self.mode.toggle()
                    bl_broadcast.stopAll()
                }) {
                    Text("Go Offline")
                        .font(.title)
                        .foregroundColor(Color.red)
                }
            }
            List(viewModel.items, id: \.self) { conn in
                VStack{
                    Text(conn.uuid).font(.subheadline)
                    Text("Seen: " + conn.time)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
