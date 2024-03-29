//
//  AnnounceDetailedViewUikit.swift
//  CoordinatorProject
//
//  Created by Benjamin Szakal on 03/01/23.
//
import Combine
import SDWebImage
import UIKit

protocol AnnounceDetailViewDelegate: AnyObject {
    var isLoggedIn: Bool {get}
    var showLoginView: ()->Void {get}
    func showChatView(announceId: String, otherUser: UserProfile, currentUser: UserProfile)
    func showAnnounceDetailView(announce: Announce)
}

extension AnnounceDetailViewDelegate{
    func getAnnounceDetailViewVC(announce: Announce)->UIViewController{
        let vc = AnnounceDetailedViewUikit(announce: announce)
        vc.delegate = self
        return vc
    }
}

class AnnounceDetailedViewUikit: UIViewController {

    
    
    @IBOutlet weak var topImage: UIImageView!
    @IBOutlet weak var userProfilePicture: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var announceUserName: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var deliveryLabel: UILabel!
    
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var mainStackView: UIStackView!
    
    private var imageDisplayed: Int = 0
    
    let announce: Announce
    let announceDetailedVM = AnnounceDetailedVM()
    
    weak var delegate: AnnounceDetailViewDelegate?
    
    var cancellables = Set<AnyCancellable>()
    
    init(announce: Announce){
        self.announce = announce
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollview.contentInsetAdjustmentBehavior = .never

        //set up swipe gesture to change photo and the photo indicator at the bottom
        setUpSwipeGesture()
        setUpPhotoIndicator()
        
        //for the VM to fetch data
        announceDetailedVM.isAFavourite(announce: announce)
        announceDetailedVM.getUserDetailsForAnnounce(announce: announce)
        announceDetailedVM.getCurrentUserDetails()
        
        //fill view labels, images and HeartView
        suscribeToIsAFavourite()
        fillLabelsAnnounceDetails()

    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        var insets = view.safeAreaInsets
        insets.top = 0
        scrollview.contentInset = insets
    }
    
    func fillLabelsAnnounceDetails(){
        
        topImage.sd_setImage(with: URL(string: announce.imageRefs[0]), placeholderImage: UIImage(systemName: "camera"))
        
        titleLabel.text = announce.title
        priceLabel.text = String(announce.price) + "€"
        dateLabel.text = announce.lastUpdatedAt?.formatted(date: .abbreviated, time: .shortened)
        descriptionLabel.text = announce.description
        conditionLabel.text =  announce.condition
        deliveryLabel.text = announce.deliveryType
        
        announceDetailedVM.$userProfileForAnnounce
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] profile in
                self?.userProfilePicture.sd_setImage(with: URL(string: profile.profilePictureUrlStr), placeholderImage: UIImage(systemName: "camera"))
                self?.announceUserName.text = profile.pseudo
            }
            .store(in: &cancellables)
    }
    
    //MARK: - Swipe gesture for changing picture
        private func setUpSwipeGesture(){
            topImage.isUserInteractionEnabled = true
            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(photoRight))
            swipeRight.direction = .right
            topImage.addGestureRecognizer(swipeRight)
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(photoLeft))
            swipeLeft.direction = .left
            topImage.addGestureRecognizer(swipeLeft)
        }
        
        @objc func photoLeft() {
            if imageDisplayed < announce.imageRefs.count - 1 {
                topImage.sd_setImage(with: URL(string: announce.imageRefs[imageDisplayed + 1]),
                                          placeholderImage: UIImage(systemName: "camera"))
                imageDisplayed += 1
                setUpPhotoIndicator()
            }
     
        }
        @objc func photoRight() {
            if imageDisplayed > 0 {
                topImage.sd_setImage(with: URL(string: announce.imageRefs[imageDisplayed - 1]),
                                          placeholderImage: UIImage(systemName: "camera"))
                imageDisplayed -= 1
                setUpPhotoIndicator()
            }
        }
    
    //MARK: - Photo indicator image (showing which image is curretnly showing)
       private func setUpPhotoIndicator(){
           let photoIndicatorView = topImage.viewWithTag(100)
           photoIndicatorView?.removeFromSuperview()
           
           let horizontalStackview = UIStackView()
           horizontalStackview.distribution = .fillProportionally
           horizontalStackview.axis = .horizontal
           horizontalStackview.spacing = 5
           horizontalStackview.translatesAutoresizingMaskIntoConstraints = false
           horizontalStackview.alignment = .center
           
           for index in 0..<announce.imageRefs.count {
               let indicatorImgView = UIImageView(image: UIImage(systemName: "circle.fill"))
               indicatorImgView.tintColor = .white
               
               
               if index == imageDisplayed {
                   indicatorImgView.heightAnchor.constraint(equalToConstant: CGFloat(10)).isActive = true
                   indicatorImgView.widthAnchor.constraint(equalToConstant: CGFloat(10)).isActive = true
               }else{
                   indicatorImgView.heightAnchor.constraint(equalToConstant: CGFloat(5)).isActive = true
                   indicatorImgView.widthAnchor.constraint(equalToConstant: CGFloat(5)).isActive = true
               }
               
               horizontalStackview.addArrangedSubview(indicatorImgView)
           }
           
           horizontalStackview.tag = 100
           topImage.addSubview(horizontalStackview)
           horizontalStackview.centerXAnchor.constraint(equalTo: topImage.centerXAnchor).isActive = true
           horizontalStackview.bottomAnchor.constraint(equalTo: topImage.bottomAnchor, constant: CGFloat(-10)).isActive = true

       }
    
    //MARK: - Heart Image set up + gesture
        private func setUpHeartView(){
            let previousheartView = topImage.viewWithTag(1)
            previousheartView?.removeFromSuperview()
            
            var imageHeart = UIImage()
            if announceDetailedVM.isAFavourite{
                imageHeart = UIImage(systemName: "heart.fill")!
            } else {
                imageHeart = UIImage(systemName: "heart")!
            }
            
            let heartView = UIImageView(image: imageHeart)
            heartView.tintColor = .red
            heartView.translatesAutoresizingMaskIntoConstraints = false
            heartView.isUserInteractionEnabled = true
            heartView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:))))
            heartView.tag = 1
            topImage.addSubview(heartView)
            heartView.rightAnchor.constraint(equalTo: topImage.rightAnchor, constant: -50).isActive = true
            heartView.topAnchor.constraint(equalTo: topImage.topAnchor, constant: 100).isActive = true
        }
        
        @objc func imageTapped(_ sender: UITapGestureRecognizer) {
            if delegate!.isLoggedIn{
                announceDetailedVM.AddOrRemoveFromFavourite(announce: announce)
            } else {
                delegate!.showLoginView()
            }
        }
    
    private func suscribeToIsAFavourite(){
        announceDetailedVM.$isAFavourite
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] _ in
                self?.setUpHeartView()
            }

            .store(in: &cancellables)
    }

    @IBAction func messageButtonPressed(_ sender: UIButton) {
        if delegate!.isLoggedIn{
            delegate!.showChatView(announceId: announce.id ?? "", otherUser: announceDetailedVM.userProfileForAnnounce, currentUser: announceDetailedVM.currentUserProfile)
        } else {
            delegate!.showLoginView()
        }
    }
    
    @IBAction func buyButtonPressed(_ sender: UIButton) {
        //TO DO
    }
    
}
