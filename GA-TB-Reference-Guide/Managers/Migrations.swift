//
//  Migrations.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 2/10/26.
//

import Foundation
import RealmSwift

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

// BookmarksMigration centralizes related app data or service logic.
struct BookmarksMigration {
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

// NotesMigration centralizes related app data or service logic.
struct NotesMigration {
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
