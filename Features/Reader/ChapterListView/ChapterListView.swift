//
//  ChapterListView.swift
//  Hoshi Reader
//
//  Copyright © 2026 Manhhao.
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import EPUBKit

struct ChapterListView: View {
    let document: EPUBDocument
    let bookInfo: BookInfo
    let currentIndex: Int
    let currentCharacter: Int
    let coverURL: URL?
    let onSelect: (Int) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var viewModel: ChapterListViewModel?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView(
                    title: document.title,
                    currentCharacterCount: currentCharacter,
                    totalCharacterCount: bookInfo.characterCount,
                    coverURL: coverURL
                )
                
                List {
                    if let vm = viewModel {
                        ForEach(vm.rows) { row in
                            ChapterView(row: row) {
                                onSelect(row.spineIndex)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ChapterListViewModel(
                        document: document,
                        bookInfo: bookInfo,
                        currentIndex: currentIndex
                    )
                }
            }
            .navigationTitle("Chapters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

struct HeaderView: View {
    let title: String?
    let currentCharacterCount: Int
    let totalCharacterCount: Int
    let coverURL: URL?
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: coverURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color.secondary.opacity(0.2))
            }
            .frame(width: 50, height: 75)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title ?? "")
                    .font(.headline)
                    .lineLimit(2)
                
                let percent = totalCharacterCount > 0 ? (Double(currentCharacterCount) / Double(totalCharacterCount) * 100) : 0
                Text("\(currentCharacterCount) / \(totalCharacterCount) (\(String(format: "%.1f%%", percent)))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }
}

struct ChapterView: View {
    let row: ChapterRow
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Text(row.label)
                
                Spacer()
                
                if let count = row.characterCount {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(row.isCurrent ? Color(uiColor: .systemGray5) : nil)
    }
}
