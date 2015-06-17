# Paypoint Payments iOS SDK

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
    
    pod 'PaypointSDK', '~> 1.0.0'

Then run the following command:

    $ pod install


# Usage

Each and every payment request must be coupled with a client access token.  Please set up a means of acquiring a client access token from Paypoint, before continuing on to a payment request.

## Making a Payment 

An instance of **PPOCredentials** is required for each payment request.  To make a simple payment, first build an instance of PPOCredentials.

```objective-c
PPOCredentials *credentials = [PPOCredentials new];
credentials.installationID = INSTALLATION_ID;
credentials.token = clientAccessToken;
```


The PaypointSDK will evaluate all parameters injected into a payment for their presence and validity.  These methods are exposed as public API and are available if you want to validate inline with the UI.

If you choose to validate an instance of PPOCredentials at this stage, there is public API available, which looks like the following:

```objective-c
NSError *invalidCredentials = [PPOPaymentValidator validateCredentials:credentials];
```

Build a representation of your payment, by instantiating an instance of **PPOPayment**.  This requires three parameters, each of which require information about your payment.

There is also the opportunity to provide custom fields or details of financial services.

When 'isDeferred' is set to 'YES' the payment will be an Authorisation.


```objective-c
PPOBillingAddress *address = [PPOBillingAddress new];
address.line1 = @"House name";
address.line2 = @"Steet";
address.city = @"Bristol";
address.region = @"Somerset";
address.postcode = @"BS32";

PPOTransaction *transaction = [PPOTransaction new];
transaction.currency = @"GBP";
transaction.amount = @100;
transaction.transactionDescription = @"description";
transaction.merchantRef = @"dk93kl320";
transaction.isDeferred = @NO;

PPOCreditCard *card = [PPOCreditCard new];
card.pan = @"9900000000005159";
card.cvv = @"123";
card.expiry = @"0117";
card.cardHolderName = @"Bob Jones";

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

PPOFinancialServices *financialServices = [PPOFinancialServices new];
financialServices.dateOfBirth = @"19870818";
financialServices.surname = @"Smith";
financialServices.accountNumber = @"123ABC";
financialServices.postCode = @"BS20";

PPOPayment *payment = [PPOPayment new];
payment.transaction = transaction;
payment.card = card;
payment.address = address;
payment.customFields = [collector copy];
payment.financialServices = payment.financialServices;
```

To trigger a payment, set up an instance of  **PPOPaymentManager**, with a suitable baseURL.  A custom baseURL can be used, or a subset of pre-defined baseURL's can be found in **PPOPaymentBaseURLManager**, as follows:

```objective-c
NSURL *baseURL = [PPOPaymentBaseURLManager baseURLForEnvironment:PPOEnvironmentMerchantIntegrationTestingEnvironment];
PPOPaymentManager *paymentManager = [[PPOPaymentManager alloc] initWithBaseURL:baseURL];
```

Trigger a payment by passing an instance of **PPOPayment** and an instance of **PPOCredentials**, as follows:

```objective-c    
self.paymentManager makePayment:payment 
                    withTimeOut:60.0f
                 withCompletion:^(PPOOutcome *outcome) {
                        
                          if (outcome.error) {
                              //Handle failure
                          } else {
                              // Handle success
                          }
                          
                      }];
```


Some payments can sometimes take ~60 seconds to process, but the option to use a custom timeout is available here, should you want to provide a different value.  


# Testing your application in the MITE environment

PayPoint provide a Merchant Integration and Testing Environment (MITE), which lets you test your payment applications. 

In order to make test payments your server must obtain a client access token for your app, from our API. 

Instructions for doing this are available here:

TBD:  {TODO: placeholder for server-side authoriseClient call}

For convenience we provide a mock REST api which supplies these tokens for your test installations which can be used for prototyping your app in our MITE environment: 

## Mock Authorise Client Call

Perform a Get requests using the following URL. At this point, you should have your InstallationID ready.

```objective-c
NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://developer.paypoint.com/payments/explore/rest/mockmobilemerchant/getToken/%@", INSTALLATION_ID]];
```

Your should receive a HTTP Status code '200', indicating the call was successful. Parse the JSON data that is returned in the response payload. Extract the string value for key "accessToken" and build an intance of PPOCredentials, as follows.

```objective-c
PPOCredentials *credentials = [PPOCredentials new];
credentials.installationID = INSTALLATION_ID;
credentials.token = token;
```

Using this instance of PPOCredentials, you can now make a payment in our MITE testing environment.


## Test Cards

In the MITE environment you can use the standard test PANs for testing your applications (including 3DS test cards): 
[MITE test cards](https://developer.paypoint.com/payments/docs/#getting_started/test_cards)
