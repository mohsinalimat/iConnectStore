//
//  EditFileContentView.swift
//  iConnectStore
//
//  Created by 快游 on 2019/12/5.
//  Copyright © 2019 com.even_cheng. All rights reserved.
//

import Cocoa

class EditFileContentView: NSView {
    
    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var doneButton: NSButton!

    open var fileType:FileType? {
        didSet {
            self.addViews()
        }
    }

    open var submitSuccessAction: (()->(Void))?

    open var edit_profile: Profile?
    open var edit_bundleID: BundleId?
    open var edit_device: Device?
    
    open var bundleIDs: [BundleId]?
    open var devices: [Device]?
    open var certificates: [Certificate]?

    private lazy var editCertificateView: EditCertificateView = {
        
        let editView = self.viewForXIB(class_name: "EditCertificateView") as! EditCertificateView
        return editView
    }()
    
    private lazy var editBundleIDView: EditBundleIDView = {
        
        let editView = self.viewForXIB(class_name: "EditBundleIDView") as! EditBundleIDView
        return editView
    }()
    
    private lazy var editDeviceView: EditDeviceView = {
        
        let editView = self.viewForXIB(class_name: "EditDeviceView") as! EditDeviceView
        return editView
    }()
    
    private lazy var editProfileView: EditProfileView = {
        
        let editView = self.viewForXIB(class_name: "EditProfileView") as! EditProfileView
        return editView
    }()
    
    private func viewForXIB(class_name: String) -> NSView?{
        
        let xib = NSNib.init(nibNamed: class_name, bundle: nil)
        var views: NSArray?
        xib!.instantiate(withOwner: nil, topLevelObjects: &views)
        for view in views! {
            if let editView = view as? NSView {
                return editView
            }
        }
        return nil
    }

        
    //MARK: Functions
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
       
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    private func addViews() {

        switch fileType {
        case .certificate?:
            self.titleField.stringValue = "Add Certificate"
            if self.editCertificateView.superview == nil {
                self.addSubview(self.editCertificateView)
                self.editCertificateView.snp.makeConstraints { (maker) in
                    maker.edges.equalTo(self)
                }
            }
            
        case .bundleId?:
            if self.editBundleIDView.superview == nil {
                self.addSubview(self.editBundleIDView)
                self.editBundleIDView.snp.makeConstraints { (maker) in
                    maker.edges.equalTo(self)
                }
            }
            if self.edit_bundleID == nil {
                self.titleField.stringValue = "Add BundleID"
                self.editBundleIDView.clear()
            } else {
                self.titleField.stringValue = "Modify BundleID"
                self.editBundleIDView.bundleID = self.edit_bundleID
            }
           
        case .device?:
            if self.editDeviceView.superview == nil {
                self.addSubview(self.editDeviceView)
                self.editDeviceView.snp.makeConstraints { (maker) in
                    maker.edges.equalTo(self)
                }
            }
            if self.edit_device == nil {
                self.titleField.stringValue = "Add Device"
                self.editDeviceView.clear()
            } else {
                self.titleField.stringValue = "Modify Device"
                self.editDeviceView.device = self.edit_device
            }

        case .profile?:
            if self.editProfileView.superview == nil {
                self.addSubview(self.editProfileView)
                self.editProfileView.snp.makeConstraints { (maker) in
                    maker.edges.equalTo(self)
                }
            }
            self.editProfileView.devices = self.devices
            self.editProfileView.bundleIDs = self.bundleIDs
            self.editProfileView.certificates = self.certificates
            if self.edit_profile == nil {
                self.titleField.stringValue = "Add Profile"
                self.editProfileView.clear()
            } else {
                self.titleField.stringValue = "Modify Profile"
                self.editProfileView.profile = self.edit_profile
            }
            
        case .none: break
        }
        
        self.editCertificateView.isHidden = (fileType != .certificate)
        self.editBundleIDView.isHidden = (fileType != .bundleId)
        self.editDeviceView.isHidden = (fileType != .device)
        self.editProfileView.isHidden = (fileType != .profile)
    }
    
    @IBAction func CloseAction(_ sender: Any?) {
        self.isHidden = true
        self.edit_bundleID = nil
        self.edit_device = nil
        self.edit_profile = nil
        self.bundleIDs = nil
        self.devices = nil
        self.certificates = nil
        self.editCertificateView.clear()
        self.editBundleIDView.clear()
        self.editDeviceView.clear()
        self.editProfileView.clear()
    }
    
    @IBAction func DoneAction(_ sender: NSButton) {
        
        self.upldateOrCreat { (res) -> (Void) in
            if res == true {
                self.CloseAction(sender)
                if self.submitSuccessAction != nil {
                    self.submitSuccessAction!()
                }
            }
        }
    }
    
    private func upldateOrCreat(complete: @escaping (Bool)->(Void)) {
        
        switch fileType {
        case .certificate?:
            //add cer
            let CSR_path = self.editCertificateView.ChooseCSRField.stringValue
            guard CSR_path.count > 0 else {
                return
            }
            guard let selectTitle = self.editCertificateView.SelectCerTypeButton.selectedItem?.title else {
                return
            }
            ProfileDataManager().creatCertificate(CSRPath: CSR_path, cerType: CertificateType(rawValue: selectTitle)!).done { (cer) in
                complete(true)
            }.catch { (Error) in
                print(Error)
                complete(false)
            }
            
        case .bundleId?:
            
            let bundle_id = self.editBundleIDView.bundleIDField.stringValue
            let name = self.editBundleIDView.nameField.stringValue
            guard let selectPlatform = self.editBundleIDView.platformButton.selectedItem?.title else {
                return
            }
            guard bundle_id.count*name.count > 0 else {return}
            if self.edit_bundleID == nil {
                //add bundleID
                ProfileDataManager().creatBundleId(id: bundle_id, name: name, platform: Platform(rawValue: selectPlatform)!).done { (bundleID) in
                    complete(true)
                }.catch { (Error) in
                    print(Error)
                    complete(false)
                }

            } else {
                guard let bundleID = self.edit_bundleID else {
                    return
                }
                //update bundleID
                ProfileDataManager().updateBundleId(id: bundleID.id, new_name: name).done { (bundleID) in
                    complete(true)
                }.catch { (Error) in
                    print(Error)
                    complete(false)
                }
            }
            
        case .device?:
            let udids = self.editDeviceView.UDIDField.stringValue.components(separatedBy: "&")
            let names = self.editDeviceView.nameField.stringValue.components(separatedBy: "&")
            guard let selectPlatform = self.editDeviceView.platformButton.selectedItem?.title else {
                return
            }
            guard udids.count == names.count && udids.count != 0 else {return}
            if self.edit_device == nil {
                // Add Device
                ProfileDataManager().registerdNewDevices(names:names ,udids: udids, platform: Platform(rawValue: selectPlatform)!).done { (devices) in
                    complete(true)
                }.catch { (Error) in
                    print(Error)
                    complete(false)
                }
                
            } else {
                // update Device
                guard let device = self.edit_device else {
                    return
                }
                //update bundleID
                ProfileDataManager().updateDevice(id: device.id, name: names.first!, status: .enable).done { (device) in
                    complete(true)
                }.catch { (Error) in
                    print(Error)
                    complete(false)
                }
            }
            
        case .profile?:

            // Add Profile
            let name = self.editProfileView.nameField.stringValue
            guard (self.editProfileView.selectBundleButton.selectedItem?.title) != nil else {
                return
            }
            guard let selectProfileType = self.editProfileView.selectProfileTypeButton.selectedItem?.title else {
                return
            }
            guard let selectDevices = self.editProfileView.selectDevices else {
                return
            }
            guard let selectCertificates = self.editProfileView.selectCertificates else {
                return
            }
            guard selectDevices.count*selectCertificates.count != 0 else {return}
            var device_ids: [String] = []
            for device in selectDevices {
                if selectProfileType.hasPrefix("IOS") && device.attributes?.platform == .ios{
                    device_ids.append(device.id)
                } else if selectProfileType.hasPrefix("MAC") && device.attributes?.platform == .macOs{
                    device_ids.append(device.id)
                } else if selectProfileType.hasPrefix("TC") && device.attributes?.platform == .tvOs{
                    device_ids.append(device.id)
                }
            }
            var certificate_ids: [String] = []
            for cer in selectCertificates {
                if selectProfileType.hasPrefix("IOS") && cer.attributes!.certificateType!.rawValue.hasPrefix("IOS"){
                    certificate_ids.append(cer.id)
                } else if selectProfileType.hasPrefix("MAC") && cer.attributes!.certificateType!.rawValue.hasPrefix("MAC"){
                    certificate_ids.append(cer.id)
                }
            }
            let bundle_id = self.bundleIDs![self.editProfileView.selectBundleButton.indexOfSelectedItem].id
            
            if self.edit_device == nil {
                // creatProvisionFile
                ProfileDataManager().creatProvisionFile(name: name, bundleId: bundle_id, profileType:selectProfileType, certificates: certificate_ids, devices: device_ids).done { (devices) in
                    complete(true)
                }.catch { (Error) in
                    print(Error)
                    complete(false)
                }
                
            } else {
                
                ProfileDataManager().deleteProvisionFile(id: self.edit_profile!.id).done { (res) in
                    if res == false {
                        complete(false)
                        return
                    }
                    // creatProvisionFile
                    ProfileDataManager().creatProvisionFile(name: name, bundleId: bundle_id, profileType:selectProfileType, certificates: certificate_ids, devices: device_ids).done { (devices) in
                        complete(true)
                    }.catch { (Error) in
                        print(Error)
                        complete(false)
                    }
                }.catch { (Error) in
                    print(Error)
                    complete(false)
                }
            }
            

        case .none: break
        }
    }
}
