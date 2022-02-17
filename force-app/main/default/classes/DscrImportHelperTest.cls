@isTest
public with sharing class DscrImportHelperTest {
  static String testJson = '{"1":"[{\\"Loan ID\\":3243424,\\"Lender Name\\":\\"ChurChill\\",\\"Address\\":\\"456 Another St\\",\\"City\\":\\"Costa Mesa\\",\\"State\\":\\"CA\\",\\"Zip\\":\\"92627\\",\\"Property Type\\":\\"SFR\\",\\"Units\\":1,\\"Sqft\\":1100,\\"Origination Date\\":\\"2021-12-01T08:00:00.000Z\\",\\"Maturity Date\\":\\"2024-01-01T08:00:00.000Z\\",\\"Amortization Type (Fixed, IO, ADJ)\\":\\"IO\\",\\"IO Term\\":120,\\"Note Rate (%)\\":0.02,\\"Rate Type\\":\\"Fixed\\",\\" Total Loan Amount \\":800000,\\" 3rd Party AIV \\":50000,\\" Purchase Price \\":60000,\\" Total LTC \\":0.8,\\" LTV \\":0.85,\\" Leased (Y/N) \\":\\"Y\\",\\" Occupancy Status/Type \\":\\"Occupied/Short Term Rental\\",\\"DSCR Value\\":5.56,\\"Borrower Name\\":\\"456 Some Place Inc\\",\\"Guarantor Name\\":\\"Blaire Clutters\\",\\"Guarantor Email\\":\\"cluutersbl@gmailf.com\\",\\"Experience\\":2,\\"FICO\\":750,\\"Loan Purpose (Acquisition,Refi, or Cash out Refi)\\":\\"Refi\\",\\"Date of 1st Payment\\":\\"2022-02-02T08:00:00.000Z\\",\\"3rd Party Valuation Date\\":\\"2021-12-01T08:00:00.000Z\\",\\"3rd Party Valuation Type\\":\\"Exterior Appraisal\\",\\"3rd Party Valuation Provider\\":\\"AN\\",\\"Prepayment Type\\":\\"5/4/3/2/1\\",\\"Foreign National (Y/N)\\":\\"N\\"}]","2":"[{\\"a\\":\\"b\\"]"}';

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

    List<Lender_Deal_to_Deal__c> createdLenderD2Ds = DscrImportHelper.parseFileValues(
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
