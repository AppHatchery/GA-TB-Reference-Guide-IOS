//
//  NotesBottomSheetDelegate.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 28/09/2025.
//


import UIKit
import RealmSwift

protocol NotesBottomSheetDelegate: AnyObject {
    func didSelectNote(_ note: Notes)
    func didDeleteNote(_ note: Notes)
}

class NotesBottomSheetViewController: UIViewController {
    
    // MARK: - UI Elements
    private let tableView = UITableView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let dismissButton = UIButton(type: .system)
    private let emptyStateLabel = UILabel()
    
    // MARK: - Properties
    weak var delegate: NotesBottomSheetDelegate?
    var content: ContentPage!
    private let colorTags = [UIColor.black, UIColor.systemRed, UIColor.systemOrange, UIColor.systemYellow, UIColor.systemGreen, UIColor.systemTeal, UIColor.systemBlue, UIColor.systemIndigo, UIColor.systemPurple]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        updateEmptyState()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .colorBackground
        
        // Setup header view
        headerView.backgroundColor = .colorBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        // Setup title label
        let notesCount = content?.notes.count ?? 0
        titleLabel.text = "Notes (\(notesCount))"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
        titleLabel.textColor = UIColor.label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        // Setup dismiss button
//        dismissButton.setTitle("Done", for: .normal)
//        dismissButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
//        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
//        dismissButton.translatesAutoresizingMaskIntoConstraints = false
//        headerView.addSubview(dismissButton)
        
        // Setup empty state label
        emptyStateLabel.text = "No notes saved"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.textColor = UIColor.secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate(
[
            // Header view
            headerView.topAnchor
                .constraint(
                    equalTo: view.safeAreaLayoutGuide.topAnchor,
                    constant: 29
                ),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            // Title label
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            // Dismiss button
//            dismissButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
//            dismissButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            // Empty state label
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ChapterNoteTableViewCell", bundle: nil), forCellReuseIdentifier: "chapterNote")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorStyle = .none
        tableView.backgroundColor = .colorBackground
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor
                .constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor
                .constraint(equalTo: view.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateEmptyState() {
        let hasNotes = content?.notes.count ?? 0 > 0
        emptyStateLabel.isHidden = hasNotes
        tableView.isHidden = !hasNotes
    }
    
    // MARK: - Actions
    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Public Methods
    func reloadData() {
        tableView.reloadData()
        updateEmptyState()
    }
}

// MARK: - UITableViewDataSource
extension NotesBottomSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content?.notes.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chapterNote", for: indexPath) as! ChapterNoteTableViewCell
        
        guard let notes = content?.notes, indexPath.row < notes.count else {
            return cell
        }
        
        let note = notes[notes.count - 1 - indexPath.row] // Reverse order to show newest first
        
        cell.backgroundColor = UIColor.systemBackground
        cell.header.text = "Note - Last Edited \(note.lastEdited)"
        cell.content.text = note.content
        cell.colorTag.backgroundColor = colorTags[note.colorTag]
        cell.selectionStyle = .none
        
        cell.contentView.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        cell.backgroundColor = .clear
        
        cell.onEditTapped = { [weak self] in
            self?.delegate?.didSelectNote(note)
            self?.dismiss(animated: true)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension NotesBottomSheetViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard let notes = content?.notes, indexPath.row < notes.count else { return }
//        
//        let note = notes[notes.count - 1 - indexPath.row]
//        delegate?.didSelectNote(note)
//        dismiss(animated: true)
//    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let notes = content?.notes, indexPath.row < notes.count else { return }
            
            let note = notes[notes.count - 1 - indexPath.row]
            
            // Delete from Realm through delegate
            delegate?.didDeleteNote(note)
            
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
                self?.updateEmptyState()
            }
        }
    }
}
