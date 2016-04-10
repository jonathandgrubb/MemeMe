//
//  ViewController.swift
//  UIPicker-research
//
//  Created by Jonathan Grubb on 8/28/15.
//  Copyright (c) 2015 Jonathan Grubb. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var futureNavBar: UIToolbar!
    @IBOutlet weak var actionButton: UIBarButtonItem!
    
    var memedImage: UIImage!
    var savedMemes: [Meme] = []
    
    let defaultTopText = "TOP"
    let defaultBottomText = "BOTTOM"
    
    // approximate an Imact Font
    let memeTextAttributes = [
        NSStrokeColorAttributeName : UIColor.blackColor(),
        NSForegroundColorAttributeName : UIColor.whiteColor(),
        NSFontAttributeName : UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSStrokeWidthAttributeName : -3
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // topTextField settings
        topTextField.delegate = self                               // set the delegate
        topTextField.defaultTextAttributes = memeTextAttributes    // set the default text attributes
        topTextField.textAlignment = NSTextAlignment.Center        // set center justification
        
        // bottomTextField settings
        bottomTextField.delegate = self                            // set the delegate
        bottomTextField.defaultTextAttributes = memeTextAttributes // set the default text attributes
        bottomTextField.textAlignment = NSTextAlignment.Center     // set center justification

        // enable the camera button if the camera is available
        cameraButton.enabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
        
        // disable the action button at the beginning
        actionButton.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // subscribe to notifications about the keyboard
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // unsubscribe from notifications about the keyboard before the view disappears
        unsubscribeFromKeyboardNotifications()
    }

    // graders might want this called 'pickAnImageFromAlbum'
    @IBAction func pickAnImage(sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        presentViewController(imagePicker, animated: true, completion: nil)
    }

    @IBAction func pickAnImageFromCamera(sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func shareMeme(sender: AnyObject) {
        // create the memed image (as an array)
        memedImage = generateMemedImage()
        let memedImages = [memedImage]
        // pass the ActivityViewController a memedImage as an activity item
        let activityViewController = UIActivityViewController(activityItems: memedImages, applicationActivities: nil)
        
        // save the meme and dismiss with animation
        activityViewController.completionWithItemsHandler = {(activityType: String!, completed: Bool, returnedItems: [AnyObject]!, error: NSError!) -> Void in
            if (completed) {
                // save the meme if it was shared (seemed more useful than even sharing when cancelled)
                self.save()
            }
            activityViewController.dismissViewControllerAnimated(true, completion: nil)
        }
        
        // display the activity view
        presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func cancelMeme(sender: AnyObject) {
        // When the user presses the “Cancel” button, the Meme Editor View returns to its launch state, 
        // displaying no image and default text.
        imagePickerView.image = nil
        topTextField.text = defaultTopText
        bottomTextField.text = defaultBottomText
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imagePickerView.image = image  // use the image in our UIImage
            actionButton.enabled = true    // enable the action button now that we've chosen a picture
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // when a user taps inside a textfield, the default text should clear
    func textFieldDidBeginEditing(textField: UITextField) {
        if (textField == topTextField) {
            if (textField.text == defaultTopText) {
                textField.text = ""
            }
        } else {
            if (textField.text == defaultBottomText) {
                textField.text = ""
            }
        }
    }

    // when a user presses return, the keyboard should be dismissed
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    // call "keyboardWillShow()" when there is a "keyboard will show/hide" notification
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // stop watching for keyboard notifications
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name:
            UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:
            UIKeyboardWillHideNotification, object: nil)
    }
    
    // move the screen up/down when there is a "keyboard will show" notification
    func keyboardWillShow(notification: NSNotification) {
        view.frame.origin.y -= getKeyboardHeight(notification)
    }
    
    // move the screen up/down when there is a "keyboard will hide" notification
    func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0.0
    }

    // return the height of the keyboard
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.CGRectValue().height
    }
    
    // generate the meme
    func generateMemedImage() -> UIImage
    {
        // hide toolbar, navbar, and grey UIImageView background
        toolbar.hidden = true
        futureNavBar.hidden = true
        imagePickerView.backgroundColor = UIColor.whiteColor()
        
        // Render view to an image
        UIGraphicsBeginImageContext(view.frame.size)
        view.drawViewHierarchyInRect(view.frame, afterScreenUpdates: true)
        let memedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // show toolbar, navbar, and grey UIImageView background
        toolbar.hidden = false
        futureNavBar.hidden = false
        imagePickerView.backgroundColor = UIColor.darkGrayColor()
        
        return memedImage
    }
    
    // save the meme
    func save() {
        // create a Meme object (top and bottom text, original image, and final image)
        let meme = Meme( textTop: topTextField.text!, textBottom: bottomTextField.text!, image: imagePickerView.image!, memedImage: memedImage)
        
        // save meme to an array of saved memes
        self.savedMemes.append(meme)
    }
}

