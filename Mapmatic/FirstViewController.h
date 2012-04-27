//
//  FirstViewController.h
//  Mapmatic
//
//  Created by Jeremiah Boyle on 4/25/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface FirstViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate> 
{
    CLLocationManager *_locmgr;
    UIImage *_image;
}

@property (nonatomic, retain) IBOutlet UITextField *field_title;
@property (nonatomic, retain) IBOutlet UITextField *field_description;
@property (nonatomic, retain) IBOutlet UITextField *field_username;
@property (nonatomic, retain) IBOutlet UIButton *button_takephoto;
@property (nonatomic, retain) IBOutlet UIButton *button_postspot;
@property (nonatomic, retain) IBOutlet UIImageView *view_image;
@property (nonatomic, retain) IBOutlet UILabel *label_location;
@property (nonatomic, retain) IBOutlet UILabel *label_status;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner_posting;

- (IBAction)takePhoto:(id)sender;
- (IBAction)postSpot:(id)sender;

@end
