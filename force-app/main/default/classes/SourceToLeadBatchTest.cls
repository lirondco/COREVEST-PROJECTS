@isTest
public with sharing class SourceToLeadBatchTest {
  @isTest
  public static void testSourceToLeadBatch() {
    Lead ld = new Lead();
    ld.LastName = 'Doe';
    ld.FirstName = 'John';
    ld.Company = 'Test';
    ld.Status = 'Open';
    ld.Phone = '5165266300';
    ld.Email = '5165266300@gmail.com';
    ld.Introduction_Source__c = 'Hotline';
    ld.Introduction_Subsource__c = 'Pardot';
    ld.Street = '123 test st';
    ld.City = 'Irvine';
    insert ld;

    Source__c src = [SELECT Id FROM Source__C WHERE Lead__c = :ld.Id];
    delete src;

    Test.startTest();
    Database.executeBatch(new SourceToLeadBatch());
    Test.stopTest();
  }

  @isTest
  public static void testSourceToLeadBatchException() {
    Lead ld = new Lead();
    ld.LastName = 'Doe';
    ld.FirstName = 'EXCEPTION';
    ld.Company = 'Test';
    ld.Status = 'Open';
    ld.Phone = '5165266300';
    ld.Email = '5165266300@gmail.com';
    ld.Introduction_Source__c = 'Hotline';
    ld.Introduction_Subsource__c = 'Pardot';
    ld.Street = '123 test st';
    ld.City = 'Irvine';
    insert ld;

    Source__c src = [SELECT Id FROM Source__C WHERE Lead__c = :ld.Id];
    delete src;

    Test.startTest();
    Database.executeBatch(new SourceToLeadBatch());
    Test.stopTest();
  }
}