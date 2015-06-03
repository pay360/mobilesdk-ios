# **Paypoint Payments iOS SDK**

**Requirements**  
* iOS 7+  
* XCode 5+  

**Dependencies**  
* UIKit.framework  
* SystemConfiguration.framework  
* CoreGraphics.framework  

# **Installation**

**CocoaPods**  
[CocoPods](https://cocoapods.org) is a dependency manager for Cocoa projects.  You can install it with the following command:

```
$ gem install cocoapods
```
To integrate the Paypoint Payments iOS SDK into your project using CocoaPods, specify it in your Podfile:

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '7.0'

pod 'PaypointSDK', '~> 1.0.0'
```
Then run the following command:

```
$ pod install
```

**Manually**  
If you prefer not to use the aforementioned dependency managers, you can integrate this SDK into your project manually.

* Download the Paypoint SDK.
* Enter Xcode and select "*File > Add Files to Project*".  Navigate to the directory where 'Paypoint.framework' was saved and select it.
* In Xcode, navigate to the target configuration window by clicking on the blue project icon, and selecting the application target under the "Targets" heading in the sidebar.
* Under the tab 'General', navigate to 'Linked Frameworks and Libraries'.
	* Ensure 'the 'Paypoint.framework' is listed there.  If not, select the '+' icon at the bottom of the list and select Paypoint.framework.  
	* Select the '+' icon at the bottom of this list and select each of the native iOS frameworks listed in the 'dependecies' section above.

# **Usage**

Each and every payment request must be coupled with a bearer token.  Please set up a means of acquiring a bearer token from Paypoint, before continuing on to a payment request.

**SIMPLE PAYMENT**  

An instance of **PPOCredentials** is required for each payment request.  To make a simple payment, first build an instance of PPOCredentials.

```
PPOCredentials *credentials = [PPOCredentials new];
credentials.installationID = INSTALLATION_ID;
credentials.token = bearerToken;
```

The PaypointSDK will throughly evaluate all paramers injected into a payment for their presence and validity.  However, you may want to validate your parameters incrementally, espeically if you are building UI elements that response to an incorrect card number, for example.

If you choose to validate an instance of PPOCredentials at this stage, there is public API available, which looks like the following:

```
NSError *invalidCredentials = [PPOPaymentValidator validateCredentials:credentials];
```

Build a representation of your payment, by instatiating an instance of **PPOPayment**.  This requires three parameters, each of which require information about your payment.

There is also the opportunity to provide custom fields here, which may be helpful.

```
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
transaction.isDeferred = @false;
    
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

PPOPayment *payment = [PPOPayment new];
payment.transaction = transaction;
payment.card = card;
payment.address = address;
payment.customFields = [collector copy];
```

To trigger a payment, set up an instance of  **PPOPaymentManager**, with a suitable baseURL.  A custom baseURL can be used, or a subset of pre-defined baseURL's can be found in **PPOPaymentBaseURLManager**, as follows:

```
NSURL *baseURL = [PPOPaymentBaseURLManager baseURLForEnvironment:PPOEnvironmentMerchantIntegrationTestingEnvironment];
PPOPaymentManager *paymentManager = [[PPOPaymentManager alloc] initWithBaseURL:baseURL];
```

Trigger a payment by passing an instance of **PPOPayment** and an instance of **PPOCredentials**, as follows:

```
    
[self.paymentManager makePayment:payment
                 withCredentials:credentials
                     withTimeOut:60.0f
                  withCompletion:^(PPOOutcome *outcome, NSError *paymentFailure) {
                      
                      if (paymentFailure) {
                          //Handle failure
                      } else {
                          // Handle success
                      }
                      
                  }];
```

Some payments can sometimes take ~60 seconds to process, but the option to use a quicker timeout is available here, should you want to.  

**Acknowledgements**  
Apple for Reachability.h  
Max Kramer for Luhn.h  



# **Test Credentials**

A test payment server is available using this as the baseURL http://ppmobilesdkstub.herokuapp.com/mobileapi

A test mechant server is available using this as the baseURL https://ppmobilesdkstub.herokuapp.com/merchant/getToken. 

See Demo app for example of retrieving the merchant token.

The following card numbers can be used for testing against the test payment server:

9900 0000 0000 5159 – returns successful authorisation.
9900 0000 0000 5282 – returns payment declined.
9900 0000 0000 0168 - returns successful authorisation but after a forced delay of 2 seconds
9900 0000 0001 0407 - server error

All other cards will return a server error.
