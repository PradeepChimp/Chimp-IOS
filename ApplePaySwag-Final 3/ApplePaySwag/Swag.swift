//
//  Swag.swift
//  ApplePaySwag
//
//  Created by Erik.Kerber on 10/21/14.
//  Edited by Eric Cerney on 11/21/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import UIKit

struct ShippingMethod {
    let price: NSDecimalNumber
    let title: String
    let description: String
    
    init(price: NSDecimalNumber, title: String, description: String) {
        self.price = price
        self.title = title
        self.description = description
    }
    
    static let ShippingMethodOptions = [
        ShippingMethod(price: NSDecimalNumber(string: "5.00"), title: "Carrier Pigeon", description: "You'll get it someday."),
        ShippingMethod(price: NSDecimalNumber(string: "100.00"), title: "Racecar", description: "Vrrrroom! Get it by tomorrow!"),
        ShippingMethod(price: NSDecimalNumber(string: "9000000.00"), title: "Rocket Ship", description: "Look out your window!"),
    ]
}

enum SwagType {
    case Delivered(method: ShippingMethod)
    case Electronic
    
}

func ==(lhs: SwagType, rhs: SwagType) -> Bool {
    switch(lhs, rhs) {
    case (.Delivered(let lhsVal), .Delivered(let rhsVal)):
        return true
    case (.Electronic, .Electronic):
        return true
    default: return false
    }
}

struct Swag {
    let image: UIImage?
    let title: String
    let price: NSDecimalNumber
    let description: String
    var swagType: SwagType
    
    init(image: UIImage?, title: String, price: NSDecimalNumber, type: SwagType, description: String) {
        self.image = image
        self.title = title
        self.price = price
        self.swagType = type
        self.description = description
    }
    
    func total() -> NSDecimalNumber {
        var s = SwagType.Delivered(method: ShippingMethod(price: 3.0, title: "asdf", description: "asdf"))
        
        
        switch (swagType) {
        case .Delivered(let method):
            return price.adding(method.price)
        case .Electronic:
            return price
        }
    }
    
    var priceString: String {
        let dollarFormatter: NumberFormatter = NumberFormatter()
        dollarFormatter.minimumFractionDigits = 2;
        dollarFormatter.maximumFractionDigits = 2;
        return dollarFormatter.string(from: price)!
    }
}
