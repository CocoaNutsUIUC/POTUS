//
//  ViewController.swift
//  POTUS
//
//  Created by Justin Loew on 2/3/16.
//  Copyright © 2016 Justin Loew. All rights reserved.
//

import UIKit
import LocalAuthentication // for Touch ID

class ViewController: UIViewController {
	
	@IBOutlet weak var launchCodeTextField: UITextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func launchCodeEntryDone(sender: UITextField) {
		// save the launch codes securely
		
		let secretData = sender.text!.dataUsingEncoding(NSUTF8StringEncoding)!
		
		let query: [NSString : NSObject] = [
			// We're saving just a generic password, as opposed to a login or something else.
			kSecClass : kSecClassGenericPassword, 
			// This is a string that uniquely identifies your application.
			kSecAttrService : "com.cocoanuts.POTUS", 
			// We don't want this data to fall into the wrong hands, so we'll use the highest security setting.
			// If the user removes his/her passcode, this data will be deleted. If somebody restores another iPhone
			// from our user's backup, the encrypted data won't transfer over.
			kSecAttrAccessible : kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
			// This is the data that should actually be saved.
			kSecValueData : secretData 
		]
		
		// delete the previous launch codes, if they exist
		SecItemDelete(query)
		// save the new launch codes
		let status = SecItemAdd(query, nil)
		guard status == errSecSuccess else {
			print("Failed to save secret!")
			return
		}
		// Success!
		
		// Clear the text field and dismiss the keyboard.
		sender.text = nil
		sender.resignFirstResponder()
	}
	
	@IBAction func viewLaunchCodesTapped(sender: AnyObject) {
		// load the saved launch codes
		
		// authenticate with Touch ID
		self.authenticateWithTouchID { (success) -> Void in
			let launchCodes: String
			if success {
				// this is pretty much the same thing as up above
				let query: [NSString : NSObject] = [
					kSecClass : kSecClassGenericPassword,
					kSecAttrService : "com.cocoanuts.POTUS",
					kSecReturnData : true // retrieve the saved codes instead of setting new codes
					// We don't have to tell it when the data should be saved
					// and we don't have to give it data to save, either.
				]
				
				// submit the query
				var returnedData: AnyObject?
				let status = withUnsafeMutablePointer(&returnedData) { (returnedDataPtr) -> OSStatus in
					return SecItemCopyMatching(query, returnedDataPtr)
				}
				
				// make sure it was able to give us the saved secret
				if status == errSecSuccess, let secretData = returnedData as? NSData
				{
					// success
					launchCodes = String(data: secretData, encoding: NSUTF8StringEncoding)!
				} else {
					// error
					launchCodes = "Unable to retrieve saved launch codes."
				}
			} else {
				launchCodes = "Unable to retrieve saved launch codes."
			}
			
			// show the saved launch codes to the user
			dispatch_async(dispatch_get_main_queue()) { () -> Void in
				let alert = UIAlertController(title: "Launch Codes", message: launchCodes, preferredStyle: .Alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
				self.presentViewController(alert, animated: true, completion: nil)
			}
		}
	}
	
	func authenticateWithTouchID(completion: (Bool) -> Void) {
		// check if Touch ID is available
		let context = LAContext()
		guard context.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: nil) else {
			// Touch ID not available
			completion(false)
			return
		}
		
		// authenticate using Touch ID
		context.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock to view nuclear launch codes.") { (success, _) -> Void in
			completion(success)
		}
	}
	
}

