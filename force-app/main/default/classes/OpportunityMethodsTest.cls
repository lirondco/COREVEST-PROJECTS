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
    sabdeal.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
      .get('Single_Asset_Bridge_Loan')
      .getRecordTypeId();
    insert sabdeal;

    Map<Id, Opportunity> testOppMap = new Map<Id, Opportunity>{
      sabdeal.Id => sabdeal
    };
    Property__c testProp = new Property__c(
      Deal__c = o.Id,
      Name = i + ' Test',
      Property_Name__c = i + ' Test',
      Property_Type__c = 'SFR',
      Number_of_Units__c = 1,
      Interior_Access_POC_Email__c = 'test@test.com',
      Security_Deposit__c = 800,
      Status__c = 'Active'
    );

    insert testProp;

    
  }
}
