//
//  FileLoggerTableViewCell.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

// TODO: Refactor using SwiftUI instead of UIKit
import Foundation
#if canImport(UIKit)
import UIKit

class FileLoggerTableViewCell: UITableViewCell {

    var logFileRecord: LogFileRecord? {
        didSet {
            logHeaderLabel.text = logFileRecord!.header
            logBodyLabel.text = logFileRecord!.body
        }
    }

    private let logHeaderLabel = UILabel()
    private let logBodyLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setup() {
        let vStackView = UIStackView()
        contentView.addSubview(vStackView)

        vStackView.axis = .vertical
        vStackView.spacing = 3.0
        vStackView.translatesAutoresizingMaskIntoConstraints = false

        vStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        vStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        vStackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20).isActive = true
        vStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20).isActive = true

        vStackView.addArrangedSubview(logHeaderLabel)
        vStackView.addArrangedSubview(logBodyLabel)

        logHeaderLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
        logBodyLabel.font = UIFont.systemFont(ofSize: 12.0)
        logBodyLabel.numberOfLines = 0

        if let _logFileRecord = logFileRecord {
            logHeaderLabel.text = _logFileRecord.header
            logBodyLabel.text = _logFileRecord.body
        }

    }
}
#endif
