@isTest
public with sharing class AppraisalParseBatchTest {
  @isTest
  public static void testBatch() {
    StaticResource xml = [
      SELECT Id, Body
      FROM StaticResource
      WHERE Name = 'AppraisalXMLTest'
      LIMIT 1
    ];
    ContentVersion cv = new ContentVersion(
      Title = 'Test',
      PathOnClient = 'Test.xml',
      VersionData = xml.Body,
      IsMajorVersion = true
    );

    insert cv;
    Id docId = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :cv.Id
      LIMIT 1
    ]
    .ContentDocumentId;
    Account acc = Test_Helper.createAccount();
    Contact cont = Test_Helper.createContact(acc);
    Opportunity opp = Test_Helper.createOpportunity(acc, cont);
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE DeveloperName = 'Term_Loan' AND sobjecttype = 'Opportunity'
    ]
    .Id;
    List<Property__c> properties = Test_Helper.createProperties(opp);

    Deal_Document__c doc = new Deal_Document__c(
      Deal__c = opp.Id,
      Property__c = properties[0].Id,
      Document_Type__c = 'Valuations',
      Attachment_Id__c = docId
    );

    insert doc;

    Appraisal__c appraisal = new Appraisal__c(
      Property_Address__c = properties[0].Name,
      Deal_Document__c = doc.Id,
      Deal__c = opp.Id,
      Property__c = properties[0].Id
    );

    insert appraisal;

    Test.startTest();
    AppraisalParseBatch batch = new AppraisalParseBatch();
    Database.executeBatch(batch, 5);
    Test.stopTest();

    Appraisal__c appraisal2 = [
      SELECT
        Id,
        Appraisal_Replacement_Cost_Value__c,
        No_of_Stories__c,
        Property__c
      FROM Appraisal__c
      WHERE Id = :appraisal.Id
      LIMIT 1
    ];

    Property__c property = [
      SELECT Id, Name, Appraisal_Replacement_Cost_Value__c, No_of_Stories__c
      FROM Property__c
      WHERE Id = :appraisal.Property__c
      LIMIT 1
    ];

    System.assertEquals(
      100560,
      appraisal2.Appraisal_Replacement_Cost_Value__c,
      'Appraisal_Replacement_Cost_Value__c'
    );
    System.assertEquals(1, appraisal2.No_of_Stories__c, 'No_of_Stories__c');

    Boolean assertExpression =
      appraisal2.Appraisal_Replacement_Cost_Value__c ==
      property.Appraisal_Replacement_Cost_Value__c &&
      appraisal2.No_of_Stories__c == property.No_of_Stories__c;

    System.assertEquals(
      appraisal2.Appraisal_Replacement_Cost_Value__c,
      property.Appraisal_Replacement_Cost_Value__c,
      'The batch should\'ve updated the property__c.Appraisal_Replacement_Cost_Value__c as well'
    );
    System.assertEquals(
      appraisal2.No_of_Stories__c,
      property.No_of_Stories__c,
      'The batch should\'ve updated the property__c.No_of_Stories__c as well'
    );
  }
}
