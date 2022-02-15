@isTest
public with sharing class ExcelUploadLwcHelperTest {
    @TestSetup
    static void makeData() {
      Account a = Test_Helper.createAccount();
      Lender_Deal__c ld = new Lender_Deal__c();
      ld.Lender__c = a.Id;
      ld.Name = 'Test Lender Deal';
      ld.Stage__c = 'Initial Review';
  
      insert ld;
  
      ContentVersion content = new ContentVersion();
      content.Title = 'Excel_TEST';
      content.PathOnClient = '/' + content.Title + '.xlsx';
      Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body');
      content.VersionData = bodyBlob;
      //content.LinkedEntityId=sub.id;
      content.origin = 'H';
      insert content;
      ContentDocumentLink contentlink = new ContentDocumentLink();
      contentlink.LinkedEntityId = ld.id;
      contentlink.contentdocumentid = [
        SELECT contentdocumentid
        FROM contentversion
        WHERE id = :content.id
      ]
      .contentdocumentid;
      contentlink.ShareType = 'I';
      contentlink.Visibility = 'AllUsers';
  
      insert contentlink;
    }
    @isTest
    public static void testGetLastAttachment() {
      Lender_Deal__c ld = [
        SELECT Id
        FROM Lender_Deal__c
        WHERE Name = :'Test Lender Deal'
        LIMIT 1
      ];
  
      ContentDocumentLink cl = [
        SELECT Id, ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :ld.id
        LIMIT 1
      ];
  
      Map<String, String> returnedAttachmentMap = ExcelUploadLwcHelper.getLastAttachment(
        ld.id
      );
  
      System.assertEquals(
        cl.ContentDocumentId,
        returnedAttachmentMap.get('documentId'),
        'Expected 1 attachment'
      );
    }

    @isTest
    public static void testGetFileBody() {
      ContentVersion cv = [
        SELECT Id, VersionData
        FROM ContentVersion
        WHERE Title = :'Excel_TEST'
        LIMIT 1
      ];
      String expectedVersiondata = EncodingUtil.base64Encode(
        Blob.valueOf('Unit Test ContentVersion Body')
      );
      System.assertEquals(
        expectedVersiondata,
        ExcelUploadLwcHelper.getFileBody(cv.id),
        'Expected file body to match'
      );
    }
  
}
