@isTest
public with sharing class ExecSummaryControllerTest {
  @TestSetup
  static void makeData() {
    Account a = Test_Helper.createAccount();
    Contact c = Test_Helper.createContact(a);
    Opportunity d = Test_Helper.createBridgeDeal(a, c);
    Contentversion cv = new Contentversion();
    cv.Title = 'test.pdf';
    cv.PathOnClient = 'test.pdf';
    cv.VersionData = EncodingUtil.base64Decode(
      EncodingUtil.urlEncode('Unit Test Attachment Body', 'UTF-8')
    );
    insert cv;
    Id docId = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :cv.Id
      LIMIT 1
    ]
    .ContentDocumentId;
    Deal_Document__c doc = new Deal_Document__c(
      Deal__c = d.Id,
      Document_Type__c = 'Draft IC Memo',
      ContentVersion_Id__c =cv.Id,
      Attachment_Id__c = docId,
      File_Name__c = 'test.pdf'
    );

    insert doc;
  }

  @isTest
  public static void testGetFileId() {
      Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
      ExecSummaryController.getFileId(opp.Id);
  }
}