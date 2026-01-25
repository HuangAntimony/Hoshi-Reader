//
//  BookshelfViewModel.swift
//  Hoshi Reader
//
//  Copyright © 2026 Manhhao.
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import EPUBKit

@Observable
@MainActor
class BookshelfViewModel {
    var books: [BookMetadata] = []
    var isImporting: Bool = false
    var shouldShowError: Bool = false
    var errorMessage: String = ""
    
    private var bookProgress: [UUID: Double] = [:]
    
    init() {
        loadBooks()
    }
    
    func loadBooks() {
        do {
            books = try BookStorage.loadAllBooks()
            loadBookProgress()
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    func sortedBooks(by option: SortOption) -> [BookMetadata] {
        switch option {
        case .recent:
            return books.sorted {
                ($0.lastAccess) > ($1.lastAccess)
            }
        case .title:
            return books.sorted {
                ($0.title ?? "").localizedCompare($1.title ?? "") == .orderedAscending
            }
        }
    }
    
    private func loadBookProgress() {
        guard let directory = try? BookStorage.getBooksDirectory() else {
            return
        }
        
        for book in books {
            guard let folder = book.folder else {
                continue
            }
            let root = directory.appendingPathComponent(folder)
            
            let bookInfo = BookStorage.loadBookInfo(root: root)
            let bookmark = BookStorage.loadBookmark(root: root)
            
            if let total = bookInfo?.characterCount, total > 0,
               let current = bookmark?.characterCount {
                bookProgress[book.id] = Double(current) / Double(total)
            } else {
                bookProgress[book.id] = 0.0
            }
        }
    }
    
    func progress(for book: BookMetadata) -> Double {
        bookProgress[book.id] ?? 0.0
    }
    
    
    func deleteBook(_ book: BookMetadata) {
        do {
            if let folder = book.folder {
                let bookURL = try BookStorage.getBooksDirectory().appendingPathComponent(folder)
                try BookStorage.delete(at: bookURL)
            }
            withAnimation {
                books.removeAll { $0.id == book.id }
            }
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    func importBook(result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            try processImport(sourceURL: url)
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    private func processImport(sourceURL: URL) throws {
        let localURL = try BookStorage.copySecurityScopedFile(from: sourceURL, to: "Books/\(sourceURL.lastPathComponent)")
        let bookFolder = localURL.deletingPathExtension()
        
        do {
            let document = try BookStorage.loadEpub(localURL)
            
            var coverURL: String? = nil
            if let coverPath = findCoverInManifest(document: document) {
                let coverSourceURL = document.contentDirectory.appendingPathComponent(coverPath)
                let coverDestination = "Books/\(bookFolder.lastPathComponent)/\(URL(fileURLWithPath: coverPath).lastPathComponent)"
                try BookStorage.copyFile(from: coverSourceURL, to: coverDestination)
                coverURL = coverDestination
            }

            let metadata = BookMetadata(
                title: document.title,
                cover: coverURL,
                folder: bookFolder.lastPathComponent,
                lastAccess: Date()
            )
            
            let bookinfo = BookProcessor.process(document: document)

            try BookStorage.save(metadata, inside: bookFolder, as: FileNames.metadata)
            try BookStorage.save(bookinfo, inside: bookFolder, as: FileNames.bookinfo)
            try BookStorage.delete(at: localURL)
            
            books = try BookStorage.loadAllBooks()
        } catch {
            try? BookStorage.delete(at: localURL)
            try? BookStorage.delete(at: bookFolder)
            throw error
        }
    }
    
    private func findCoverInManifest(document: EPUBDocument) -> String? {
        if let coverItem = document.manifest.items.values.first(where: { $0.property?.contains("cover-image") == true }) {
            return coverItem.path
        }
        
        let imageTypes: [EPUBMediaType] = [.jpeg, .png, .gif, .svg]
        if let firstImage = document.manifest.items.values.first(where: { imageTypes.contains($0.mediaType) }) {
            return firstImage.path
        }
        
        return nil
    }
    
    private func showError(message: String) {
        errorMessage = message
        shouldShowError = true
    }
}
