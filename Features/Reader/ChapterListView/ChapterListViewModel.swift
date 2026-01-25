//
//  ChapterListViewModel.swift
//  Hoshi Reader
//
//  Copyright © 2026 Manhhao.
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import EPUBKit

struct ChapterRow: Identifiable {
    let id = UUID()
    let label: String
    let spineIndex: Int
    let characterCount: Int?
    let isCurrent: Bool
}

@Observable
@MainActor
class ChapterListViewModel {
    var rows: [ChapterRow] = []
    
    private let document: EPUBDocument
    private let bookInfo: BookInfo
    private let currentIndex: Int
    
    init(document: EPUBDocument, bookInfo: BookInfo, currentIndex: Int) {
        self.document = document
        self.bookInfo = bookInfo
        self.currentIndex = currentIndex
        
        self.rows = generateRows()
    }
    
    private func generateRows() -> [ChapterRow] {
        let rawChapters = document.tableOfContents.subTable ?? []
        var result: [ChapterRow] = []
        var lastTotal: Int? = nil
        
        for item in rawChapters {
            let count = getCharacterCount(for: item)
            
            if count != lastTotal {
                if let index = findSpineIndex(for: item) {
                    let row = ChapterRow(
                        label: item.label,
                        spineIndex: index,
                        characterCount: count,
                        isCurrent: index == currentIndex
                    )
                    result.append(row)
                }
                lastTotal = count
            }
        }
        return result
    }
    
    private func getCharacterCount(for item: EPUBTableOfContents) -> Int? {
        guard let tocPath = item.item else {
            return nil
        }
        let basePath = tocPath.components(separatedBy: "#").first ?? tocPath
        return bookInfo.chapterInfo[basePath]?.currentTotal
    }
    
    private func findSpineIndex(for item: EPUBTableOfContents) -> Int? {
        guard let tocPath = item.item else {
            return nil
        }
        let basePath = tocPath.components(separatedBy: "#").first ?? tocPath
        
        for (index, spineItem) in document.spine.items.enumerated() {
            if let manifestItem = document.manifest.items[spineItem.idref] {
                if manifestItem.path == basePath ||
                    manifestItem.path.hasSuffix(basePath) ||
                    basePath.hasSuffix(manifestItem.path) {
                    return index
                }
            }
        }
        return nil
    }
}
