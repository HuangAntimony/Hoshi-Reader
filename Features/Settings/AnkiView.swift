//
//  AnkiView.swift
//  Hoshi Reader
//
//  Copyright © 2026 Manhhao.
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

struct AnkiView: View {
    @State private var ankiManager = AnkiManager.shared
    
    var body: some View {
        List {
            Section {
                Button("Fetch decks and models from Anki") { ankiManager.requestInfo() }
            }
            
            if ankiManager.isConnected {
                Section("Settings") {
                    Picker("Deck", selection: $ankiManager.selectedDeck) {
                        ForEach(ankiManager.availableDecks, id: \.self) { deck in
                            Text(deck).tag(deck as String?)
                        }
                    }
                    .onChange(of: ankiManager.selectedDeck) { _, _ in ankiManager.save() }
                    
                    Picker("Model", selection: $ankiManager.selectedNoteType) {
                        ForEach(ankiManager.availableNoteTypes) { noteType in
                            Text(noteType.name).tag(noteType.name as String?)
                        }
                    }
                    .onChange(of: ankiManager.selectedNoteType) { _, _ in ankiManager.save() }
                    
                    Toggle("Allow Duplicates", isOn: $ankiManager.allowDupes)
                        .onChange(of: ankiManager.allowDupes) { _, _ in ankiManager.save() }
                }
            }
            
            if let typeName = ankiManager.selectedNoteType,
               let noteType = ankiManager.availableNoteTypes.first(where: { $0.name == typeName }) {
                Section("Fields") {
                    ForEach(noteType.fields, id: \.self) { field in
                        HStack {
                            Picker(field, selection: Binding(
                                get: { ankiManager.fieldMappings[field] },
                                set: {
                                    if let v = $0 {
                                        ankiManager.fieldMappings[field] = v
                                    }
                                    else {
                                        ankiManager.fieldMappings.removeValue(forKey: field)
                                    }
                                    ankiManager.save()
                                }))
                            {
                                Text("-").tag(nil as Handlebars?)
                                ForEach(Handlebars.allCases, id: \.rawValue) { option in
                                    Text(option.rawValue).tag(option as Handlebars?)
                                }
                            }
                        }
                    }
                    
                    LabeledContent("Tags") {
                        TextField("None", text: $ankiManager.tags)
                            .multilineTextAlignment(.trailing)
                            .submitLabel(.done)
                            .onSubmit {
                                ankiManager.save()
                            }
                    }
                }
            }
        }
        .navigationTitle("Anki")
    }
}
