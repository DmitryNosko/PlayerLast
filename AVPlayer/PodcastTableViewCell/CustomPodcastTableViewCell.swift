//
//  CustomPodcastTableViewCell.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 11/13/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import UIKit

let FATAL_ERROR_MESSAGE = "init(coder:) has not been implemented"

class CustomPodcastTableViewCell: UITableViewCell {
    
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
    
    var videoDescription: String?
    var videoDescriptionLabel: UILabel = {
        var textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 0
        return textLabel
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
            videoDescription = item.itemDescription
            videoImageView.image = DownloadManager.loadImageUsingURLString(string: item.itemImage)
        }
    }
    
    override func prepareForReuse() {
        self.videoTitleLabel.text = Constants.kEmptyString
        self.videoDescriptionLabel.text = Constants.kEmptyString
        self.videoImageView.image = nil
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(videoImageView)
        self.addSubview(videoTitleLabel)
        self.addSubview(videoDescriptionLabel)
        setUpViewsConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let title = videoTitle {
            videoTitleLabel.text = title
        }
        if let image = videoImage {
            videoImageView.image = image
        }
        if let descr = videoDescription {
            videoDescriptionLabel.text = descr
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(FATAL_ERROR_MESSAGE)
    }
    
    func setUpViewsConstraints() -> Void {
        videoTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        videoTitleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 20).isActive = true
        videoTitleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
        
        videoImageView.topAnchor.constraint(equalTo: videoTitleLabel.bottomAnchor, constant: 5).isActive = true
        videoImageView.bottomAnchor.constraint(equalTo: self.videoDescriptionLabel.topAnchor, constant: -5).isActive = true
        videoImageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        videoImageView.widthAnchor.constraint(equalToConstant: 300).isActive = true
        videoImageView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor).isActive = true
        
        videoDescriptionLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20).isActive = true
        videoDescriptionLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -15).isActive = true
        videoDescriptionLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
    }

}
