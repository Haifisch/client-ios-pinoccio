//
//  MainTableViewController.m
//  Pinoccio
//
//  Created by Haifisch on 6/7/14.
//  Copyright (c) 2014 Haifisch. All rights reserved.
//

#import "MainTableViewController.h"
#import "UARTPeripheral.h"
#import <QuartzCore/QuartzCore.h>
#import "NSString+hex.h"
#import "NSData+hex.h"

#define CONNECTING_TEXT @"Connecting…"
#define DISCONNECTING_TEXT @"Disconnecting…"
#define DISCONNECT_TEXT @"Disconnect"
#define CONNECT_TEXT @"Connect"

@interface MainTableViewController (){
    NSString *globalToken;
    NSMutableDictionary *globalTroopDict;
    NSMutableArray *globalScoutList;
    UIRefreshControl *refreshControl;
}

@end

@implementation MainTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.tableView.backgroundColor = [UIColor colorWithRed:31/255.0f green:38/255.0f blue:51.0f/255.0f alpha:1];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:31/255.0f green:38/255.0f blue:51.0f/255.0f alpha:1];
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setTitleTextAttributes: @{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"Lato-Regular" size:20.0f]}];
    [self.tableView setSeparatorColor:[UIColor blackColor]];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];

    //[self performSegueWithIdentifier:@"submitIssue" sender:self];

}
-(void)checkLogin:(BOOL)loggedOut {
    if (loggedOut == NO) {
        globalToken = [JNKeychain loadValueForKey:@"APIToken"];
    }
    
    if (globalToken != nil) {
        [self refreshTroops];
    }else if (loggedOut == YES){
        [[[UIAlertView alloc] initWithTitle:@"Logged out!" message:@"Successfully logged out" delegate:nil cancelButtonTitle:@"Ok :D" otherButtonTitles:nil, nil] show];
        [self performSegueWithIdentifier:@"loginSegue" sender:self];
    }else {
        [[[UIAlertView alloc] initWithTitle:@"Login invalid!" message:@"Check email and password, then try again" delegate:nil cancelButtonTitle:@"Ok :(" otherButtonTitles:nil, nil] show];
        [self performSegueWithIdentifier:@"loginSegue" sender:self];
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    globalTroopDict = [[NSMutableDictionary alloc] init];
    globalScoutList = [[NSMutableArray alloc] init];
    
    refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refreshTroops) forControlEvents:UIControlEventValueChanged];
    
    if ([JNKeychain loadValueForKey:@"APIToken"] == nil) {
        globalTroopDict = [[NSMutableDictionary alloc] init];
        globalScoutList = [[NSMutableArray alloc] init];
        [self.tableView reloadData];
        [self performSegueWithIdentifier:@"loginSegue" sender:self];
    }else {
        [self checkLogin:NO];
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [globalTroopDict[@"data"] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableDictionary *tempScoutDict;
    int count = 0;
    while (count < [self numberOfSectionsInTableView:self.tableView]) {
        NSInteger troopID = [globalTroopDict[@"data"][count][@"id"] integerValue];
        tempScoutDict = [[self scoutsForTroopID:troopID] mutableCopy];
        [globalScoutList addObject:tempScoutDict];
        count++;
    }
    return [[globalScoutList[section][@"data"] mutableCopy] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    // Cell specifics
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"Cell%ld%ld", (long)indexPath.row, (long)indexPath.section]];
    if (cell == NULL) {
        // Scout Name Label Specifics
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ScoutCell"];
        cell.backgroundColor = [UIColor colorWithRed:31/255.0f green:38/255.0f blue:51.0f/255.0f alpha:1];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        UILabel *scoutNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, cell.frame.size.width, cell.frame.size.height)];
        scoutNameLabel.text = globalScoutList[indexPath.section][@"data"][indexPath.row][@"name"];
        scoutNameLabel.textColor = [UIColor colorWithRed:172/255.0f green:188/255.0f blue:208/255.0f alpha:1];
        scoutNameLabel.font = [UIFont fontWithName:@"Lato-Regular" size:15];
        
        UIView *ledView = [[UIView alloc] initWithFrame:CGRectMake(8, 13, 20, 20)];
        [ledView setTag:32];
        ledView.backgroundColor = [UIColor clearColor];
        ledView.layer.cornerRadius = ledView.frame.size.height/2;
        ledView.layer.shadowColor = [UIColor clearColor].CGColor;
        ledView.layer.shadowOpacity = .7;
        ledView.layer.shadowRadius = ledView.frame.size.height/2;
        ledView.layer.shadowOffset = CGSizeZero;
        ledView.layer.borderColor = [UIColor grayColor].CGColor;
        ledView.layer.borderWidth = 2.5;
        [cell addSubview:ledView];
        [cell addSubview:scoutNameLabel];
        
        UIView *selectedBackgroundView = [[UIView alloc] init];
        [selectedBackgroundView setBackgroundColor:[UIColor colorWithRed:51/255.0f green:58/255.0f blue:101.0f/255.0f alpha:1]];
        [cell setSelectedBackgroundView:selectedBackgroundView];
        
        return cell;
        
    }
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.tableView.bounds.size.width,20)];
    headerView.backgroundColor = [UIColor colorWithRed:43/255.0f green:53/255.0f blue:69/255.0f alpha:1];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 7, headerView.frame.size.width, headerView.frame.size.height)];
    titleLabel.textColor = [UIColor colorWithRed:97/255.0f green:117/255.0f blue:138/255.0f alpha:1];
    titleLabel.font = [UIFont fontWithName:@"Lato-Black" size:20];
    titleLabel.text = globalTroopDict[@"data"][section][@"name"];
    [headerView addSubview:titleLabel];
    return headerView;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self performSegueWithIdentifier:@"gotoScout" sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier  isEqual: @"gotoScout"]) {
        ScoutControlTableViewController *scoutControl = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        scoutControl.troopID = [[[globalTroopDict objectForKey:@"data"] objectAtIndex:indexPath.section] objectForKey:@"id"];
        scoutControl.scoutID = globalScoutList[indexPath.section][@"data"][indexPath.row][@"id"];
        scoutControl.scoutName = globalScoutList[indexPath.section][@"data"][indexPath.row][@"name"];
        scoutControl.token = globalToken;
    }
}


- (IBAction)refreshTroops:(id)sender {
    [self refreshTroops];
}

- (IBAction)settingsOptions:(id)sender {
    UIActionSheet *popupQuery = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Logout" otherButtonTitles:nil, nil];
    popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [popupQuery showInView:self.view];
}
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // Logout
        [JNKeychain deleteValueForKey:@"APIToken"];
        globalToken = nil;
        [self checkLogin:YES];
        
    }
}

#pragma mark - Scouts 

-(NSMutableDictionary*)scoutsForTroopID:(NSInteger)troopID {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSURL *urlString = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinocc.io/v1/%ld/scouts?token=%@",(long)troopID,globalToken]];
    if ([NSData dataWithContentsOfURL:urlString]) {
        dict = [[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:urlString] options:0 error:nil] mutableCopy];
    }
    if (dict) {
        return  dict;
    }else {
        return  nil;
    }

}

-(NSDictionary *)colorDataWithTroop:(NSInteger)troopID scout:(NSInteger)scoutID {
    NSURL *urlString = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinocc.io/v1/%ld/%ld/command/led.report?token=%@",(long)troopID,scoutID,globalToken]];
    NSData *rawData = [NSData dataWithContentsOfURL:urlString];
    NSDictionary *colorData;
    if (rawData) {
        NSDictionary *report = [NSJSONSerialization JSONObjectWithData:rawData options:0 error:nil];
        colorData = [NSJSONSerialization JSONObjectWithData:[report[@"data"][@"reply"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    }else {
        colorData = nil;
    }
    return colorData;
}

-(NSDictionary *)allTroopsFor:(NSString *)token {
    NSURL *urlString = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinocc.io/v1/troops?token=%@",token]];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:urlString] options:0 error:nil];
    return  dict;
}

-(NSString *)token {
    
    NSString *post = [NSString stringWithFormat:@"{\"email\":\"%@\",\"password\":\"%@\"}",[JNKeychain loadValueForKey:@"PinoccioKeychainUsername"],[JNKeychain loadValueForKey:@"PinoccioKeychainPassword"]];
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
-(void)setupColorViews {
    for (int troopCount = 0; troopCount < [globalTroopDict[@"data"] count]; troopCount++) {
        int scoutCount = 0;
        while (scoutCount < [globalScoutList[troopCount][@"data"] count]) {
            UIColor *scoutLEDColor;
            UIColor *scoutTorchColor;
            NSInteger scoutID = [globalScoutList[troopCount][@"data"][scoutCount][@"id"] integerValue];
            NSDictionary *colorData = [self colorDataWithTroop:[globalTroopDict[@"data"][troopCount][@"id"] integerValue] scout:scoutID];
            
            NSIndexPath *path = [NSIndexPath indexPathForRow:scoutCount inSection:troopCount];
            UITableViewCell *tempCell = [self.tableView cellForRowAtIndexPath:path];
            UIView *colorView = [tempCell viewWithTag:32];
            if (!(colorData[@"led"][0] == 0 && colorData[@"led"][1] == 0 && colorData[@"led"][2] == 0)) {
                scoutLEDColor = [UIColor colorWithRed:[colorData[@"led"][0] integerValue] green:[colorData[@"led"][1] integerValue] blue:[colorData[@"led"][2] integerValue] alpha:1];
                scoutTorchColor = [UIColor colorWithRed:[colorData[@"torch"][0] integerValue] green:[colorData[@"torch"][1] integerValue] blue:[colorData[@"torch"][2] integerValue] alpha:1];
                
                colorView.backgroundColor = scoutLEDColor;
                colorView.layer.shadowColor = scoutLEDColor.CGColor;
                colorView.layer.borderColor = scoutTorchColor.CGColor;
            }
            scoutCount++;
        }
        scoutCount = 0;
    }
}
-(void)refreshTroops {
    if (globalToken) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [refreshControl endRefreshing];
        hud.labelText = @"Getting troops...";
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            globalTroopDict = [[self allTroopsFor:globalToken] mutableCopy];
            [self.tableView reloadData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [self setupColorViews];
            });
        });
    }
}

@end
