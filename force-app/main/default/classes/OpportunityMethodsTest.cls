@isTest
public with sharing class OpportunityMethodsTest {
  @isTest
  public static void testUpdatePaidOffProperties() {
    Account a = Test_Helper.createAccount();
    Contact c = Test_Helper.createContact(a);
    Opportunity sabdeal = new Opportunity();
    sabdeal.Name = 'test';
    sabdeal.CloseDate = System.today();
    sabdeal.StageName = 'Underwriting';
    sabdeal.Loan_Size__c = 2000000;
    sabdeal.AccountId = a.Id;
    sabdeal.Contact__c = c.Id;
    sabdeal.Deal_Intro_Source__c = 'Hotline';
    sabdeal.Deal_Intro_Sub_Source__c = 'Main';
    sabdeal.Apex_Context__c = true;
    sabdeal.LOC_Loan_Type__c = 'Single Asset (1-4 Unit)';
    sabdeal.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get('Single_Asset_Bridge_Loan')
      .getRecordTypeId();
    insert sabdeal;

    Property__c testProp = new Property__c(
      Deal__c = sabDeal.Id,
      Name = 'Test 123',
      Property_Name__c = 'Test 123',
      Property_Type__c = '2-4 Unit',
      Number_of_Units__c = 2,
      Interior_Access_POC_Email__c = 'test@test.com',
      Security_Deposit__c = 800,
      Status__c = 'Active'
    );

    insert testProp;

    sabdeal.StageName = 'Paid Off';
    sabdeal.Payoff_Date__c = System.today();

    update sabdeal;

    Map<Id, Opportunity> testOppMap = new Map<Id, Opportunity>{
      sabdeal.Id => sabdeal
    };

    OpportunityMethods.updatePaidOffProperties(testOppMap);

    Property__c updatedProp = [SELECT Id,Status__c FROM Property__c WHERE Id=:testProp.Id];

    System.assertEquals('Paid Off', updatedProp.Status__c, 'Property status should be Paid Off');
  }
}
