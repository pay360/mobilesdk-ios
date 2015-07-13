# Paypoint Advanced Payments iOS SDK

## Requirements

* iOS 7+  
* XCode 5+  

## Dependencies
 
* UIKit.framework  
* SystemConfiguration.framework  
* CoreGraphics.framework  
* MessageUI.framework

# Installation with CocoaPods

To integrate the Paypoint Payments iOS SDK into your project using CocoaPods, specify it in your Podfile:

    source 'https://github.com/CocoaPods/Specs.git'
    platform :ios, '7.0'
    
    pod 'PayPointPayments',:git => 'https://github.com/paypoint/mobilesdk-ios.git', :tag => '1.0.0'

Then run the following command:

    $ pod install


# Register

You can sign up for a [PayPoint Explorer](https://developer.paypoint.com/payments/explore/#/register). This will give you access to a number of PayPoint products including the Mobile SDK in our Merchant Integration Test Environment (MITE). 

MITE - is a dedicated environment for merchants to explore our products and build their integration before go-live.  

We'll send you an Installation ID for Cashier API once you have signed up which can be used with the Mobile SDK. 

Payments made through the Mobile SDK can be tracked in our MITE [Portal](https://portal.mite.paypoint.net:3443/portal-client/#/en_gb/log_in)

# Testing your application against MITE

In order to make payments in MITE your server must obtain a client access token.  The client access token will be used by your app to submit payments. Instructions for doing this are available [here](https://developer.paypoint.com/payments/docs/#getting_started/response_codes_and_messages)

For convenience we provide a mock REST api which supplies these tokens for your MITE installations which can be used for prototyping your app.

## Mock Authorise Client Call

Perform a a Get request using the following URL. At this point, you should have your InstallationID ready.

```objective-c
NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://developer.paypoint.com/payments/explore/rest/mockmobilemerchant/getToken/%@", INSTALLATION_ID]];
```

You should receive a HTTP Status code '200', indicating the call was successful. Parse the JSON data that is returned in the response payload. Extract the string value for key "accessToken" and build an intance of PPOCredentials, as follows.

```objective-c
PPOCredentials *credentials = [PPOCredentials new];
credentials.installationID = INSTALLATION_ID;
credentials.token = token;
```

Using this instance of PPOCredentials, you can now make a payment in our MITE testing environment.

## Making a Payment 

When making a payment, you should have an instance of **PPOCredentials** ready. If you do not, please see 'Mock Authorise Client Call' above. 

If you choose to validate an instance of PPOCredentials at this stage, there is public API available for you to do so, which looks like the following:

```objective-c
NSError *invalidCredentials = [PPOValidator validateCredentials:credentials];
```

To proceed with making a payment, build a representation of your payment by preparing an instance of **PPOPayment**.


```objective-c
PPOPayment *payment = [PPOPayment new];
payment.credentials = credentials;
```

Prepare an instance of your transaction and card details, by preparing an instance of **PPOTransaction** and **PPOCard**, like so: 

```ojective-c
PPOTransaction *transaction = [PPOTransaction new];
transaction.currency = @"GBP";
transaction.amount = @100;
transaction.transactionDescription = @"description";
transaction.merchantRef = @"dk93kl320";

payment.transaction = transaction;

PPOCard *card = [PPOCard new];
card.pan = @"9900000000005159";
card.cvv = @"123";
card.expiry = @"0117";
card.cardHolderName = @"Bob Jones";

payment.card = card;
```

You may also want to provide a billing address, by providing an instance of **PPOBillingAddress**, like so.

```objective-c
PPOBillingAddress *address = [PPOBillingAddress new];
address.line1 = @"House name";
address.line2 = @"Steet";
address.city = @"Bristol";
address.region = @"Somerset";
address.postcode = @"BS32";

payment.address = address;
```

You may also want to provide custom fields, by building instances of **PPOCustomField**, like so.


```objective-c
NSMutableSet *collector = [NSMutableSet new];

customField = [PPOCustomField new];
customField.name = @"CustomName";
customField.value = @"CustomValue";
customField.isTransient = @YES;

[collector addObject:customField];

customField = [PPOCustomField new];
customField.name = @"CustomName";

[collector addObject:customField];

customField = [PPOCustomField new];
customField.name = @"AnotherCustomName";
customField.isTransient = @YES;

[collector addObject:customField];

payment.customFields = [collector copy];
```

You may also want to provide financial services details, by building an instance of **PPOFinancialServices**, like so.

```objective-c
PPOFinancialServices *financialServices = [PPOFinancialServices new];
financialServices.dateOfBirth = @"19870818";
financialServices.surname = @"Smith";
financialServices.accountNumber = @"123ABC";
financialServices.postCode = @"BS20";

payment.financialServices = financialServices;
```


To trigger a payment, set up an instance of  **PPOPaymentManager**, with a suitable baseURL.  A custom baseURL can be used, or a subset of pre-defined baseURL's can be found in **PPOPaymentBaseURLManager**, as follows:

```objective-c
NSURL *baseURL = [PPOPaymentBaseURLManager baseURLForEnvironment:PPOEnvironmentMerchantIntegrationTestingEnvironment];
PPOPaymentManager *paymentManager = [[PPOPaymentManager alloc] initWithBaseURL:baseURL];
```

Trigger a payment by passing an instance of **PPOPayment** as follows:

```objective-c    
self.paymentManager makePayment:payment 
                    withTimeOut:60.0f
                 withCompletion:^(PPOOutcome *outcome) {
                        
                          if (outcome.error) {
                              //Inspect payment status in error code for the corresponding error domain.
                          } else {
                              // Handle success
                          }
                          
                      }];
```

NOTE - the SDK will always callback within a set timeout period. Care should be taken when setting this value as short timeouts might not allow enough time for the payment to be authorised. This timeout does not include any delays resulting from the user being redirected to 3D Secure.

If a payment requires 3D Secure, a scene is automatically presented modally, full screen, from the root view controller of UIWindow. This scene will consists of a form that the user is expected to complete. Once the user completes this process the scene will dismiss and the payment will proceed.

## Error handling

An instance of PPOPayment carries a unique identifier. If a payment fails and the state of the transaction is ambiguous you should query the state, by passing the instance in question into your payment manager.

```objective-c
self.paymentManager queryPayment:payment 
                  withCompletion:^(PPOOutcome *outcome) {
                        
                          if (outcome.error) {
                              //Inspect payment status in error code for the corresponding error domain.
                          } else {
                              //Status is payment success
                          }
                          
                      }];
```

Calling makePayment again, when an error is ambiguous, may result in a duplicate payment. For peace of mind, a convenience method is available which returns a boolean value, indicating if it is safe to repeat the payment, without the risk of duplication.

```objective-c
if ([PPOPaymentManager isSafeToRetryPaymentWithOutcome:outcome]) {
    [self makePayment:outcome.payment];
}
```


## Test Cards

A set of test cards for MITE are available here:
[MITE test cards](https://developer.paypoint.com/payments/docs/#getting_started/test_cards)

## Documentation

The in depth documentation can be found [here](https://developer.paypoint.com)
