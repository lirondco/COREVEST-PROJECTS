@isTest
public with sharing class ExecSummaryControllerTest {
  @isTest
  public static void testMethod1() {
    List<String> icDocTypes = new List<String>{
      'Draft IC Memo',
      'Committee Memo'
    };

    Account testAcct = Test_Helper.createBorrowerAccount();
    Contact testCtc = Test_Helper.createBorContact(testAcct);
    Opportunity testDeal = Test_Helper.createTermDeal(testAcct, testCtc);

    Deal_Document__c testDoc = new Deal_Document__c(
        ContentVersion_Id__c = '1234',
        Attachment_Id__c = '5678',
        Document_Type__c = 'Draft IC Memo',
        File_Name__c = 'test.pdf',
        Deal__c = testDeal.Id
    );

    insert testDoc;

    String returnedVal = ExecSummaryController.getFileId(testDeal.Id);
    System.assertEquals(testDoc.Attachment_Id__c, returnedVal, 'File Id should be returned');
  }
}
