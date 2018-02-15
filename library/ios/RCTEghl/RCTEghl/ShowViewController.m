//
//  ShowViewController.m
//  eghl
//
//  Created by mac on 15/1/27.
//  Copyright (c) 2015年 eghl. All rights reserved.
//

#import "ShowViewController.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface CallbackToJS: RCTEventEmitter <RCTBridgeModule>
@end
@implementation CallbackToJS
RCT_EXPORT_MODULE(EGHLReturn);

+ (id)allocWithZone:(NSZone *)zone {
    static CallbackToJS *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [super allocWithZone:zone];
    });
    return sharedInstance;
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"eGHLReturn"];
}

- (void)postEvent:(NSDictionary *)info{
    [self sendEventWithName:@"eGHLReturn" body:info];
}
@end

typedef enum {
    tagAVExitPayment = 900
}tagForAlerView;

@interface ShowViewController () <UIAlertViewDelegate>
@property (strong, nonatomic) PaymentRequestPARAM *paypram;
@end

@implementation ShowViewController

-(id)initWithValue:(PaymentRequestPARAM *)payment
{
    self = [super init];
    
    if (self) {
        _paypram = payment;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
//    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
//        self.edgesForExtendedLayout = UIRectEdgeNone;
//    }

    UIButton * button = [[UIButton alloc] initWithFrame:CGRectZero];
    [button setImage:[UIImage imageNamed:@"navigationItemBack"] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRed:0.04 green:0.38 blue:1 alpha:1.0] forState:UIControlStateNormal];

    [button addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button setClipsToBounds:YES];
    
    [button setTitle:@"Exit" forState:UIControlStateNormal];
    [button sizeToFit];

    [button.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
//    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;

    /* ------------------
     * [OPTIONAL]
     * setup first Loading message
     * ------------------ */
    UILabel * messageLabel = [[UILabel alloc] init];
    messageLabel.text = @"Redirecting to Payment Gateway...";
    messageLabel.textColor = [UIColor whiteColor];
//        self.loadingMessageLabel.backgroundColor = [UIColor blackColor];
    [messageLabel sizeToFit];
    
    CGRect frame = messageLabel.frame;
    frame.size.height = 200;
    messageLabel.frame = frame;

    self.eghlpay.loadingMessageLabel = messageLabel;
    /* ------------------
     * [OPTIONAL]
     * setup finalise message
     * ------------------ */
    self.eghlpay.finaliseMessage = @"Verifying payment...";
    /* ------------------
     * [OPTIONAL]
     * setup masterpass lightbox loading message
     * ------------------ */
    self.eghlpay.loadingMPLightBoxMessage = @"Redirecting to Masterpass...";
    // ------------------
    
    [self.view addSubview:self.eghlpay];
    [self.eghlpay paymentAPI:self.paypram successBlock:^(PaymentRespPARAM * result) {
        if ([result.rawResponseDict isKindOfClass:[NSDictionary class]]) {
            NSLog(@"result.rawResponseDict:%@",result.rawResponseDict);
            
            [self dismissViewControllerAnimated:YES completion:^{
                CallbackToJS *callback = [CallbackToJS allocWithZone: nil];
                
                [callback postEvent:@{
                                      @"status":@YES,
                                      @"result":result.rawResponseDict
                                      }];
            }];
        }
    } failedBlock:^(NSString *errorCode, NSString *errorData, NSError * error) {
        NSLog(@"errordata:%@ (%@)", errorData, errorCode);
        
        if (error) {
            NSString * urlstring = [error userInfo][@"NSErrorFailingURLKey"];
            if (urlstring) {
                NSLog(@"NSErrorFailingURLKey:%@",urlstring);
            }
        }
        
        [self dismissViewControllerAnimated:YES completion:^{
            CallbackToJS *callback = [CallbackToJS allocWithZone: nil];
            
            [callback postEvent:@{
                                  @"status":@NO,
                                  @"message":errorData
                                  }];
        }];
    }];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    self.eghlpay.frame = self.view.frame;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


- (void)backButtonPressed:(id)sender{
    UIAlertView * alertExit = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to quit" message:@"Pressing BACK button will close and abandon the payment session." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Exit", nil];
    
    [alertExit setTag:tagAVExitPayment];
    [alertExit show];
}

#pragma mark - UIAlertView delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch ([alertView tag]) {
        case tagAVExitPayment:
        {
            if (buttonIndex == 1) {
//                [self.navigationController popViewControllerAnimated:YES];
                [self.eghlpay finalizeTransaction];
            }
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - convenient method
+ (NSString *)displayResponseParam:(PaymentRespPARAM *)respParam {
    NSMutableString * message = [NSMutableString string];
    
    for (NSString * key in @[@"Amount",@"AuthCode",@"BankRefNo",@"CardExp",@"CardHolder",@"CardNoMask",@"CardType",@"CurrencyCode",@"EPPMonth",@"EPP_YN",@"HashValue",@"HashValue2",@"IssuingBank",@"OrderNumber",@"PromoCode",@"PromoOriAmt",@"Param6",@"Param7",@"PaymentID",@"PymtMethod",@"QueryDesc",@"ServiceID",@"SessionID",@"SettleTAID",@"TID",@"TotalRefundAmount",@"Token",@"TokenType",@"TransactionType",@"TxnExists",@"TxnID",@"TxnMessage",@"TxnStatus",@"ReqToken",@"PairingToken",@"PreCheckoutId",@"Cards",@"mpLightboxError"]) {
        NSString * value = [respParam valueForKey:key];
        
        if ([value isKindOfClass:[NSString class]] && value.length>0) {
            [message appendFormat:@"%@: %@\n", key,value];
        } else if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value
                                                               options:0 //NSJSONWritingPrettyPrinted for readability
                                                                 error:&error];
            
            if (jsonData) {
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
                
                [message appendFormat:@"%@: %@\n", key, jsonString];
            }
            
        }
    }
        
    return message;
}
+ (NSString *)displayRequestParam:(PaymentRequestPARAM *)reqParam {
    NSMutableString * message = [NSMutableString string];
    
    for (NSString * key in @[@"realHost",@"Amount", @"PaymentID", @"OrderNumber", @"MerchantName", @"ServiceID", @"PymtMethod", @"MerchantReturnURL", @"CustEmail", @"Password", @"CustPhone", @"CurrencyCode", @"CustName", @"LanguageCode", @"PaymentDesc", @"PageTimeout", @"CustIP", @"MerchantApprovalURL", @"CustMAC", @"MerchantUnApprovalURL", @"CardHolder", @"CardNo", @"CardExp", @"CardCVV2", @"BillAddr", @"BillPostal", @"BillCity", @"BillRegion", @"BillCountry", @"ShipAddr", @"ShipPostal", @"ShipCity", @"ShipRegion", @"ShipCountry", @"TransactionType", @"TokenType", @"Token", @"SessionID", @"IssuingBank", @"MerchantCallBackURL", @"B4TaxAmt", @"TaxAmt", @"Param6", @"Param7", @"EPPMonth", @"PromoCode", @"ReqVerifier", @"PairingVerifier", @"CheckoutResourceURL", @"ReqToken", @"PairingToken", @"CardId", @"PreCheckoutId", @"mpLightboxParameter",  @"sdkTimeOut"]) {
        id value = [reqParam valueForKey:key];
        
        if (value) {
            if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSArray class]]) {
                if ([value length]>0) {
                    [message appendFormat:@"%@: %@\n", key, value];
                }
            } else if ([value isKindOfClass:[NSNumber class]]) {
                [message appendFormat:@"%@: %d\n", key, [value intValue]] ;
            }
        }
    }
    
    return message;
}

@end