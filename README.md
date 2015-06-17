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


# Testing your application in the MITE environment

PayPoint provide a Merchant Integration and Testing Environment (MITE), which lets you test your payment applications. In order to make test payments your server must obtain a client access token for your app, from our API. Instructions for doing this are available here:

TBD:  {TODO: placeholder for server-side authoriseClient call}

For convenience we provide a mock REST api which supplies these tokens for your test installations which can be used for prototyping your app in our MITE environment: 

## Mock Authorise Client Call

***TBD more detail about sign up here ?***

Perform a Get requests using the following URL. At this point, you should have your InstallationID ready. If you do not, please head over to the Paypoint Explorer page and sign up.

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

## Making a Payment 

The PaypointSDK will evaluate all parameters injected into a payment for their presence and validity.  These methods are exposed as public API and are available if you want to validate inline with the UI.

At this point, you should have an instance of PPOCredentials ready. If you do not, please see 'Mock Authorise Client Call' above. If you choose to validate an instance of PPOCredentials at this stage, there is public API available, which looks like the following:

```objective-c
NSError *invalidCredentials = [PPOPaymentValidator validateCredentials:credentials];
```

Build a representation of your payment, by preparing an instance of **PPOPayment**.

```objective-c
PPOPayment *payment = [PPOPayment new];
payment.credentials = credentials;
```

Prepare an instance of your transaction and card details, by preparing an instance of PPOTransaction and PPOCreditCard, like so (When 'isDeferred' is set to 'YES' the payment will be an Authorisation.)

```ojective-c
PPOTransaction *transaction = [PPOTransaction new];
transaction.currency = @"GBP";
transaction.amount = @100;
transaction.transactionDescription = @"description";
transaction.merchantRef = @"dk93kl320";
transaction.isDeferred = @NO;

payment.transaction = transaction;

PPOCreditCard *card = [PPOCreditCard new];
card.pan = @"9900000000005159";
card.cvv = @"123";
card.expiry = @"0117";
card.cardHolderName = @"Bob Jones";

payment.card = card;
```

You may also want to provide a billing address, by providing an instance of PPOBillingAddress, like so.

```objective-c
PPOBillingAddress *address = [PPOBillingAddress new];
address.line1 = @"House name";
address.line2 = @"Steet";
address.city = @"Bristol";
address.region = @"Somerset";
address.postcode = @"BS32";

payment.address = address;
```

You may also want to provide custom fields, by building instances of PPOCustomField, like so.


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

You may also want to provide financial services details, by building an instance of PPOFinancialServices, like so.

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


## Test Cards

In the MITE environment you can use the standard test PANs for testing your applications (including 3DS test cards): 
[MITE test cards](https://developer.paypoint.com/payments/docs/#getting_started/test_cards)
