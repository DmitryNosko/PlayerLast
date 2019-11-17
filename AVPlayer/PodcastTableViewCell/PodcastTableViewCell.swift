//
//  VideoPlayerTableViewCell.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 10/23/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import UIKit


class PodcastTableViewCell: UITableViewCell {
    
    private struct Constants {
        static let kFontName = "Futura-Bold"
        static let kEmptyString = ""
    }
    
    var videoTitle: String?
    var videoTitleLabel: UILabel = {
        var textLabel = UILabel()
        textLabel.font = UIFont(name: Constants.kFontName, size: 19)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 0
        return textLabel
    }()
    
    var videoStatus: String?
    var videoStatusLabel: UILabel = {
        var statusLabel = UILabel()
        statusLabel.font = UIFont.boldSystemFont(ofSize: 11)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.numberOfLines = 0
        return statusLabel
    }()
    
    var videoImage: UIImage?
    var videoImageView: UIImageView = {
       var imgView = UIImageView()
        imgView.backgroundColor = UIColor.lightGray
        imgView.layer.cornerRadius = 20
        imgView.clipsToBounds = true
        imgView.translatesAutoresizingMaskIntoConstraints = false
        return imgView
    }()
    
    var item: PodcastItem! {
        didSet {
            videoTitle = item.itemTitle
            videoStatus = item.itemProgressStatus.rawValue
            videoImageView.image = DownloadManager.loadImageUsingURLString(string: item.itemImage)
        }
    }

    override func prepareForReuse() {
        self.videoTitleLabel.text = Constants.kEmptyString
        self.videoStatusLabel.text = Constants.kEmptyString
        self.videoImageView.image = nil
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(videoImageView)
        self.addSubview(videoStatusLabel)
        self.addSubview(videoTitleLabel)
        setUpViewsConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let title = videoTitle {
            videoTitleLabel.text = title
        }
        if let status = videoStatus {
            videoStatusLabel.text = status
        }
        if let image = videoImage {
            videoImageView.image = image
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(FATAL_ERROR_MESSAGE)
    }
    
    func setUpViewsConstraints() -> Void {
        videoStatusLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        videoStatusLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
        
        videoImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 20).isActive = true
        videoImageView.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
        videoImageView.topAnchor.constraint(equalTo: topAnchor, constant: 19).isActive = true
        videoImageView.bottomAnchor.constraint(equalTo: videoTitleLabel.topAnchor, constant: -5).isActive = true
        videoImageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        videoTitleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 20).isActive = true
        videoTitleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
        videoTitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
    }

}

