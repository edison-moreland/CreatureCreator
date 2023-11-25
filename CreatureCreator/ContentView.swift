//
//  ContentView.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/24/23.
//

import SwiftUI

struct ContentView: View {
    @State var count = UInt64(0)
    @State var counter = Counter()
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button(action: {
                count = counter.next()
            }, label: {
                Text("Press me!")
            })
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
