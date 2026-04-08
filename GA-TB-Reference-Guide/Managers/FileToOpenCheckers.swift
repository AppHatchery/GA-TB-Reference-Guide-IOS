//
//  FileToOpenChecker.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 12/02/2025.
//

import Foundation

let chapterIndex = ChapterIndex()

///Helper function to check if a file was downloaded or not, if it exists, route to points to downloaded file
func getFileURL(for filename: String, withExtension fileExtension: String = "html") -> URL {
	let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
	let filePath = documentsPath.appendingPathComponent("\(filename).\(fileExtension)")

	if FileManager.default.fileExists(atPath: filePath.path) {
		print("Loading from Documents: \(filePath)")
		return filePath
	} else {
		return Bundle.main.url(forResource: filename, withExtension: fileExtension)!
	}
}

/// is File Downloaded.
func isFileDownloaded(for filename: String, withExtension fileExtension: String = "html") -> Bool {
	let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
	let filePath = documentsPath.appendingPathComponent("\(filename).\(fileExtension)")

	if filename == "15_appendix_district_tb_coordinators_(by_district)" {
		updateFileIfDownloaded(filename: filename)
	}

	return FileManager.default.fileExists(atPath: filePath.path)
}

@discardableResult
/// is File Deleted.
func isFileDeleted(for filename: String, withExtension fileExtension: String = "html") -> Bool {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let filePath = documentsPath.appendingPathComponent("\(filename).\(fileExtension)")

    /// If it exists in Documents, it's not deleted
    let existsInDocuments = FileManager.default.fileExists(atPath: filePath.path)
    if existsInDocuments {
        return false
    }

    /// If it doesn't exist in Documents but exists in the bundle, treat as deleted (i.e., we will fall back to bundle)
    if Bundle.main.url(forResource: filename, withExtension: fileExtension) != nil {
        return true
    }

    /// Neither in Documents nor in bundle; consider it deleted/missing
    return true
}

/// Returns the correct URL to load for a given file name: prefers Documents if present, falls back to the app bundle.
/// Use this to "proceed to the correct file" after checking for deletion.
func availableFileURL(for filename: String, withExtension fileExtension: String = "html") -> URL {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let filePath = documentsPath.appendingPathComponent("\(filename).\(fileExtension)")

    if FileManager.default.fileExists(atPath: filePath.path) {
        return filePath
    }
    
    /// Keeping this for debugging purposes to LIST all HTML files in bundle
    if let bundleContents = try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath) {
        let htmlFiles = bundleContents.filter { $0.hasSuffix(".html") }
        print("HTML files in bundle: \(htmlFiles)")
    }
    
    let url = Bundle.main.url(forResource: filename, withExtension: fileExtension)
    
    return url! // This will crash if url is nil
}

/// Resolves old content slugs to current file URLs for runtime content access
/// 
/// This function is the runtime counterpart to `resolvedSlug()`, providing actual file URLs
/// for content that has been migrated. It handles the same migration mappings but returns
/// the resolved file URL instead of just the slug.
/// 
/// ## Usage Context:
/// 
/// This function is primarily used in SavedViewController to handle bookmark access:
/// - When users tap on bookmarks that point to old/deleted content
/// - During navigation to ensure content URLs are current
/// - When displaying saved content that may have been reorganized
/// 
/// ## Resolution Process:
/// 
/// 1. **Migration Mapping**: Checks if the slug matches any historical migration patterns
/// 2. **File Location**: Uses `availableFileURL()` to locate the actual file (documents or bundle)
/// 3. **Fallback**: Returns the original slug's URL if no migration is needed
/// 
/// ## SavedViewController Integration:
/// 
/// In SavedViewController.swift, this function is called in two key places:
/// 
/// **1. Bookmark Access (line 279):**
/// ```swift
/// if isFileDeleted(for: slug) {
///     let resolvedFileURL = resolvedURL(for: slug)
///     // Use resolved URL for content access
/// }
/// ```
/// 
/// **2. Navigation Preparation (line 661):**
/// ```swift
/// if isFileDeleted(for: slug) {
///     let resolved = resolvedURL(for: slug)
///     webViewViewController.url = resolved
///     
///     // Extract resolved slug for title mapping
///     let resolvedSlug = resolved.deletingPathExtension().lastPathComponent
///     let mapped = mappedTitles(for: resolvedSlug)
///     // Update display titles with migrated content
/// }
/// ```
/// 
/// ## Migration Synchronization:
/// 
/// This function must be kept in sync with `resolvedSlug()` - both should contain
/// the same migration mappings to ensure consistency between data migration
/// (Migrations.swift) and runtime content access (SavedViewController).
/// 
/// - Parameters:
///   - slug: The original content slug that may need migration
///   - fileExtension: The file extension to use (defaults to "html")
/// - Returns: The URL of the current content file, either migrated or original
/// 
/// - Note: This function handles both bundle and documents directory files
/// - Note: Always test with both downloaded and bundled content
/// - Important: Keep migration mappings identical to resolvedSlug() function
func resolvedURL(for slug: String, withExtension fileExtension: String = "html") -> URL {
    if slug == "table_10_pediatric_dosages_rifampin_in_children_(birth_to_15_years)" || slug == "table_11_pediatric_dosages_ethambutol_in_children_(birth_to_15_years)" || slug == "table_12_pediatric_dosages_pyrazinamide_in_children_(birth_to_15_years)" {
        
        return availableFileURL(for: "table_9_pediatric_dosage_isoniazid_in_children_(birth_to_15_years)")
    } else if slug == "table_13_antituberculosis_antibiotics_in_adult_patients_with_renal_impairment" {
        return availableFileURL(for: "table_10_antituberculosis_antibiotics_in_adult_patients_with_renal_impairment")
    } else if slug == "table_14_antituberculosis_medications_which_may_be_used_for_patients_who_have_contraindications_to_or_intolerance" {
        return availableFileURL(for: "table_11_antituberculosis_medications_which_may_be_used_for_patients_who_have_contraindications_to_or_intolerance")
    } else if slug == "table_15_clinical_situations_for_which_standard_therapy_cannot_be_given_or_is_not_well_tolerated" {
        return availableFileURL(for: "table_12_clinical_situations_for_which_standard_therapy_cannot_be_given_or_is_not_well_tolerated")
    } else if slug == "table_16_when_to_start_hiv_therapy" {
        return availableFileURL(for: "table_13_when_to_start_hiv_therapy")
    } else if slug == "table_17_what_to_start_choice_of_tb_therapy_and_antiretroviral_therapy_(art)_when)treating_co-infected_patients" {
        return availableFileURL(for: "table_14_what_to_start_choice_of_tb_therapy_and_antiretroviral_therapy_(art)_when_treating_co-infected_patients")
    } else if slug == "table_18_dosage_adjustments_for_art_and_rifamycins_when_used_in_combination" {
        return availableFileURL(for: "table_15_summary_of_recommendations_for_treatment_of_active_tb_disease_in_persons_with_hiv")
    } else if slug == "table_18_dosage_adjustments_for_art_and_rifamycins_when_used_in_combination" {
        return availableFileURL(for: "table_15_summary_of_recommendations_for_treatment_of_active_tb_disease_in_persons_with_hiv")
    } else if slug == "table_19_guidelines_for_treatment_of_extrapulmonary_tuberculosis" {
        return availableFileURL(for: "table_16_guidelines_for_treatment_of_extrapulmonary_tuberculosis")
    } else if slug == "table_20_use_of_anti-tb_medications_in_special_situations_pregnancy_tuberculosis_meningitis_and_renal_failure" {
        return availableFileURL(for: "table_17_use_of_anti-tb_medications_in_special_situations_pregnancy_tuberculosis_meningitis_and_renal_failure")
    } else if slug == "table_21_grady_hospital_tb_isolation_policy" {
        return availableFileURL(for: "table_18_grady_hospital_tb_isolation_policy")
    } else if slug == "18_hello_and_welcome_clinical_statement" {
        return availableFileURL(for: "hello_and_welcome_clinical_statement")
    } else if slug == "19_for_more_information" {
        return availableFileURL(for: "18_for_more_information")
    } else if slug == "5_treatment_of_current_(active)_disease_therapy__g__antiretroviral_therapy_(art)_and_treatment_of_persons" {
        return availableFileURL(for: "5_treatment_of_current_(active)_disease_therapy__f__tb_and_hiv")
    } else if slug == "8_tuberculosis_and_long-term_care_facilities" {
        return availableFileURL(for: "8_tuberculosis_and_long_term_care_facilities")
    }
    
    if isFileDownloaded(for: slug, withExtension: fileExtension) {
        let url = getFileURL(for: slug, withExtension: fileExtension)
        return url
    }
    
    if let bundleURL = Bundle.main.url(forResource: slug, withExtension: fileExtension) {
        return bundleURL
    }
    
    return availableFileURL(for: slug, withExtension: fileExtension)
}

/// Resolves old content slugs to their current equivalents for migration purposes
/// 
/// This function is the core of the migration system, mapping historical URL slugs to their
/// current counterparts. When content files are renamed, reorganized, or renumbered,
/// this function ensures that user bookmarks and notes continue to point to the correct content.
/// 
/// ## Migration Categories:
/// 
/// ### Table Renumbering (2024 Content Reorganization):
/// - Pediatric dosage tables (10, 11, 12) consolidated into table 9
/// - All subsequent tables renumbered down by 1 (13 becomes 10, 14 becomes 11, etc.)
/// 
/// ### Chapter Reorganization:
/// - Welcome chapter numbering simplified (18 removed)
/// - Chapter 5 therapy section reorganized from "__g__" to "__f__" designation
/// - Chapter 8 underscore hyphenation standardized
/// 
/// ## Usage:
/// 
/// This function is called by the migration system in Migrations.swift:
/// - `BookmarksMigration.migrateBookmarksForDeletedSlugs()`
/// - `NotesMigration.migrateNotesForDeletedSlugs()`
/// 
/// ## Adding New Migrations:
/// 
/// When adding new content migrations, follow this pattern:
/// ```swift
/// } else if slug == "old_slug_name" {
///     return "new_slug_name"
/// ```
/// 
/// **Important:** Migration paths are cumulative - never remove existing mappings
/// as they are needed for users who may have old data from previous app versions.
/// 
/// - Parameter slug: The original slug that may need migration
/// - Returns: The current slug if migration is needed, or the original slug if no migration is required
/// 
/// - Note: Always test migrations in development before deploying to production
/// - Note: This function should be kept in sync with ChapterIndex data
func resolvedSlug(for slug: String) -> String {
    if slug == "table_10_pediatric_dosages_rifampin_in_children_(birth_to_15_years)" || slug == "table_11_pediatric_dosages_ethambutol_in_children_(birth_to_15_years)" || slug == "table_12_pediatric_dosages_pyrazinamide_in_children_(birth_to_15_years)" {
        
        return "table_9_pediatric_dosage_isoniazid_in_children_(birth_to_15_years)"
    } else if slug == "table_13_antituberculosis_antibiotics_in_adult_patients_with_renal_impairment" {
        return "table_10_antituberculosis_antibiotics_in_adult_patients_with_renal_impairment"
    } else if slug == "table_14_antituberculosis_medications_which_may_be_used_for_patients_who_have_contraindications_to_or_intolerance" {
        return "table_11_antituberculosis_medications_which_may_be_used_for_patients_who_have_contraindications_to_or_intolerance"
    } else if slug == "table_15_clinical_situations_for_which_standard_therapy_cannot_be_given_or_is_not_well_tolerated" {
        return "table_12_clinical_situations_for_which_standard_therapy_cannot_be_given_or_is_not_well_tolerated"
    } else if slug == "table_16_when_to_start_hiv_therapy" {
        return "table_13_when_to_start_hiv_therapy"
    } else if slug == "table_17_what_to_start_choice_of_tb_therapy_and_antiretroviral_therapy_(art)_when)treating_co-infected_patients" {
        return "table_14_what_to_start_choice_of_tb_therapy_and_antiretroviral_therapy_(art)_when_treating_co-infected_patients"
    } else if slug == "table_18_dosage_adjustments_for_art_and_rifamycins_when_used_in_combination" {
        return "table_15_summary_of_recommendations_for_treatment_of_active_tb_disease_in_persons_with_hiv"
    } else if slug == "table_18_dosage_adjustments_for_art_and_rifamycins_when_used_in_combination" {
        return "table_15_summary_of_recommendations_for_treatment_of_active_tb_disease_in_persons_with_hiv"
    } else if slug == "table_19_guidelines_for_treatment_of_extrapulmonary_tuberculosis" {
        return "table_16_guidelines_for_treatment_of_extrapulmonary_tuberculosis"
    } else if slug == "table_20_use_of_anti-tb_medications_in_special_situations_pregnancy_tuberculosis_meningitis_and_renal_failure" {
        return "table_17_use_of_anti-tb_medications_in_special_situations_pregnancy_tuberculosis_meningitis_and_renal_failure"
    } else if slug == "table_21_grady_hospital_tb_isolation_policy" {
        return "table_18_grady_hospital_tb_isolation_policy"
    } else if slug == "18_hello_and_welcome_clinical_statement" {
        return "hello_and_welcome_clinical_statement"
    } else if slug == "19_for_more_information" {
        return "18_for_more_information"
    } else if slug == "5_treatment_of_current_(active)_disease_therapy__g__antiretroviral_therapy_(art)_and_treatment_of_persons" {
        return "5_treatment_of_current_(active)_disease_therapy__f__tb_and_hiv"
    } else if slug == "8_tuberculosis_and_long-term_care_facilities" {
        return "8_tuberculosis_and_long_term_care_facilities"
    }
    
    return slug
}

/// update File If Downloaded.
func updateFileIfDownloaded(filename: String, withExtension fileExtension: String = "html") {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let filePath = documentsPath.appendingPathComponent("\(filename).\(fileExtension)")

    if FileManager.default.fileExists(atPath: filePath.path) {
        do {
            var fileContent = try String(contentsOf: filePath, encoding: .utf8)

            /// Try different ways to locate the SVG file
            if let iconURL = Bundle.main.url(forResource: "ic_title_icon", withExtension: "svg") ??
                              Bundle.main.url(forResource: "ic_title_icon.svg", withExtension: nil) {
                
                let iconPath = iconURL.path
                
                print("Found icon at: \(iconPath)") // Debug print
                
                /// More flexible regex that matches the img tag with class="ic_title_icon"
                let pattern = #"<img[^>]*class="ic_title_icon"[^>]*>"#
                let updatedImgTag = #"<img alt="aut" src="\#(iconPath)" width="50" height="50" class="ic_title_icon">"#
                
                fileContent = fileContent.replacingOccurrences(of: pattern, with: updatedImgTag, options: .regularExpression)

                /// Write the updated content back to the file
                try fileContent.write(to: filePath, atomically: true, encoding: .utf8)
                print("Successfully updated image source")
            } else {
                // List all bundle resources to debug
//                print("Icon file not found in the bundle!")
                if let bundlePath = Bundle.main.resourcePath {
//                    print("Bundle path: \(bundlePath)")
                    // Check if file exists at bundle path
                    let potentialIconPath = "\(bundlePath)/ic_title_icon.svg"
//                    print("Checking: \(potentialIconPath)")
//                    print("Exists: \(FileManager.default.fileExists(atPath: potentialIconPath))")
                }
            }
        } catch {
            print("Error reading or writing file: \(error.localizedDescription)")
        }
    } else {
        print("File \(filename).\(fileExtension) not found!")
    }
}
