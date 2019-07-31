//
//  DetailViewController.swift
//  ApplePaySwag
//
//  Created by Erik.Kerber on 10/17/14.
//  Edited by Eric Cerney on 11/21/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import UIKit
import PassKit

class BuySwagViewController: UIViewController {

    let SupportedPaymentNetworks = [PKPaymentNetwork.visa, PKPaymentNetwork.masterCard, PKPaymentNetwork.amex]
    let ApplePaySwagMerchantID = "merchant.com.charitableimpulse.ChimpProto"//"<TODO - Your merchant ID>" // This should be <your> merchant ID

    @IBOutlet weak var applePayButton: UIButton!
    @IBOutlet weak var swagPriceLabel: UILabel!
    @IBOutlet weak var swagTitleLabel: UILabel!
    @IBOutlet weak var swagImage: UIImageView!
    
    var swag: Swag! {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {

        if (!self.isViewLoaded) {
            return
        }
        
        self.title = swag.title
        self.swagPriceLabel.text = "$" + swag.priceString
        self.swagImage.image = swag.image
        self.swagTitleLabel.text = swag.description
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applePayButton.isHidden = !PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: SupportedPaymentNetworks)
        self.configureView()
    }

    @IBAction func purchase(sender: AnyObject) {
        
        let request = PKPaymentRequest()
        request.merchantIdentifier = ApplePaySwagMerchantID
        request.supportedNetworks = SupportedPaymentNetworks
        request.merchantCapabilities = PKMerchantCapability.capability3DS
        request.countryCode = "US"
        request.currencyCode = "USD"
        
        request.paymentSummaryItems = calculateSummaryItemsFromSwag(swag: swag)
        
        switch (swag.swagType) {
        case .Delivered:
            request.requiredShippingAddressFields = PKAddressField.postalAddress
        case .Electronic:
            request.requiredShippingAddressFields = PKAddressField.email
        }
        request.requiredShippingAddressFields = PKAddressField.all

        switch (swag.swagType) {
        case .Delivered(let method):
            var shippingMethods = [PKShippingMethod]()
            
            for shippingMethod in ShippingMethod.ShippingMethodOptions {
                let method = PKShippingMethod(label: shippingMethod.title, amount: shippingMethod.price)
                method.identifier = shippingMethod.title
                method.detail = shippingMethod.description
                shippingMethods.append(method)
            }
            
            request.shippingMethods = shippingMethods
        case .Electronic:
            break
        }
        
        let applePayController = PKPaymentAuthorizationViewController(paymentRequest: request)
        applePayController?.delegate = self
        present((applePayController ?? nil)!, animated: true, completion: nil)
    }
    
    func calculateSummaryItemsFromSwag(swag: Swag) -> [PKPaymentSummaryItem] {
        var summaryItems = [PKPaymentSummaryItem]()
        summaryItems.append(PKPaymentSummaryItem(label: swag.title, amount: swag.price))
        
        switch (swag.swagType) {
        case .Delivered(let method):
            summaryItems.append(PKPaymentSummaryItem(label: "Shipping", amount: method.price))
        case .Electronic:
            break
        }
        
        summaryItems.append(PKPaymentSummaryItem(label: "Razeware", amount: swag.total()))

        return summaryItems
    }
}

extension BuySwagViewController: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController!, didAuthorizePayment payment: PKPayment!, completion: ((PKPaymentAuthorizationStatus) -> Void)!) {

        // 1
        let shippingAddress = self.createShippingAddressFromRef(address: payment.shippingAddress)

        // 2
        Stripe.setDefaultPublishableKey("pk_test_cfn382rPs5hlZdupsVj6Q5ur")
        
        // 3
        STPAPIClient.shared().createToken(with: payment) {
            (token, error) -> Void in
            
            if (error != nil) {
                print(error.debugDescription)
                completion(PKPaymentAuthorizationStatus.failure)
                return
            }
            
            print(token.debugDescription)
            
            // 4
            let shippingAddress = self.createShippingAddressFromRef(address: payment.shippingAddress)
            
            // 5
            let url = NSURL(string: "http://<your ip address>:5000/pay")
            let request = NSMutableURLRequest(url: url! as URL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            // 6
            let body = ["stripeToken": token?.tokenId ?? nil,
                        "amount": self.swag.total().multiplying(by: NSDecimalNumber(string: "100")),
                        "description": self.swag.title,
                        "shipping": [
                            "city": shippingAddress.City!,
                            "state": shippingAddress.State!,
                            "zip": shippingAddress.Zip!,
                            "firstName": shippingAddress.FirstName!,
                            "lastName": shippingAddress.LastName!]
                ] as [String : Any]
            
            var error: NSError?
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions())
            
            // 7
            NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue.main) { (response, data, error) -> Void in
                if (error != nil) {
                    completion(PKPaymentAuthorizationStatus.failure)
                } else {
                    completion(PKPaymentAuthorizationStatus.success)
                }
            }
        }
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        print("-----------------")
        print(payment.debugDescription)
        print("token---- \(payment.token)")
        controller.dismiss(animated: true, completion: nil)
        
        
        
        let shippingAddress = self.createShippingAddressFromRef(address: payment.shippingAddress)
        
        // 2
        Stripe.setDefaultPublishableKey("pk_test_cfn382rPs5hlZdupsVj6Q5ur")
        
        // 3
        STPAPIClient.shared().createToken(with: payment) {
            (token, error) -> Void in
            
            if (error != nil) {
                print(error.debugDescription)
                completion(PKPaymentAuthorizationStatus.failure)
                return
            }
            
            print(token.debugDescription)
            
            // 4
            let shippingAddress = self.createShippingAddressFromRef(address: payment.shippingAddress)
            
            // 5
            let url = NSURL(string: "http://<your ip address>:5000/pay")
            let request = NSMutableURLRequest(url: url! as URL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            // 6
            let body = ["stripeToken": token?.tokenId ?? nil,
                        "amount": self.swag.total().multiplying(by: NSDecimalNumber(string: "100")),
                        "description": self.swag.title,
                        "shipping": [
                            "city": shippingAddress.City!,
                            "state": shippingAddress.State!,
                            "zip": shippingAddress.Zip!,
                            "firstName": shippingAddress.FirstName!,
                            "lastName": shippingAddress.LastName!]
                ] as [String : Any]
            
            var error: NSError?
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions())
            
            // 7
            NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue.main) { (response, data, error) -> Void in
                if (error != nil) {
                    completion(PKPaymentAuthorizationStatus.failure)
                } else {
                    completion(PKPaymentAuthorizationStatus.success)
                }
            }
        }
        
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func createShippingAddressFromRef(address: ABRecord!) -> Address {
        var shippingAddress: Address = Address()
        
        shippingAddress.FirstName = ABRecordCopyValue(address, kABPersonFirstNameProperty)?.takeRetainedValue() as? String
        shippingAddress.LastName = ABRecordCopyValue(address, kABPersonLastNameProperty)?.takeRetainedValue() as? String
        
        let addressProperty : ABMultiValue = ABRecordCopyValue(address, kABPersonAddressProperty).takeUnretainedValue() as ABMultiValue
        if let dict : NSDictionary = ABMultiValueCopyValueAtIndex(addressProperty, 0).takeUnretainedValue() as? NSDictionary {
            shippingAddress.Street = dict[String(kABPersonAddressStreetKey)] as? String
            shippingAddress.City = dict[String(kABPersonAddressCityKey)] as? String
            shippingAddress.State = dict[String(kABPersonAddressStateKey)] as? String
            shippingAddress.Zip = dict[String(kABPersonAddressZIPKey)] as? String
        }
        
        return shippingAddress
    }
    
    private func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController!, didSelectShippingAddress address: ABRecord!, completion: ((PKPaymentAuthorizationStatus, [AnyObject]?, [AnyObject]?) -> Void)!) {
        let shippingAddress = createShippingAddressFromRef(address: address)
        
        switch (shippingAddress.State, shippingAddress.City, shippingAddress.Zip) {
        case (.some(let state), .some(let city), .some(let zip)):
            completion(.success, nil, nil)
        default:
            completion(.invalidShippingPostalAddress, nil, nil)
        }
    }
    
    private func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController!, didSelectShippingMethod shippingMethod: PKShippingMethod!, completion: ((PKPaymentAuthorizationStatus, [AnyObject]?) -> Void)!) {
        let shippingMethod = ShippingMethod.ShippingMethodOptions.filter {(method) in method.title == shippingMethod.identifier}.first!
        swag.swagType = SwagType.Delivered(method: shippingMethod)
        completion(PKPaymentAuthorizationStatus.success, calculateSummaryItemsFromSwag(swag: swag))
    }
}

