//
//  Migrations.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 2/10/26.
//

import Foundation
import RealmSwift

// MARK: - Migration Documentation
//
// This file contains migration logic for handling URL slug changes and content reorganization
// in the Georgia TB Reference Guide iOS app. When HTML content files are renamed, reorganized,
// or their URL structure changes, existing user data (bookmarks and notes) must be migrated
// to maintain data integrity and user experience.
//
// ## Key Components:
//
// ### Helper Functions:
// - `normalizedSlug(from:)`: Extracts clean URL slugs from file paths, removing fragments and extensions
// - `mappedTitles(for:chapterIndex:)`: Maps slugs to their corresponding titles and navigation titles
//
// ### Migration Structs:
// - `BookmarksMigration`: Handles migration of user bookmarks when content URLs change
// - `NotesMigration`: Handles migration of user notes when content URLs change
//
// ## Migration Process:
//
// When content files are renamed or reorganized:
// 1. The migration system identifies old slugs that need updating
// 2. It maps old slugs to new slugs using the ChapterIndex data
// 3. User bookmarks and notes are updated to point to the new URLs
// 4. Content titles and navigation information are refreshed
//
// ## Usage:
//
// Call these migration methods during app startup or after content updates:
// ```swift
// let realm = try Realm()
// BookmarksMigration.migrateBookmarksForDeletedSlugs(in: realm)
// NotesMigration.migrateNotesForDeletedSlugs(in: realm)
// ```
//
// ## Important Notes:
//
// - Always ensure ChapterIndex data is up-to-date before running migrations
// - Migrations are designed to be idempotent - they can be run multiple times safely
// - The system preserves user data integrity during URL structure changes
// - Error handling is included to prevent crashes during migration failures

// MARK: - Helper Functions

/// Extracts a clean URL slug from a file path or URL string
/// 
/// This function processes raw URL strings to extract the essential slug identifier:
/// - Removes whitespace and newlines
/// - Strips URL fragments (everything after #)
/// - Extracts the last path component
/// - Removes file extensions
/// 
/// - Parameter value: The raw URL string or file path
/// - Returns: A clean slug string suitable for content identification
/// 
/// ## Examples:
/// ```swift
/// normalizedSlug(from: "pages/chapter_1.html#section2") // Returns "chapter_1"
/// normalizedSlug(from: "  table_5_interpretation.html  ") // Returns "table_5_interpretation"
/// normalizedSlug(from: "content/overview") // Returns "overview"
/// ```
private func normalizedSlug(from value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return "" }

    let noFragment = trimmed.components(separatedBy: "#").first ?? trimmed
    let lastPath = (noFragment as NSString).lastPathComponent
    let withoutExt = (lastPath as NSString).deletingPathExtension
    if !withoutExt.isEmpty {
        return withoutExt
    }

    if noFragment.hasSuffix(".html") {
        return String(noFragment.dropLast(5))
    }

    return noFragment
}

/// Maps a content slug to its corresponding display titles
/// 
/// This function searches through the ChapterIndex data structure to find
/// the appropriate titles for a given slug. It handles both chart and chapter content.
/// 
/// - Parameters:
///   - slug: The content slug to look up
///   - chapterIndex: The ChapterIndex instance containing all content mappings
/// - Returns: A tuple containing the full title and navigation title, or nil if not found
/// 
/// ## Search Order:
/// 1. Charts: Searches chartCode array for matching slug
/// 2. Chapters/Subchapters: Searches chapterCode array for matching slug
/// 
/// ## Title Sources:
/// - **Charts**: Full title from chartNested, navigation title from chartsTrimmed
/// - **Chapters**: Full title from chapterNested, navigation title from chaptermapsubchapternested
/// 
/// - Note: Charts are searched first as they have more specific slugs
private func mappedTitles(for slug: String, chapterIndex: ChapterIndex) -> (title: String?, navTitle: String?) {
    let baseSlug = slug.components(separatedBy: "#").first ?? slug

    let chartCodes = Array(chapterIndex.chartCode.joined())
    if let idx = chartCodes.firstIndex(of: baseSlug) {
        let chartNested = Array(chapterIndex.chartNested.joined())
        let title = chartNested.indices.contains(idx) ? chartNested[idx] : nil
        let navTitle = chapterIndex.chartsTrimmed.indices.contains(idx) ? chapterIndex.chartsTrimmed[idx] : nil
        return (title, navTitle)
    }

    let chapterCodes = Array(chapterIndex.chapterCode.joined())
    if let idx = chapterCodes.firstIndex(of: baseSlug) {
        let chapterNested = Array(chapterIndex.chapterNested.joined())
        let title = chapterNested.indices.contains(idx) ? chapterNested[idx] : nil
        let navTitle = chapterIndex.chaptermapsubchapternested.indices.contains(idx) ? chapterIndex.chaptermapsubchapternested[idx] : nil
        return (title, navTitle)
    }

    return (nil, nil)
}

// MARK: - BookmarksMigration

/// Handles migration of user bookmarks when content URLs change
/// 
/// This struct provides functionality to migrate user bookmarks when HTML content files
/// are renamed, reorganized, or their URL structure changes. The migration process:
/// 1. Identifies bookmarks pointing to old/deleted slugs
/// 2. Maps old slugs to new slugs using ChapterIndex data
/// 3. Updates or creates ContentPage objects with new URLs
/// 4. Preserves bookmark status and custom names
/// 5. Cleans up old bookmark references
/// 
/// ## Migration Behavior:
/// - **Existing target**: Updates the existing ContentPage with new titles if needed
/// - **New target**: Creates a new ContentPage with mapped titles
/// - **Bookmark name**: Preserves custom names, falls back to mapped title or original name
/// - **Idempotent**: Safe to run multiple times without side effects
/// 
/// ## Usage:
/// ```swift
/// let realm = try Realm()
/// BookmarksMigration.migrateBookmarksForDeletedSlugs(in: realm)
/// ```
/// 
/// - Note: This should be called during app startup or after content updates
struct BookmarksMigration {
    /// Migrates bookmarks for content with changed URLs
    /// 
    /// - Parameter realm: The Realm database instance to perform migrations in
    static func migrateBookmarksForDeletedSlugs(in realm: Realm) {
        let chapterIndex = ChapterIndex()
        let favorites = realm.objects(ContentPage.self).filter("favorite == true")
        if favorites.isEmpty { return }

        do {
            try realm.write {
                for page in favorites {
                    let baseSlug = normalizedSlug(from: page.url)
                    if baseSlug.isEmpty { continue }

                    let mappedSlug = resolvedSlug(for: baseSlug)
                    if mappedSlug == baseSlug { continue }

                    let mappedTitleResult = mappedTitles(for: mappedSlug, chapterIndex: chapterIndex)
                    let targetContent: ContentPage = {
                        if let existing = realm.object(ofType: ContentPage.self, forPrimaryKey: mappedSlug) {
                            if existing.name.isEmpty, let title = mappedTitleResult.title {
                                existing.name = title
                            }
                            if existing.chapterParent.isEmpty, let navTitle = mappedTitleResult.navTitle {
                                existing.chapterParent = navTitle
                            }
                            return existing
                        }

                        let created = ContentPage()
                        created.url = mappedSlug
                        if let title = mappedTitleResult.title { created.name = title }
                        if let navTitle = mappedTitleResult.navTitle { created.chapterParent = navTitle }
                        realm.add(created, update: .modified)
                        return created
                    }()

                    let favoriteNameToUse: String = {
                        let trimmed = page.favoriteName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { return trimmed }
                        if let title = mappedTitleResult.title { return title }
                        return page.name
                    }()

                    targetContent.favorite = true
                    targetContent.favoriteName = favoriteNameToUse

                    page.favorite = false
                    page.favoriteName = ""
                }
            }
        } catch {
            print("Error migrating bookmarks for deleted slugs: \(error.localizedDescription)")
        }
    }
}

// MARK: - NotesMigration

/// Handles migration of user notes when content URLs change
/// 
/// This struct provides functionality to migrate user notes when HTML content files
/// are renamed, reorganized, or their URL structure changes. The migration process:
/// 1. Identifies notes attached to pages with old/deleted slugs
/// 2. Maps old slugs to new slugs using ChapterIndex data
/// 3. Updates note URLs and titles to point to new content
/// 4. Moves notes between ContentPage objects as needed
/// 5. Handles both page-attached notes and standalone notes
/// 
/// ## Migration Behavior:
/// - **Page notes**: Notes attached to ContentPage objects are moved to target pages
/// - **Standalone notes**: Notes with their own URL references are updated in-place
/// - **Title updates**: Note titles are refreshed with mapped content titles
/// - **Relationship preservation**: Maintains note-to-page relationships
/// 
/// ## Usage:
/// ```swift
/// let realm = try Realm()
/// NotesMigration.migrateNotesForDeletedSlugs(in: realm)
/// ```
/// 
/// - Note: This should be called during app startup or after content updates
/// - Important: Run this after BookmarksMigration to ensure target pages exist
struct NotesMigration {
    /// Migrates notes for content with changed URLs
    /// 
    /// - Parameter realm: The Realm database instance to perform migrations in
    static func migrateNotesForDeletedSlugs(in realm: Realm) {
        let chapterIndex = ChapterIndex()
        let pages = realm.objects(ContentPage.self)
        let notes = realm.objects(Notes.self)
        if pages.isEmpty && notes.isEmpty { return }

        do {
            try realm.write {
                for page in pages {
                    let baseSlug = normalizedSlug(from: page.url)
                    if baseSlug.isEmpty { continue }

                    let mappedSlug = resolvedSlug(for: baseSlug)
                    if mappedSlug == baseSlug { continue }

                    let mappedTitleResult = mappedTitles(for: mappedSlug, chapterIndex: chapterIndex)

                    let targetContent: ContentPage = {
                        if let existing = realm.object(ofType: ContentPage.self, forPrimaryKey: mappedSlug) {
                            if existing.name.isEmpty, let title = mappedTitleResult.title {
                                existing.name = title
                            }
                            if existing.chapterParent.isEmpty, let navTitle = mappedTitleResult.navTitle {
                                existing.chapterParent = navTitle
                            }
                            return existing
                        }

                        let created = ContentPage()
                        created.url = mappedSlug
                        if let title = mappedTitleResult.title { created.name = title }
                        if let navTitle = mappedTitleResult.navTitle { created.chapterParent = navTitle }
                        realm.add(created, update: .modified)
                        return created
                    }()

                    let notesToMove = Array(page.notes)
                    for note in notesToMove {
                        note.subChapterURL = mappedSlug
                        if let title = mappedTitleResult.title, !title.isEmpty {
                            note.subChapterName = title
                        }
                        if !targetContent.notes.contains(where: { $0.id == note.id }) {
                            targetContent.notes.append(note)
                        }
                    }

                    if !notesToMove.isEmpty {
                        page.notes.removeAll()
                    }
                }

                for note in notes {
                    let baseSlug = normalizedSlug(from: note.subChapterURL)
                    if baseSlug.isEmpty { continue }

                    let mappedSlug = resolvedSlug(for: baseSlug)
                    if mappedSlug == baseSlug { continue }

                    let mappedTitleResult = mappedTitles(for: mappedSlug, chapterIndex: chapterIndex)
                    note.subChapterURL = mappedSlug
                    if let title = mappedTitleResult.title, !title.isEmpty {
                        note.subChapterName = title
                    }
                }
            }
        } catch {
            print("Error migrating notes for deleted slugs: \(error.localizedDescription)")
        }
    }
}
