//
//  LoginViewController.m
//  Pinoccio
//
//  Created by Haifisch on 6/7/14.
//  Copyright (c) 2014 Haifisch. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController (){
    NSString *email;
    NSString *password;
}

@end

@implementation LoginViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITextField *usernameField = (UITextField*)[self.view viewWithTag:1];
    UITextField *passwordField = (UITextField*)[self.view viewWithTag:2];
    [usernameField setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:@"Username or email" attributes:@{NSForegroundColorAttributeName: [UIColor blackColor]}]];
    [passwordField setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName: [UIColor blackColor]}]];
    // style username field
    usernameField.layer.borderColor = [UIColor whiteColor].CGColor;
    usernameField.layer.borderWidth = 0.5f;
    usernameField.layer.masksToBounds = YES;
    usernameField.layer.cornerRadius = 3.0f;
    usernameField.backgroundColor = [UIColor whiteColor];
    // style password field
    passwordField.layer.borderColor = [UIColor whiteColor].CGColor;
    passwordField.layer.borderWidth = 0.5f;
    passwordField.layer.masksToBounds = YES;
    passwordField.layer.cornerRadius = 3.0f;
    passwordField.backgroundColor = [UIColor whiteColor];
    
    [usernameField setDelegate:self];
    [passwordField setDelegate:self];
    [usernameField becomeFirstResponder];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)login:(id)sender {
    email = [(UITextField *)[self.view viewWithTag:1] text];
    password = [(UITextField *)[self.view viewWithTag:2] text];

    NSString *token = [self token];
    if (token) {
        [JNKeychain saveValue:[self token] forKey:@"APIToken"];
        [(UITextField*)[self.view viewWithTag:2] resignFirstResponder];
        [self dismissViewControllerAnimated:YES completion:nil];
    }else {
       [[[UIAlertView alloc] initWithTitle:@"Login failed, try again." message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
}
-(NSString *)token {
    
    NSString *post = [NSString stringWithFormat:@"{\"email\":\"%@\",\"password\":\"%@\"}",email,password];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://api.pinocc.io/v1/login"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    [request setHTTPBody:postData];
    
    NSURLResponse *response;
    NSError *error;
    
    NSData *jsonData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSDictionary *results = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error] : nil;
    if (error) NSLog(@"[%@ %@] JSON error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error.localizedDescription);
    if (results != nil && results[@"data"][@"token"] != nil) {
        return results[@"data"][@"token"];
    }else {
        return nil;
    }
    
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if ([textField tag] == 1) {
        [(UITextField*)[self.view viewWithTag:2] becomeFirstResponder];
    }else if ([textField tag] == 2){
        [self login:nil];
    }
    return YES;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

@end
