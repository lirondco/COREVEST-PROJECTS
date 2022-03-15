@isTest
public with sharing class CAFTestingClassTest {
  @isTest
  public static void testCAFEmail() {
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    Id termLoanRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
      .get('Bridge Loan')
      .getRecordTypeId();
    opp.RecordTypeId = termLoanRecordTypeId;
    opp.LOC_Program_Type__c = 'Custom';
    opp.Approved_Term_Sheet_Name__c = null;
    update opp;

    Document_Structure__mdt docStruct = [
      SELECT Id
      FROM Document_Structure__mdt
      LIMIT 1
    ];
    Deal_Document__c doc = new Deal_Document__c(
      Deal__c = opp.Id,
      Document_Structure_Id__c = docStruct.Id,
      Document_Type__c = 'CAF Application'
    );

    insert doc;

    ContentVersion cv = new Contentversion();
    cv.title = 'ABC';
    cv.PathOnClient = 'test';
    Blob b = Blob.valueOf('Unit Test Attachment Body');
    cv.versiondata = EncodingUtil.base64Decode('Unit Test Attachment Body');
    insert cv;

    doc.ContentVersion_Id__c = cv.Id;

    update doc;
  }
}