@isTest
public with sharing class PropertyTriggerExtensionsTest {
  @TestSetup
  static void makeData() {
    Account a = Test_Helper.createAccount();
    Contact c = Test_Helper.createContact(a);
    Opportunity o = Test_Helper.createBridgeDeal(a, c);
    List<Property__c> properties = new List<Property__c>();
    for (Integer i = 0; i < 10; i++) {
      properties.add(
        new Property__c(
          Deal__c = o.Id,
          Name = i + ' Test',
          Property_Name__c = i + ' Test',
          Property_Type__c = 'SFR',
          Number_of_Units__c = 1,
          Interior_Access_POC_Email__c = 'test@test.com',
          Security_Deposit__c = 800,
          BPO_Appraisal_Firm__c = 'Test',
          Status__c = 'Inactive'
        )
      );
    }
    insert properties;
  }
  @isTest
  public static void testStatusChanges() {
    Opportunity deal = [SELECT Id FROM Opportunity LIMIT 1];
    List<Property__c> props = [
      SELECT Id, Status__c
      FROM Property__c
      WHERE Deal__c = :deal.Id
    ];

    Test.startTest();
    Advance__c adv = new Advance__c(Deal__c = deal.Id, Name = 'TBD');
    insert adv;

    List<Property_Advance__c> padv = new List<Property_Advance__c>{
      new Property_Advance__c(Property__c = props[0].Id, Advance__c = adv.Id),
      new Property_Advance__c(Property__c = props[1].Id, Advance__c = adv.Id)
    };
    insert padv;

    Map<Id, Property__c> oldPropMap = new Map<Id, Property__c>{
      props[0].Id => new Property__c(Id = props[0].Id, Status__c = 'Inactive')
    };
    Map<Id, Property__c> newPropMap = new Map<Id, Property__c>{
      props[0].Id => new Property__c(Id = props[0].Id, Status__c = 'Cancelled')
    };

    PropertyTriggerExtensions.checkStatusChanges(oldPropMap, newPropMap);
    List<Property_Advance__c> padv2 = [
      SELECT Id
      FROM Property_Advance__c
      WHERE Advance__c = :adv.Id
    ];
    System.assertNotEquals(
      padv.size(),
      padv2.size(),
      'Property_Advance__c records were not deleted'
    );

    Map<Id, Property__c> oldPropMap1 = new Map<Id, Property__c>{
      props[1].Id => new Property__c(Id = props[1].Id, Status__c = 'Inactive')
    };
    Map<Id, Property__c> newPropMap1 = new Map<Id, Property__c>{
      props[1].Id => new Property__c(Id = props[1].Id, Status__c = 'Active')
    };
    update newPropMap1.values();
    PropertyTriggerExtensions.checkStatusChanges(oldPropMap1, newPropMap1);
    Map<Id, Advance__c> adv2 = new Map<Id, Advance__c>(
      [SELECT Id, Property_Count__c, Name FROM Advance__c WHERE Id = :adv.Id]
    );
    System.assertEquals(
      '1',
      adv2.values()[0].Name,
      'Advance__c record was not updated'
    );
    Test.stopTest();
  }

  @isTest
  public static void testAdvanceDeletion() {
    Opportunity deal = [SELECT Id FROM Opportunity LIMIT 1];
    List<Property__c> props = [
      SELECT Id, Status__c
      FROM Property__c
      WHERE Deal__c = :deal.Id
      LIMIT 2
    ];
    Test.startTest();
    Advance__c adv = new Advance__c(Deal__c = deal.Id, Name = 'TBD');
    insert adv;
    List<Property_Advance__c> padv = new List<Property_Advance__c>{
      new Property_Advance__c(Property__c = props[0].Id, Advance__c = adv.Id),
      new Property_Advance__c(Property__c = props[1].Id, Advance__c = adv.Id)
    };
    insert padv;

    Map<Id, Advance__c> oldMap = new Map<Id, Advance__c>(
      [SELECT Id, Property_Count__C FROM Advance__c WHERE Id = :adv.Id]
    );

    delete padv;
    Map<Id, Advance__c> newMap = new Map<Id, Advance__c>(
      [SELECT Id, Property_Count__C FROM Advance__c WHERE Id = :adv.Id]
    );

    PropertyTriggerExtensions.checkAdvancesPropertyCount(oldMap, newMap);

    List<Advance__c> advsExpectedEmpty = [
      SELECT Id
      FROM Advance__c
      WHERE Id = :adv.Id
    ];
    System.assertEquals(
      0,
      advsExpectedEmpty.size(),
      'Advance__c record was not deleted'
    );
    Test.stopTest();
  }

  @isTest
  public static void testPropAdvanceStatuses() {
    Opportunity deal = [SELECT Id FROM Opportunity LIMIT 1];
    List<Property__c> props = [
      SELECT Id, Status__c
      FROM Property__c
      WHERE Deal__c = :deal.Id
      LIMIT 2
    ];
    Test.startTest();

    for (Property__c p : props) {
      p.Status__c = 'Active';
    }
    update props;

    Advance__c adv = new Advance__c(Deal__c = deal.Id, Name = 'TBD');
    insert adv;
    List<Property_Advance__c> padv = new List<Property_Advance__c>{
      new Property_Advance__c(Property__c = props[0].Id, Advance__c = adv.Id),
      new Property_Advance__c(Property__c = props[1].Id, Advance__c = adv.Id)
    };
    insert padv;

    Map<Id, Property_Advance__c> propAdvMap = new Map<Id, Property_Advance__c>(
      [
        SELECT Id, Advance__c, Property__c
        FROM Property_Advance__c
        WHERE Advance__c = :adv.Id
      ]
    );

    PropertyTriggerExtensions.checkAdvancePropertyStatuses(propAdvMap);
    Advance__c advWithName = [
      SELECT Id, Name
      FROM Advance__c
      WHERE Id = :adv.Id
    ];
    System.assertEquals(
      '1',
      advWithName.Name,
      'Advance__c record was not updated'
    );
    Test.stopTest();
  }

  @isTest
  public static void testAdvNameChange() {
    Opportunity deal = [SELECT Id FROM Opportunity LIMIT 1];
    List<Property__c> props = [
      SELECT Id, Status__c
      FROM Property__c
      WHERE Deal__c = :deal.Id
      LIMIT 2
    ];
    Test.startTest();

    Advance__c adv = new Advance__c(Deal__c = deal.Id, Name = 'TBD');
    insert adv;
    List<Property_Advance__c> padv = new List<Property_Advance__c>{
      new Property_Advance__c(Property__c = props[0].Id, Advance__c = adv.Id),
      new Property_Advance__c(Property__c = props[1].Id, Advance__c = adv.Id)
    };
    insert padv;

    Map<Id, Advance__c> advMap = new Map<Id, Advance__c>{
      adv.Id => new Advance__c(Id = adv.Id, Name = '1')
    };

    Boolean hasException = false;

    try {
      PropertyTriggerExtensions.validateAdvanceNames(advMap);
    } catch (Exception err) {
      hasException = true;
    }
    System.assertEquals(true, hasException, 'Exception was not thrown');

    Test.stopTest();
  }
}
