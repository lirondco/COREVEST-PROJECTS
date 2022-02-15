@isTest
public with sharing class BridgeLenderDealImportHelperTest {
  static String testJson = '{"1":"[{\\"Loan ID\\":\\"12345\\",\\"Lender Name\\":\\"Lender ABC\\",\\"Address\\":\\"123 Test St\\",\\"City\\":\\"Costa Mesa\\",\\"State\\":\\"CA\\",\\"Zip\\":\\"92627\\",\\"Property Type\\":\\"Single Family\\",\\"Units\\":\\"1\\",\\"Sqft\\":\\"1200\\",\\"Loan Purpose (Refi, Purchase, Cash out Ref)\\":\\"Refi\\",\\"Program Type (Fix and Flip, Aggregation, GUC, BTR)\\":\\"Fix and Flip\\",\\"Origination Date\\":\\"2021-01-01T08:00:00.000Z\\",\\"Maturity Date\\":\\"2021-01-01T08:00:00.000Z\\",\\"Note Rate (%)\\":\\"0.02\\",\\" Total Loan Amount \\":\\"1000000\\",\\" Current UPB \\":\\"1000000\\",\\" Initial Draw \\":\\"500000\\",\\" Rehab Holdback \\":\\"500000\\",\\" Current Holdback Balance \\":\\"400000\\",\\" Interest Holdback \\":\\"90000\\",\\"Dutch/Non-Dutch \\\\r\\\\n(True/ False)\\":\\"false\\",\\" Construction Budget \\":\\"70000\\",\\" Property Purchase Price \\":\\"100000\\",\\" AIV \\":\\"150000\\",\\" ARV \\":\\"200000\\",\\"LTC\\":\\"0.75\\",\\"Total LTC\\":\\"0.9\\",\\"AILTV\\":\\"0.9\\",\\"ARLTV\\":\\"0.9\\",\\"Borrower Name\\":\\"The Borrower LLC\\",\\"Experience\\":\\"7\\",\\"FICO\\":\\"800\\",\\"Guarantor Name\\":\\"Bill Guarantor\\",\\"Guarantor Email\\":\\"bigg@guarantor.com\\",\\"Date of 1st Payment\\":\\"2021-01-01T08:00:00.000Z\\",\\"3rd Party Valuation Date\\":\\"2021-01-01T08:00:00.000Z\\",\\"3rd Party Valuation Type\\":\\"Interior\\",\\" 3rd Party AIV \\":\\"150000\\",\\" 3rd Party ARV \\":\\"200000\\",\\"3rd Party Valuation Provider\\":\\"Appraisal Nation\\"}]","2":"[{\\"a\\":\\"b\\"]"}';

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
  public static void testParseFileValues() {
    Lender_Deal__c ld = [
      SELECT Id
      FROM Lender_Deal__c
      WHERE Name = :'Test Lender Deal'
      LIMIT 1
    ];

    List<Lender_Deal_to_Deal__c> createdLenderD2Ds = BridgeLenderDealImportHelper.parseFileValues(
      testJson,
      ld.id
    );

    System.assertEquals(
      1,
      createdLenderD2Ds.size(),
      'Expected 1 Lender_Deal_to_Deal__c'
    );
    System.assertEquals(
      ld.Id,
      createdLenderD2Ds[0].Lender_Deal__c,
      'Expected Lender_Deal__c'
    );
  }
}

