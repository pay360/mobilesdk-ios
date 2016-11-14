//
//  Pay360LibraryTests.m
//  Pay360
//
//  Created by Robert Nash on 23/04/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

//SDK
#import "Pay360.h"

#define VALID_BEARER_TOKEN @"VALID_TOKEN"
#define EXPIRED_BEARER_TOKEN @"EXPIRED_TOKEN"
#define UNAUTHORISED_BEARER_TOKEN @"UNAUTHORISED_TOKEN"
#define AUTHORISED_PAN @"9900000000005159"
#define DECLINE_PAN @"9900000000005282"
#define DELAY_AUTHORISED_PAN @"9900000000000168"
#define SERVER_ERROR_PAN @"9900000000010407"
#define INSTALLATION_ID @"5300311"

@interface Pay360LibraryTests : XCTestCase
@property (nonatomic, strong) NSArray *pans;
@property (nonatomic) PPOEnvironment currentEnvironment;
@property (nonatomic, strong) NSURL *baseURL;
@end

@implementation Pay360LibraryTests

- (void)setUp {
    [super setUp];
    
    self.pans = @[
                  AUTHORISED_PAN,
                  DECLINE_PAN,
                  DELAY_AUTHORISED_PAN,
                  SERVER_ERROR_PAN
                  ];
    
    self.baseURL = [NSURL URLWithString:@"http://localhost:5000"];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Local Validation (Good Pan & Good Token)

-(void)testCardValidation {
    
    for (NSString *pan in self.pans) {
        NSError *error = [PPOValidator validateCardPan:pan];
        NSAssert((error == nil), @"Pan validation failed");
    }
}

-(void)testBaseURLManager {
    
    NSURL *baseURL;
    
    for (PPOEnvironment e = PPOEnvironmentMerchantIntegrationTestingEnvironment; e < PPOEnvironmentTotalCount; e++) {
        
        baseURL = [PPOPaymentBaseURLManager baseURLForEnvironment:e];
        
        switch (e) {
                
            case PPOEnvironmentMerchantIntegrationTestingEnvironment:
                NSAssert([baseURL.absoluteString isEqualToString:@"https://mobileapi.mite.pay360.com"], @"Base URL unexpected");
                break;
                
            case PPOEnvironmentMerchantIntegrationProductionEnvironment:
                NSAssert([baseURL.absoluteString isEqualToString:@"https://mobileapi.pay360.com"], @"Base URL unexpected");
                break;
                
            default:
                break;
        }
        
    }
    
}

-(void)testPaymentWithFinancialServicesAndCustomer {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Valid payment with financial services"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:AUTHORISED_PAN];
    payment.customer = [self customer];
    payment.financialServices = [self financialServices];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:self.baseURL];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if (!outcome.error) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
    
}

-(void)testSimplePaymentWithInvalidAmount {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment amount invalid"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:nil];
    payment.card = [self creditCardWithPan:AUTHORISED_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:self.baseURL];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOLocalValidationErrorDomain] && outcome.error.code == PPOLocalValidationErrorPaymentAmountInvalid) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
    
}

-(void)testSimplePaymentWithCustomFields {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment amount invalid"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:AUTHORISED_PAN];
    payment.customFields = [self customFields];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:self.baseURL];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if (!outcome.error && outcome.customFields.count == 3) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
    
}

-(void)testSimplePaymentWithInvalidCVV {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment card cvv invalid"];
    
    PPOCard *card = [self creditCardWithPan:AUTHORISED_PAN];
    card.cvv = nil;
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = card;
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:self.baseURL];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOLocalValidationErrorDomain] && outcome.error.code == PPOLocalValidationErrorCVVInvalid) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
}

-(void)testSimplePaymentWithAuthorisedPan {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment succeeded"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:AUTHORISED_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:self.baseURL];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if (!outcome.error) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
    
}

-(void)testSimplePaymentWithExpiredBearerToken {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment bearer token expired"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:AUTHORISED_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:self.baseURL];
    
    payment.credentials = [self credentialsWithToken:EXPIRED_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOPaymentErrorDomain] && outcome.error.code == PPOPaymentErrorClientTokenExpired) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
    
}

-(void)testSimplePaymentWithUnauthorisedBearerToken {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment bearer token unauthorised"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:AUTHORISED_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:self.baseURL];
    
    payment.credentials = [self credentialsWithToken:UNAUTHORISED_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOPaymentErrorDomain] && outcome.error.code == PPOPaymentErrorUnauthorisedRequest) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
}

#pragma mark - Good Token & Bad Pan

-(void)testSimplePaymentWithDeclinePan {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment processing failed"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:DECLINE_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:self.baseURL];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOPaymentErrorDomain] && outcome.error.code == PPOPaymentErrorTransactionDeclined) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
}

-(void)testSimplePaymentWithDeclinePanWithCustomFields {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment processing failed"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:DECLINE_PAN];
    payment.customFields = [self customFields];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:self.baseURL];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if (outcome.customFields.count > 0) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
}

-(void)testSessionTimeout {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment timedout"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:DELAY_AUTHORISED_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:self.baseURL];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:1.0
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOPaymentErrorDomain] && outcome.error.code == PPOPaymentErrorMasterSessionTimedOut) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:3.0
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
}

-(void)testSimplePaymentWithServerErrorPan {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment server error"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:SERVER_ERROR_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:self.baseURL];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOPaymentErrorDomain] && outcome.error.code == PPOPaymentErrorServerFailure) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
}

-(PPOTransaction*)transactionWithAmount:(NSNumber*)amount {
    PPOTransaction *transaction;
    transaction = [PPOTransaction new];
    transaction.currency = @"GBP";
    transaction.amount = amount;
    transaction.transactionDescription = @"A desc";
    transaction.merchantRef = [NSString stringWithFormat:@"mer_%.0f", [[NSDate date] timeIntervalSince1970]];
    transaction.isDeferred = @NO;
    return transaction;
}

-(PPOCard*)creditCardWithPan:(NSString*)pan {
    PPOCard *card = [PPOCard new];
    card.pan = pan;
    card.cvv = @"123";
    card.expiry = @"0116";
    card.cardHolderName = @"Dai Jones";
    return card;
}

-(PPOFinancialService*)financialServices {
    PPOFinancialService *financialServices = [PPOFinancialService new];
    financialServices.dateOfBirth = @"19870818";
    financialServices.surname = @"Smith";
    financialServices.accountNumber = @"123ABC";
    financialServices.postCode = @"BS20";
    return financialServices;
}

-(PPOCustomer*)customer {
    PPOCustomer *customer = [PPOCustomer new];
    customer.email = @"test@example.com";
    customer.dateOfBirth = @"1900-01-01";
    customer.telephone = @"01225 123456";
    return customer;
}

-(PPOCredentials*)credentialsWithToken:(NSString*)token {
    PPOCredentials *credentials = [PPOCredentials new];
    credentials.token = token;
    credentials.installationID = INSTALLATION_ID;
    return credentials;
}

-(NSSet*)customFields {
    NSMutableSet *collector = [NSMutableSet new];
    
    PPOCustomField *customField;
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
    
    return [collector copy];
}

@end