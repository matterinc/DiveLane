//
//  SendMoneyController.swift
//  Franklin
//
//  Created by Anton Grigorev on 24/01/2019.
//  Copyright © 2019 Matter Inc. All rights reserved.
//

import UIKit
import BlockiesSwift
import SwiftyGif
import EthereumAddress

protocol ModalViewDelegate : class {
    func modalViewBeenDismissed()
    func modalViewAppeared()
}

class SendMoneyController: BasicViewController {
    
    enum TextFieldsTags: Int {
        case amount = 0
        case search = 1
        case address = 2
    }
    
    enum SendingScreenStatus {
        case start
        case searching
        case confirm
        case sending
        case ready
        case saving
    }
    
    @IBOutlet weak var amountTextField: BasicTextField!
    @IBOutlet weak var searchTextField: BasicTextField!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var sendToContactLabel: UILabel!
    @IBOutlet weak var shareLabel: UILabel!
    @IBOutlet weak var mainButton: BasicWhiteButton!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var tableView: BasicTableView!
    @IBOutlet weak var searchStackView: UIStackView!
    @IBOutlet weak var amountStackView: UIStackView!
    @IBOutlet weak var contactStack: UIStackView!
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var contactName: UILabel!
    @IBOutlet weak var contactAddress: UILabel!
    @IBOutlet weak var sendingGif: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var readyIcon: UIImageView!
    @IBOutlet weak var addressTextField: BasicTextField!
    @IBOutlet weak var sendButton: BasicWhiteButton!
    @IBOutlet weak var orEnterAddressLabel: UILabel!
    @IBOutlet weak var sendToLabel: UILabel!
    @IBOutlet weak var addressStackView: UIStackView!
    
    var searchStackOrigin: CGFloat = 0
    weak var delegate: ModalViewDelegate?
    var contactsList: [Contact] = []
    let contactsService = ContactsService()
    var chosenContact: Contact?
    var screenStatus: SendingScreenStatus = .start
    
    private let reuseIdentifier = "ContactTableCell"
    private let sectionInsets = UIEdgeInsets(top: 0,
                                             left: 0,
                                             bottom: 0,
                                             right: 0)
    private let itemsPerRow: CGFloat = 3
    
    weak var animationTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        self.mainSetup()
        self.setupTextFields()
        self.setupTableView()
        //self.setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showStart(animated: false)
        getAllContacts()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setMiddleStackPosition()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        chosenContact = nil
    }
    
    func setMiddleStackPosition() {
        searchStackOrigin = searchStackView.frame.origin.y
    }
    
    func setupTextFields() {
        searchTextField.delegate = self
        amountTextField.delegate = self
        addressTextField.delegate = self
        
        amountTextField.tag = TextFieldsTags.amount.rawValue
        searchTextField.tag = TextFieldsTags.search.rawValue
        addressTextField.tag = TextFieldsTags.address.rawValue
    }
    
    func getAllContacts() {
        do {
            let contacts = try contactsService.getAllContacts()
            updateContactsList(with: contacts)
        } catch {
            updateContactsList(with: [])
        }
    }
    
    func setupTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        let footerView = UIView()
        footerView.backgroundColor = Colors.background
        
        let nibSearch = UINib.init(nibName: reuseIdentifier, bundle: nil)
        self.tableView.register(nibSearch, forCellReuseIdentifier: reuseIdentifier)
        self.contactsList.removeAll()
    }
    
    func mainSetup() {
        setupNavigation()
        setupBackground()
        setupContentView()
        setupGestures()
        setupGif()
    }
    
    func setupNavigation() {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func setupBackground() {
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
    }
    
    func setupContentView() {
        self.contentView.backgroundColor = Colors.background
        self.contentView.alpha = 1
        self.contentView.layer.cornerRadius = Constants.ModalView.ContentView.cornerRadius
        self.contentView.layer.borderColor = Constants.ModalView.ContentView.borderColor
        self.contentView.layer.borderWidth = Constants.ModalView.ContentView.borderWidth
    }
    
    func setupGestures() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                 action: #selector(self.dismissView))
        tap.cancelsTouchesInView = false
        backgroundView.addGestureRecognizer(tap)
        
        let tapOnChosenContact: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showSearch(animated:)))
        tapOnChosenContact.cancelsTouchesInView = false
        contactStack.addGestureRecognizer(tapOnChosenContact)
    }
    
    func setupGif() {
        sendingGif.setGifImage(UIImage(gifName: "loading.gif"))
        sendingGif.loopCount = -1
        sendingGif.contentMode = .center
        sendingGif.isUserInteractionEnabled = false
    }
    
    func setTitle(text: String?, color: UIColor) {
        self.titleLabel.text = text
        self.titleLabel.textColor = color
    }
    
    func setBottomLabel(text: String?, color: UIColor, hidden: Bool) {
        self.shareLabel.text = text
        self.shareLabel.textColor = color
        self.shareLabel.alpha = hidden ? 0 : 1
    }
    
    func setCollectionView(hidden: Bool) {
        self.tableView.alpha = hidden ? 0 : 1
        self.tableView.isUserInteractionEnabled = !hidden
    }
    
    func setBottomButton(text: String?, imageName: String?, backgroundColor: UIColor, textColor: UIColor, hidden: Bool, borderNeeded: Bool) {
        self.mainButton.setTitle(text, for: .normal)
        self.mainButton.changeColorOn(background: backgroundColor, text: textColor)
        self.mainButton.setImage(UIImage(named: imageName ?? ""), for: .normal)
        self.mainButton.layer.borderWidth = borderNeeded ? 1 : 0
        self.mainButton.alpha = hidden ? 0 : 1
        self.mainButton.isUserInteractionEnabled = !hidden
    }
    
    func setTopButton(text: String?, imageName: String?, backgroundColor: UIColor, textColor: UIColor, hidden: Bool, borderNeeded: Bool) {
        self.sendButton.setTitle(text, for: .normal)
        self.sendButton.changeColorOn(background: backgroundColor, text: textColor)
        self.sendButton.setImage(UIImage(named: imageName ?? ""), for: .normal)
        self.sendButton.layer.borderWidth = borderNeeded ? 1 : 0
        self.sendButton.alpha = hidden ? 0 : 1
        self.sendButton.isUserInteractionEnabled = !hidden
    }
    
    func setTopStack(hidden: Bool, interactive: Bool, placeholder: String?, labelText: String?, resetText: Bool = false, keyboardType: UIKeyboardType = .decimalPad) {
        self.amountLabel.text = labelText
        self.amountTextField.placeholder = placeholder
        self.amountStackView.alpha = hidden ? 0 : 1
        self.amountStackView.isUserInteractionEnabled = interactive
        self.amountTextField.keyboardType = keyboardType
        if resetText {
            self.amountTextField.text = nil
        }
    }
    
    func setMiddleStack(hidden: Bool, interactive: Bool, placeholder: String?, labelText: String?, position: CGFloat) {
        self.sendToLabel.text = labelText
        self.searchTextField.placeholder = placeholder
        self.searchStackView.alpha = hidden ? 0 : 1
        self.searchStackView.isUserInteractionEnabled = interactive
        self.searchStackView.frame.origin.y = position
    }
    
    func setBottomStack(hidden: Bool, interactive: Bool, placeholder: String?, labelText: String?) {
        self.orEnterAddressLabel.text = labelText
        self.addressTextField.placeholder = placeholder
        self.addressStackView.alpha = hidden ? 0 : 1
        self.addressStackView.isUserInteractionEnabled = interactive
    }
    
    func setContactStack(hidden: Bool, interactive: Bool, contact: Contact?, labelText: String?) {
        self.sendToContactLabel.text = labelText
        self.chosenContact = contact
        self.contactStack.alpha = hidden ? 0 : 1
        self.contactStack.isUserInteractionEnabled = interactive
        let blockies = Blockies(seed: contact?.address,
                                size: 5,
                                scale: 4,
                                color: Colors.mainGreen,
                                bgColor: Colors.mostLightGray,
                                spotColor: Colors.mainBlue)
        let img = blockies.createImage()
        self.contactImage.image = img
        self.contactImage.layer.cornerRadius = Constants.CollectionCell.Image.cornerRadius
        self.contactImage.clipsToBounds = true
        guard let contactAddress = contact?.address else {
            return
        }
        self.contactAddress.text = contactAddress
        guard let contactName = contact?.name else {
            return
        }
        self.contactName.text = contactName
    }
    
    func setSeparator(hidden: Bool) {
        self.separatorView.alpha = hidden ? 0 : 1
    }
    
    func setReadyIcon(hidden: Bool) {
        self.readyIcon.alpha = hidden ? 0 : 1
        self.readyIcon.transform = hidden ? CGAffineTransform(scaleX: 1, y: 1) : CGAffineTransform(scaleX: 2, y: 2)
    }
    
    func showGif(_ show: Bool) {
        self.sendingGif.alpha = show ? 1 : 0
    }
    
    func showStart(animated: Bool) {
        self.screenStatus = .start
        UIView.animate(withDuration: animated ?
            Constants.ModalView.animationDuration : 0) { [unowned self] in
            self.setTitle(text: "Send money", color: Colors.mainBlue)
            self.showGif(false)
            self.setBottomLabel(text: "Or share via", color: Colors.textLightGray, hidden: false)
            self.setCollectionView(hidden: true)
            self.setBottomButton(text: "Other app...", imageName: "share-blue", backgroundColor: Colors.textWhite, textColor: Colors.mainBlue, hidden: false, borderNeeded: true)
            self.setTopButton(text: "Send", imageName: "send-white", backgroundColor: Colors.orange, textColor: Colors.textWhite, hidden: false, borderNeeded: false)
            self.setTopStack(hidden: false, interactive: true, placeholder: "Amount in USD", labelText: "Amount (USD):")
            self.setMiddleStack(hidden: false, interactive: true, placeholder: "Search by name", labelText: "Send to:", position: self.searchStackOrigin)
            self.setBottomStack(hidden: false, interactive: true, placeholder: "Enter address", labelText: "or enter address:")
            self.setContactStack(hidden: true, interactive: false, contact: nil, labelText: "Send to contact:")
            self.setReadyIcon(hidden: true)
        }
    }
    
    @objc func showSearch(animated: Bool) {
        self.screenStatus = .searching
        UIView.animate(withDuration: Constants.ModalView.animationDuration) { [unowned self] in
            self.setTitle(text: "Send money", color: Colors.mainBlue)
            self.showGif(false)
            self.setBottomLabel(text: "Or share via", color: Colors.textLightGray, hidden: true)
            self.setCollectionView(hidden: false)
            self.setBottomButton(text: "Back", imageName: "left-blue", backgroundColor: Colors.textWhite, textColor: Colors.mainBlue, hidden: false, borderNeeded: true)
            self.setTopButton(text: "Send", imageName: "send-white", backgroundColor: Colors.orange, textColor: Colors.textWhite, hidden: true, borderNeeded: false)
            self.setTopStack(hidden: true, interactive: false, placeholder: "Amount in USD", labelText: "Amount (USD):")
            self.setMiddleStack(hidden: false, interactive: true, placeholder: "Search by name", labelText: "Send to:", position: self.amountStackView.frame.origin.y)
            self.setBottomStack(hidden: true, interactive: false, placeholder: "Enter address", labelText: "or enter address:")
            self.setContactStack(hidden: true, interactive: false, contact: nil, labelText: "Send to contact:")
            self.setReadyIcon(hidden: true)
        }
    }
    
    func showConfirmScreen(animated: Bool, for contact: Contact) {
        self.screenStatus = .confirm
        
        UIView.animate(withDuration: animated ?
            Constants.ModalView.animationDuration : 0) { [unowned self] in
            self.setTitle(text: "Send money", color: Colors.mainBlue)
            self.showGif(false)
            self.setBottomLabel(text: "Or share via", color: Colors.textLightGray, hidden: true)
            self.setCollectionView(hidden: true)
            self.setBottomButton(text: "Send to \(contact.name)", imageName: "ssend-white", backgroundColor: Colors.orange, textColor: Colors.textWhite, hidden: false, borderNeeded: false)
            self.setTopButton(text: "Send", imageName: "send-white", backgroundColor: Colors.orange, textColor: Colors.textWhite, hidden: true, borderNeeded: false)
            self.setTopStack(hidden: false, interactive: true, placeholder: "Amount in USD", labelText: "Amount (USD):")
            self.setMiddleStack(hidden: true, interactive: false, placeholder: "Search by name", labelText: "Send to:", position: self.searchStackOrigin)
            self.setBottomStack(hidden: true, interactive: false, placeholder: "Enter address", labelText: "or enter address:")
            self.setContactStack(hidden: false, interactive: true, contact: contact, labelText: "Send to contact:")
            self.setReadyIcon(hidden: true)
        }
    }
    
    @objc func showSending(animated: Bool) {
        self.screenStatus = .sending
        UIView.animate(withDuration: animated ?
            Constants.ModalView.animationDuration : 0, animations: { [unowned self] in
            self.setTitle(text: "Sending...", color: Colors.mainBlue)
            self.showGif(true)
            self.setBottomLabel(text: "Or share via", color: Colors.textLightGray, hidden: true)
            self.setCollectionView(hidden: true)
            self.setBottomButton(text: nil, imageName: nil, backgroundColor: Colors.orange, textColor: Colors.textWhite, hidden: true, borderNeeded: false)
            self.setTopButton(text: nil, imageName: nil, backgroundColor: Colors.orange, textColor: Colors.textWhite, hidden: true, borderNeeded: false)
            self.setTopStack(hidden: false, interactive: true, placeholder: "Amount in USD", labelText: "Amount (USD):")
            self.setMiddleStack(hidden: true, interactive: false, placeholder: "Search by name", labelText: "Send to:", position: self.searchStackOrigin)
            self.setBottomStack(hidden: true, interactive: false, placeholder: "Enter address", labelText: "or enter address:")
            self.setContactStack(hidden: false, interactive: true, contact: self.chosenContact, labelText: "Send to contact:")
            self.setReadyIcon(hidden: true)
        }) { [unowned self] (completed) in
            if completed {
                self.sending()
            }
        }
    }
    
    func sending() {
        self.animationTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
    }
    
    @objc func fireTimer() {
        animationTimer?.invalidate()
        self.showReady(animated: true)
    }
    
    @objc func showReady(animated: Bool) {
        self.screenStatus = .ready
        guard let contact = self.chosenContact else {return}
        UIView.animate(withDuration: animated ?
            Constants.ModalView.animationDuration : 0) { [unowned self] in
            self.setReadyIcon(hidden: false)
        }
        UIView.animate(withDuration: animated ?
            Constants.ModalView.animationDuration : 0) { [unowned self] in
            self.setTitle(text: "Sent!", color: Colors.mainGreen)
            self.showGif(false)
            self.setBottomLabel(text: "Or share via", color: Colors.textLightGray, hidden: true)
            self.setCollectionView(hidden: true)
            self.setBottomButton(text: "Close", imageName: nil, backgroundColor: Colors.mainBlue, textColor: Colors.textWhite, hidden: false, borderNeeded: true)
            self.setTopButton(text: "Save contact", imageName: "add-contacts", backgroundColor: Colors.textWhite, textColor: Colors.mainBlue, hidden: contact.name == "" ? false : true, borderNeeded: true)
            self.setTopStack(hidden: false, interactive: false, placeholder: "Amount in USD", labelText: "Amount (USD):")
            self.setMiddleStack(hidden: true, interactive: false, placeholder: "Search by name", labelText: "Send to:", position: self.searchStackOrigin)
            self.setBottomStack(hidden: true, interactive: false, placeholder: "Enter address", labelText: "or enter address:")
            self.setContactStack(hidden: false, interactive: false, contact: self.chosenContact, labelText: "Send to contact:")
        }
    }
    
    @objc func showSaving(animated: Bool) {
        self.screenStatus = .saving
        UIView.animate(withDuration: animated ?
            Constants.ModalView.animationDuration : 0) { [unowned self] in
            self.setTitle(text: "Add contact", color: Colors.mainBlue)
            self.showGif(false)
            self.setBottomLabel(text: "Or share via", color: Colors.textLightGray, hidden: true)
            self.setCollectionView(hidden: true)
            self.setBottomButton(text: "Close", imageName: nil, backgroundColor: Colors.textWhite, textColor: Colors.mainBlue, hidden: false, borderNeeded: true)
            self.setTopButton(text: "Save", imageName: "button-save", backgroundColor: Colors.mainGreen, textColor: Colors.textWhite, hidden: false, borderNeeded: false)
            self.setTopStack(hidden: false, interactive: true, placeholder: "Enter name", labelText: "Contact name:", resetText: true, keyboardType: .default)
            self.setMiddleStack(hidden: true, interactive: false, placeholder: "Search by name", labelText: "Send to:", position: self.searchStackOrigin)
            self.setBottomStack(hidden: true, interactive: false, placeholder: "Enter address", labelText: "or enter address:")
            self.setContactStack(hidden: true, interactive: false, contact: self.chosenContact, labelText: "Send to contact:")
            self.setReadyIcon(hidden: true)
        }
    }
    
    @objc func dismissView() {
        self.dismiss(animated: true, completion: nil)
        delegate?.modalViewBeenDismissed()
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        self.dismissView()
    }
    
    @IBAction func buttonAction(_ sender: UIButton) {
        switch screenStatus {
        case .start:
            guard let text = self.amountTextField.text else {
                self.amountTextField.attributedPlaceholder = NSAttributedString(string: "Please, fill this field",
                                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
                return
            }
            guard let amount = Float(text) else {
                self.amountTextField.attributedPlaceholder = NSAttributedString(string: "Please, fill this field",
                                                                       attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
                return
            }
            guard amount > 0 else {
                self.amountTextField.attributedPlaceholder = NSAttributedString(string: "Should be more",
                                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
                return
            }
            
            let stringToShare = "I have sent you a cheque of \(text)"
            
            let itemsToShare = [ stringToShare ]
            let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            // exclude some activity types from the list (optional)
            activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.mail, UIActivity.ActivityType.message, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.markupAsPDF ]
            self.present(activityViewController, animated: true, completion: nil)
        case .searching:
            showStart(animated: true)
        case .confirm:
            guard let text = self.amountTextField.text else {
                self.amountTextField.attributedPlaceholder = NSAttributedString(string: "Please, fill this field",
                                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
                return
            }
            guard let amount = Float(text) else {
                self.amountTextField.attributedPlaceholder = NSAttributedString(string: "Please, fill this field",
                                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
                return
            }
            guard amount > 0 else {
                self.amountTextField.attributedPlaceholder = NSAttributedString(string: "Should be more",
                                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
                return
            }
            showSending(animated: true)
        case .ready:
            self.dismissView()
        case .sending:
            self.dismissView()
        case .saving:
            self.dismissView()
        }
    }
    
    @IBAction func sendToAddress(_ sender: BasicWhiteButton) {
        switch screenStatus {
        case .start:
            guard let text = self.amountTextField.text else {
                self.amountTextField.attributedPlaceholder = NSAttributedString(string: "Please, fill this field",
                                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
                return
            }
            guard let amount = Float(text) else {
                self.amountTextField.attributedPlaceholder = NSAttributedString(string: "Please, fill this field",
                                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
                return
            }
            guard amount > 0 else {
                self.amountTextField.attributedPlaceholder = NSAttributedString(string: "Should be more",
                                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
                return
            }
            guard let address = self.addressTextField.text, !address.isEmpty else {
                self.addressTextField.attributedPlaceholder = NSAttributedString(string: "Please, enter address",
                                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
                return
            }
//            guard let address = EthereumAddress(addressText) else {
//                self.addressTextField.attributedPlaceholder = NSAttributedString(string: "Please, enter correct address",
//                                                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
//                return
//            }
            let contact = Contact(address: address, name: "")
            self.chosenContact = contact
            showSending(animated: true)
        case .ready:
            showSaving(animated: true)
        case .saving:
            guard let text = self.amountTextField.text else {
                self.amountTextField.attributedPlaceholder = NSAttributedString(string: "Please, fill this field",
                                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
                return
            }
            let contact = Contact(address: (self.chosenContact?.address)!, name: text)
            do {
                try contact.saveContact()
                self.dismissView()
            } catch {
                self.dismissView()
            }
        default:
            self.dismissView()
        }
    }
    
    func emptyContactsList() {
        contactsList = []
        DispatchQueue.main.async { [weak self] in
            self?.tableView?.reloadData()
        }
    }
    
    func updateContactsList(with list: [Contact]) {
        DispatchQueue.main.async { [weak self] in
            self?.contactsList = list
            self?.tableView?.reloadData()
        }
    }
    
    func searchContact(string: String) {
        guard let list = try? ContactsService().getFullContactsList(for: string) else {
            self.emptyContactsList()
            return
        }
        self.updateContactsList(with: list)
    }
}

extension SendMoneyController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if contactsList.isEmpty {
            return 0
        } else {
            return contactsList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !contactsList.isEmpty {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                                           for: indexPath) as? ContactTableCell else {
                                                            return UITableViewCell()
            }
            cell.configure(with: contactsList[indexPath.row])
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let contact = contactsList[indexPath.row]
        self.showConfirmScreen(animated: true, for: contact)
    }
}

//extension SendMoneyController: UICollectionViewDelegate, UICollectionViewDataSource {
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 1
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        numberOfItemsInSection section: Int) -> Int {
//        if contactsList.isEmpty {
//            return 0
//        } else {
//            return contactsList.count
//        }
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        if !contactsList.isEmpty {
//            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContactCell",
//                                                                for: indexPath) as? ContactCell else {
//                                                                    return UICollectionViewCell()
//            }
//            cell.configure(with: contactsList[indexPath.row])
//            return cell
//        } else {
//            return UICollectionViewCell()
//        }
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let contact = contactsList[indexPath.row]
//        self.showConfirmScreen(animated: true, for: contact)
//    }
//}
//
//extension SendMoneyController: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView,
//                        layout collectionViewLayout: UICollectionViewLayout,
//                        sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let width = UIScreen.main.bounds.width * Constants.CollectionView.widthCoeff - 15
//
//        return CGSize(width: width, height: Constants.CollectionCell.height)
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        layout collectionViewLayout: UICollectionViewLayout,
//                        insetForSectionAt section: Int) -> UIEdgeInsets {
//        return sectionInsets
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        layout collectionViewLayout: UICollectionViewLayout,
//                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return sectionInsets.left
//    }
//}

extension SendMoneyController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = (textField.text ?? "") as NSString
        let newText = currentText.replacingCharacters(in: range, with: string) as String
        if textField == searchTextField {
            if newText == "" {
                getAllContacts()
            } else {
                let contact = newText
                searchContact(string: contact)
            }
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        print(textField.tag)
        if textField == searchTextField {
            showSearch(animated: true)
        }
        return true
    }
}