//
//  FirstViewController.m
//  Mapmatic
//
//  Created by Jeremiah Boyle on 4/25/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "FirstViewController.h"

@implementation FirstViewController

@synthesize field_title, field_description, field_username, label_location;
@synthesize button_takephoto, view_image;
@synthesize label_status, button_postspot, spinner_posting;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [self updateStatus:nil withSpin:NO];
    [self initLocation];
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    NSLog(@"viewDidUnload");

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

//
// IBActions
//

- (IBAction)takePhoto:(id)sender
{
    NSLog(@"Take Photo");
        
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        NSLog(@"device has no camera");
        return;
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentModalViewController:imagePickerController animated:YES];
}

- (IBAction)postSpot:(id)sender
{
    NSString *location = [self stringFromLocation:_locmgr.location];    
    NSData *imgdata = UIImagePNGRepresentation(self.view_image.image);
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          self.field_title.text, @"spot[title]",
                          self.field_description.text, @"spot[description]",
                          self.field_username.text, @"spot[user]",
                          location, @"spot[location]",
                          imgdata, @"spot[image]",
                          nil];
    
    [self updateStatus:@"Posting..." withSpin:YES];
    [self httpPostWithDictionary:dict];
}

//
// Helpers
//

- (void)initLocation
{
    if (_locmgr == NULL)
    {
        _locmgr = [CLLocationManager new];
        _locmgr.delegate = self;
        _locmgr.purpose = @"Your current location will be used to display photos on the map.";
        _locmgr.desiredAccuracy = kCLLocationAccuracyBest;
        [_locmgr startUpdatingLocation];
        [_locmgr startUpdatingHeading];
    }
}

+ (NSData *)dataForPostWithDictionary:(NSDictionary *)aDictionary boundary:(NSString *)aBoundary
{
    NSArray *myDictKeys = [aDictionary allKeys];
    NSMutableData *myData = [NSMutableData dataWithCapacity:1];
    NSString *myBoundary = [NSString stringWithFormat:@"--%@\r\n", aBoundary];

    for(int i = 0;i < [myDictKeys count];i++) {
        id myValue = [aDictionary valueForKey:[myDictKeys objectAtIndex:i]];
        [myData appendData:[myBoundary dataUsingEncoding:NSUTF8StringEncoding]];
        //if ([myValue class] == [NSString class]) {
        if ([myValue isKindOfClass:[NSString class]]) {
            [myData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", [myDictKeys objectAtIndex:i]] dataUsingEncoding:NSUTF8StringEncoding]];
            [myData appendData:[[NSString stringWithFormat:@"%@", myValue] dataUsingEncoding:NSUTF8StringEncoding]];
        } else if(([myValue isKindOfClass:[NSURL class]]) && ([myValue isFileURL])) {
            [myData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", [myDictKeys objectAtIndex:i], [[myValue path] lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
            [myData appendData:[[NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [myData appendData:[NSData dataWithContentsOfFile:[myValue path]]];
        } else if(([myValue isKindOfClass:[NSData class]])) {
            [myData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", [myDictKeys objectAtIndex:i], [myDictKeys objectAtIndex:i]] dataUsingEncoding:NSUTF8StringEncoding]];
            [myData appendData:[[NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [myData appendData:myValue];
        } // eof if()

        [myData appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    } // eof for()
    [myData appendData:[[NSString stringWithFormat:@"--%@--\r\n", aBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

    return myData;
}

- (void)httpPostWithDictionary:(NSDictionary *)aDictionary
{
    NSURL *cgiUrl = [NSURL URLWithString:
                     //@"http://paprika.local:3000/spots"
                     @"http://quiet-spring-2241.herokuapp.com/spots"
                     ];
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:cgiUrl];
    [postRequest setHTTPMethod:@"POST"];

    NSString *stringBoundary = [NSString stringWithString:@"0xKhTmLbOuNdArY"];
    [postRequest addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary] forHTTPHeaderField: @"Content-Type"];
    [postRequest addValue:@"application/json" forHTTPHeaderField: @"Accepts"];
    [postRequest setHTTPBody:[FirstViewController dataForPostWithDictionary:aDictionary boundary:stringBoundary]];

    NSURLConnection *conn = [NSURLConnection connectionWithRequest:postRequest delegate:self];
    if (conn == nil)
    {
        NSLog(@"failed to create connection");
        return;
    }
}

- (void)updateStatus:(NSString *)status withSpin:(BOOL)spin
{
    if (spin)
    {
        [self.spinner_posting startAnimating];
    }
    else
    {
        [self.spinner_posting stopAnimating];
    }
    
    if (status == nil)
    {
        self.label_status.hidden = YES;
    }
    else
    {
        self.label_status.hidden = NO;
        self.label_status.text = status;
    }
}

- (void)resetUI
{
    self.view_image.image = nil;
    self.field_title.text = @"";
    self.field_description.text = @"";
}

- (NSString *)stringFromLocation:(CLLocation *)location
{
    return [NSString stringWithFormat:@"%f,%f,%f",
            location.coordinate.latitude,
            location.coordinate.longitude,
            location.altitude];
}

//
// UIImagePickerControllerDelegate methods
//

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"picker: %@", picker);
    NSLog(@"got media: %@", info);
    [picker dismissModalViewControllerAnimated:YES];
    
    self.view_image.image = [info objectForKey:UIImagePickerControllerOriginalImage];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"picker canceled");
    [picker dismissModalViewControllerAnimated:YES];
}

//
// CLLocationManagerDelegate methods
//

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    //NSLog(@"%@", [self stringFromLocation:newLocation]);
    self.label_location.text = [self stringFromLocation:newLocation];
}

/*
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
   NSLog(@"location manager authorization: %@", status);
}
*/

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"location manager failed: %@", error);
}

//
// NSURLConnectionDelegate methods
//

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"post failed: %@", error);
    [self updateStatus:@"Failed :(" withSpin:NO];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"post got response");
    // This method is called when the server has determined that it    
    // has enough information to create the NSURLResponse.
    
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
        
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"post got data");
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{    
    NSLog(@"post succeeded!");
    [self updateStatus:@"Success!" withSpin:NO];
    [self resetUI];
    
    // release the connection, and the data object
    //[connection release];
    //[receivedData release];
}

//
// UITextFieldDelegate methods
//

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
