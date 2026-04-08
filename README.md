# Georgia TB Reference Guide iOS App

This repository contains the iOS application for the Georgia TB Reference Guide, developed for the Georgia Department of Public Health. The app serves as a comprehensive resource for Tuberculosis Management guidelines in the state of Georgia.

## Overview

The Georgia TB Reference Guide App is a mobile application designed to provide healthcare professionals and TB coordinators with easy access to up-to-date information about tuberculosis management guidelines. The app includes various features to enhance user experience and facilitate quick access to critical information.

This app has been featured in the following publication:

- Armistead B, Arconada Y, Hochberg NS, Ray SM, Anderson EJ (2023) Development of a mobile application to support tuberculosis care in Georgia, USA. PLOS ONE 18(8): e0298758. https://doi.org/10.1371/journal.pone.0298758

## Features

- **Updated TB Management Guidelines**: Comprehensive and current information on tuberculosis management protocols
- **TB Coordinator Directory**: Complete list of TB Coordinators across the state of Georgia
- **Personalized Features**:
  - Note-taking capabilities
  - Bookmark important sections
  - Content sharing functionality

## Installation

The app is available on the iOS App Store: [Georgia TB Reference Guide](https://apps.apple.com/us/app/georgia-tb-reference-guide/id1583294462)

## Usage

After installation, users can:

1. Access TB management guidelines
2. Look up contact information for TB Coordinators
3. Create and save personal notes
4. Bookmark frequently accessed sections
5. Share content with colleagues

## Project Structure

- `GA-TB-Reference-Guide/AppDelegate`: App lifecycle and global service setup
- `GA-TB-Reference-Guide/Managers`: Data access, persistence, theming, and remote configuration helpers
- `GA-TB-Reference-Guide/ViewControllers`: Screen-level controllers and navigation flows
- `GA-TB-Reference-Guide/Views`: Reusable UI components and custom table cells
- `GA-TB-Reference-Guide/Extensions`: Convenience extensions for UIKit types
- `GA-TB-Reference-Guide/html-content`: Embedded static reference content

## Content Updates (Chapters, Subchapters, Charts)

All chapter/subchapter/chart ordering and labels are centralized in `GA-TB-Reference-Guide/json/chapterIndex.swift`. Keep the arrays aligned by index and update all related lists together.

### Add a Chapter

1. Add the chapter HTML file in `GA-TB-Reference-Guide/html-content` or `GA-TB-Reference-Guide/Content-html` with a new, unique slug (lowercase, underscores, parentheses as needed).
2. In `GA-TB-Reference-Guide/json/chapterIndex.swift`, append the new chapter title to `chapters` and its URL slug to `chapterURLs` at the same index.
3. Add a new entry to `chapterNested` containing the subchapter titles for this chapter. If the chapter has no subchapters, use a single-item array with the chapter title.
4. Add matching slug entries to `chapterCode` in the same shape as `chapterNested` (one slug per subchapter).
5. Update `chaptermapsubchapter` and `chaptermapsubchapternested` to include the new chapter title and its nested labels in the same order as `chapterNested`.

### Add a Subchapter

1. Add the subchapter HTML file with a new slug that follows the existing naming pattern:
   `chapter_slug__a__subchapter_slug`.
2. In `GA-TB-Reference-Guide/json/chapterIndex.swift`, locate the parent chapter in `chapterNested` and append the new subchapter title in the correct position (e.g., `a.`, `b.`, `c.`).
3. Add the matching slug to the same chapter entry in `chapterCode`.
4. Append the subchapter title to `subChapterNames`.
5. Append the parent chapter title to `chaptermapsubchapter`, and the subchapter label (e.g., `b. Title`) to `chaptermapsubchapternested`, maintaining the same ordering as `subChapterNames`.

### Add a Chart (Table/Figure)

1. Add the chart HTML file with a unique slug (e.g., `table_19_some_title`).
2. In `GA-TB-Reference-Guide/json/chapterIndex.swift`, add the chart title and slug to all chart lists: `chartNested` (single-item array), `chartCode` (slug), `chartURLs` (slug), `charts` (full display title), and `chartsTrimmed` (short label like `Table 19` or `Figure 2`).
3. Update `chartmapsubchapter` with the parent chapter title so the chart appears under the correct chapter.
4. Also add the chart title to `chapterNested` and its slug to `chapterCode` within the final “charts” group, keeping the chart ordering consistent with the arrays above.

## Support

For technical support or questions about the app, please contact [Contact Information TBD].

## Acknowledgements

This project is supported by:

- The National Center for Advancing Translational Sciences of the National Institutes of Health under Award Number UL1TR002378. The content is solely the responsibility of the authors and does not necessarily represent the official views of the National Institutes of Health.

- The Georgia Department of Public Health through Contract 40500-046-21203197

## License

[License Information TBD]
