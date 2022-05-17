@isTest
/**
 * NOTE TO DEVS:
 * This test class is getting a little bit too massive. If you're adding to it,
 * please create a new method for your specific test instead of attaching to existing ones
 * to prevent DML / SOQL Limit issues.
 * Thank you.
 *
 * Болшае спасибо,
 * - Liron
 **/

public with sharing class opportunity_Tests {
  @TestSetup
  static void dataSetup() {
    Account acc = test_Helper.createAccount();

    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);

    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'TERM TEST 123';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Initial Review';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.Final_Loan_Amount__c = 100;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.Term_Loan_Type__c = '5 Year';
    topp1.YM_Prepayment_Penalty__c = '48 Months';
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;
  }

  static testMethod void opportunity_TermTest01() {
    Opportunity topp1 = [
      SELECT Id
      FROM Opportunity
      WHERE Name = 'TERM TEST 123'
      LIMIT 1
    ];

    Test.startTest();
    Securitization__c sec = test_Helper.createSecuritization();

    topp1.Term_Sheet_Issued__c = System.today();
    update topp1;

    topp1.Trigger_Field__c = 'Originations Model;Model Name Test';
    update topp1;

    Test.stopTest();
  }

  static testMethod void opportunity_TermTest02() {
    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser1@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com'
    );
    //insert p;
    insert origU;

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser2@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator2@teada.com'
    );
    //insert p;
    insert origU2;

    User origU3 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator3@teada.com'
    );
    //insert p;
    insert origU3;

    User origU4 = new User(
      Alias = 'orig',
      Email = 'standarduser4@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator4@teada.com'
    );
    //insert p;
    insert origU4;

    User analystU = new User(
      Alias = 'analyst',
      Email = 'standarduser5@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst@teada.com'
    );
    //insert p;
    insert analystU;

    User analystU2 = new User(
      Alias = 'analyst',
      Email = 'standarduser6@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst2@teada.com'
    );
    //insert p;
    insert analystU2;

    User analystU3 = new User(
      Alias = 'analyst',
      Email = 'standarduser7@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst3@teada.com'
    );
    //insert p;
    insert analystU3;

    User analystU4 = new User(
      Alias = 'analyst',
      Email = 'standarduser8@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst4@teada.com'
    );
    //insert p;
    insert analystU4;

    User uwU = new User(
      Alias = 'underw',
      Email = 'standarduser9@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter@teada.com'
    );
    //insert p;
    insert uwU;

    User uwU2 = new User(
      Alias = 'underw',
      Email = 'standarduser10@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter2@teada.com'
    );
    //insert p;
    insert uwU2;

    User lcU = new User(
      Alias = 'loanco',
      Email = 'standarduser11@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord1@teada.com'
    );
    //insert p;
    insert lcU;

    User lcU2 = new User(
      Alias = 'loanco',
      Email = 'standarduser12@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord2@teada.com'
    );
    //insert p;
    insert lcU2;

    User closerU = new User(
      Alias = 'clos',
      Email = 'standarduser13@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer1@teada.com'
    );
    //insert p;
    insert closerU;

    User closerU2 = new User(
      Alias = 'clos',
      Email = 'standarduser14@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada.com'
    );
    //insert p;
    insert closerU2;

    Opportunity topp1 = [
      SELECT Id
      FROM Opportunity
      WHERE Name = 'TERM TEST 123'
      LIMIT 1
    ];

    Test.startTest();
    Securitization__c sec = test_Helper.createSecuritization();

    topp1.Term_Sheet_Issued__c = System.today();
    topp1.Trigger_Field__c = 'Originations Model;Model Name Test';
    topp1.Pres_Deal_Id__c = '123';
    //topp1.StageName = 'Term Sheet Issued';
    topp1.Loan_Effective_Date__c = System.today();
    topp1.Deal_Intro_Source__c = 'Email';
    topp1.Bridge_Borrower__c = 'No';
    topp1.Are_Assets_Coming_Off_Bridge_Line__c = 'No';
    topp1.Term_Sheet_Signed__c = System.today();
    topp1.OwnerId = origU.Id;
    topp1.CAF_Analyst__c = analystU.Id;
    topp1.Second_Production_Analyst__c = analystU3.Id;
    topp1.Co_Originator__c = origU3.Id;
    update topp1;

    Test.stopTest();
  }

  static testMethod void opportunity_TermTest03() {
    List<User> newUsers = new List<User>();
    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com'
    );
    //insert p;
    insert origU;

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator2@teada.com'
    );
    //insert p;
    insert origU2;

    User origU3 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator3@teada.com'
    );
    //insert p;
    insert origU3;

    User origU4 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator4@teada.com'
    );
    //insert p;
    insert origU4;

    User analystU = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst@teada.com'
    );
    //insert p;
    insert analystU;

    User analystU2 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst2@teada.com'
    );
    //insert p;
    insert analystU2;

    User analystU3 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst3@teada.com'
    );
    //insert p;
    insert analystU3;

    User analystU4 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst4@teada.com'
    );
    //insert p;
    insert analystU4;

    User uwU = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter@teada.com'
    );
    //insert p;
    insert uwU;

    User uwU2 = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter2@teada.com'
    );
    //insert p;
    insert uwU2;

    User lcU = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord1@teada.com'
    );
    //insert p;
    insert lcU;

    User lcU2 = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord2@teada.com'
    );
    //insert p;
    insert lcU2;

    User closerU = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer1@teada.com'
    );
    //insert p;
    insert closerU;

    User closerU2 = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada.com'
    );
    //insert p;
    insert closerU2;

    Opportunity topp1 = [
      SELECT Id
      FROM Opportunity
      WHERE Name = 'TERM TEST 123'
      LIMIT 1
    ];

    Test.startTest();
    Securitization__c sec = test_Helper.createSecuritization();

    topp1.Term_Sheet_Issued__c = System.today();
    topp1.Trigger_Field__c = 'Originations Model;Model Name Test';
    topp1.Pres_Deal_Id__c = '123';
    //topp1.StageName = 'Term Sheet Issued';
    topp1.Loan_Effective_Date__c = System.today();
    topp1.Deal_Intro_Source__c = 'Email';
    topp1.Bridge_Borrower__c = 'No';
    topp1.Are_Assets_Coming_Off_Bridge_Line__c = 'No';
    topp1.Term_Sheet_Signed__c = System.today();
    topp1.OwnerId = origU.Id;
    topp1.CAF_Analyst__c = analystU.Id;
    topp1.Second_Production_Analyst__c = analystU3.Id;
    topp1.Co_Originator__c = origU3.Id;
    topp1.IO_Term__c = '0 months';
    topp1.Deposit_Amount__c = 0;
    topp1.Deposit_Collected__c = System.today();
    topp1.Deposit_Fed_Reference__c = 'adfaf';
    topp1.Broker_Fees_and_or_YSP__c = 'adffda';
    topp1.Property_Management__c = 'Third Party';
    update topp1;
    Test.stopTest();
  }

  static testMethod void opportunity_TermTest04() {
    List<User> newUsers = new List<User>();
    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com'
    );
    //insert p;
    insert origU;

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator2@teada.com'
    );
    //insert p;
    insert origU2;

    User origU3 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator3@teada.com'
    );
    //insert p;
    insert origU3;

    User origU4 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator4@teada.com'
    );
    //insert p;
    insert origU4;

    User analystU = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst@teada.com'
    );
    //insert p;
    insert analystU;

    User analystU2 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst2@teada.com'
    );
    //insert p;
    insert analystU2;

    User analystU3 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst3@teada.com'
    );
    //insert p;
    insert analystU3;

    User analystU4 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst4@teada.com'
    );
    //insert p;
    insert analystU4;

    User uwU = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter@teada.com'
    );
    //insert p;
    insert uwU;

    User uwU2 = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter2@teada.com'
    );
    //insert p;
    insert uwU2;

    User lcU = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord1@teada.com'
    );
    //insert p;
    insert lcU;

    User lcU2 = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord2@teada.com'
    );
    //insert p;
    insert lcU2;

    User closerU = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer1@teada.com'
    );
    //insert p;
    insert closerU;

    User closerU2 = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada.com'
    );
    //insert p;
    insert closerU2;

    Opportunity topp1 = [
      SELECT Id
      FROM Opportunity
      WHERE Name = 'TERM TEST 123'
      LIMIT 1
    ];

    Test.startTest();
    Securitization__c sec = test_Helper.createSecuritization();

    topp1.Term_Sheet_Issued__c = System.today();
    topp1.Trigger_Field__c = 'Originations Model;Model Name Test';
    topp1.Pres_Deal_Id__c = '123';
    //topp1.StageName = 'Term Sheet Issued';
    topp1.Loan_Effective_Date__c = System.today();
    topp1.Deal_Intro_Source__c = 'Email';
    topp1.Bridge_Borrower__c = 'No';
    topp1.Are_Assets_Coming_Off_Bridge_Line__c = 'No';
    topp1.Term_Sheet_Signed__c = System.today();
    topp1.OwnerId = origU.Id;
    topp1.CAF_Analyst__c = analystU.Id;
    topp1.Second_Production_Analyst__c = analystU3.Id;
    topp1.Co_Originator__c = origU3.Id;
    topp1.IO_Term__c = '0 months';
    topp1.Deposit_Amount__c = 0;
    topp1.Deposit_Collected__c = System.today();
    topp1.Deposit_Fed_Reference__c = 'adfaf';
    topp1.Broker_Fees_and_or_YSP__c = 'adffda';
    topp1.Property_Management__c = 'Third Party';
    topp1.StageName = 'Underwriting';
    topp1.Current_Loan_Amount__c = 2000000;
    topp1.Underwriter__c = uwU.Id;
    topp1.Loan_Coordinator__c = lcU.Id;
    topp1.Closer__c = closerU.Id;
    topp1.Kickoff_Date__c = System.today();
    // topp1.Commission_Type__c = 'Direct';
    update topp1;
    Test.stopTest();
  }

  static testMethod void opportunity_TermTest05() {
    List<User> newUsers = new List<User>();
    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com'
    );
    //insert p;
    insert origU;

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator2@teada.com'
    );
    //insert p;
    insert origU2;

    User origU3 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator3@teada.com'
    );
    //insert p;
    insert origU3;

    User origU4 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator4@teada.com'
    );
    //insert p;
    insert origU4;

    User analystU = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst@teada.com'
    );
    //insert p;
    insert analystU;

    User analystU2 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst2@teada.com'
    );
    //insert p;
    insert analystU2;

    User analystU3 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst3@teada.com'
    );
    //insert p;
    insert analystU3;

    User analystU4 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst4@teada.com'
    );
    //insert p;
    insert analystU4;

    User uwU = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter@teada.com'
    );
    //insert p;
    insert uwU;

    User uwU2 = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter2@teada.com'
    );
    //insert p;
    insert uwU2;

    User lcU = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord1@teada.com'
    );
    //insert p;
    insert lcU;

    User lcU2 = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord2@teada.com'
    );
    //insert p;
    insert lcU2;

    User closerU = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer1@teada.com'
    );
    //insert p;
    insert closerU;

    User closerU2 = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada.com'
    );
    //insert p;
    insert closerU2;

    Opportunity topp1 = [
      SELECT Id
      FROM Opportunity
      WHERE Name = 'TERM TEST 123'
      LIMIT 1
    ];

    Test.startTest();
    Securitization__c sec = test_Helper.createSecuritization();

    topp1.Term_Sheet_Issued__c = System.today();
    topp1.Trigger_Field__c = 'Originations Model;Model Name Test';
    topp1.Pres_Deal_Id__c = '123';
    //topp1.StageName = 'Term Sheet Issued';
    topp1.Loan_Effective_Date__c = System.today();
    topp1.Deal_Intro_Source__c = 'Email';
    topp1.Bridge_Borrower__c = 'No';
    topp1.Are_Assets_Coming_Off_Bridge_Line__c = 'No';
    topp1.Term_Sheet_Signed__c = System.today();
    topp1.OwnerId = origU.Id;
    topp1.CAF_Analyst__c = analystU.Id;
    topp1.Second_Production_Analyst__c = analystU3.Id;
    topp1.Co_Originator__c = origU3.Id;
    topp1.IO_Term__c = '0 months';
    topp1.Deposit_Amount__c = 0;
    topp1.Deposit_Collected__c = System.today();
    topp1.Deposit_Fed_Reference__c = 'adfaf';
    topp1.Broker_Fees_and_or_YSP__c = 'adffda';
    topp1.Property_Management__c = 'Third Party';
    topp1.StageName = 'Underwriting';
    topp1.Current_Loan_Amount__c = 2000000;
    topp1.Underwriter__c = uwU.Id;
    topp1.Loan_Coordinator__c = lcU.Id;
    topp1.Closer__c = closerU.Id;
    topp1.Kickoff_Date__c = System.today();
    // topp1.Commission_Type__c = 'Direct';
    topp1.StageName = 'UW Hold';
    update topp1;
    Test.stopTest();
  }

  static testMethod void opportunity_TermTest06() {
    List<User> newUsers = new List<User>();
    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com'
    );
    //insert p;
    insert origU;

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator2@teada.com'
    );
    //insert p;
    insert origU2;

    User origU3 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator3@teada.com'
    );
    //insert p;
    insert origU3;

    User origU4 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator4@teada.com'
    );
    //insert p;
    insert origU4;

    User analystU = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst@teada.com'
    );
    //insert p;
    insert analystU;

    User analystU2 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst2@teada.com'
    );
    //insert p;
    insert analystU2;

    User analystU3 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst3@teada.com'
    );
    //insert p;
    insert analystU3;

    User analystU4 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst4@teada.com'
    );
    //insert p;
    insert analystU4;

    User uwU = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter@teada.com'
    );
    //insert p;
    insert uwU;

    User uwU2 = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter2@teada.com'
    );
    //insert p;
    insert uwU2;

    User lcU = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord1@teada.com'
    );
    //insert p;
    insert lcU;

    User lcU2 = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord2@teada.com'
    );
    //insert p;
    insert lcU2;

    User closerU = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer1@teada.com'
    );
    //insert p;
    insert closerU;

    User closerU2 = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada.com'
    );
    //insert p;
    insert closerU2;

    Opportunity topp1 = [
      SELECT Id
      FROM Opportunity
      WHERE Name = 'TERM TEST 123'
      LIMIT 1
    ];

    Test.startTest();
    Securitization__c sec = test_Helper.createSecuritization();

    topp1.Term_Sheet_Issued__c = System.today();
    topp1.Trigger_Field__c = 'Originations Model;Model Name Test';
    topp1.Pres_Deal_Id__c = '123';
    //topp1.StageName = 'Term Sheet Issued';
    topp1.Loan_Effective_Date__c = System.today();
    topp1.Deal_Intro_Source__c = 'Email';
    topp1.Bridge_Borrower__c = 'No';
    topp1.Are_Assets_Coming_Off_Bridge_Line__c = 'No';
    topp1.Term_Sheet_Signed__c = System.today();
    topp1.OwnerId = origU.Id;
    topp1.CAF_Analyst__c = analystU.Id;
    topp1.Second_Production_Analyst__c = analystU3.Id;
    topp1.Co_Originator__c = origU3.Id;
    topp1.IO_Term__c = '0 months';
    topp1.Deposit_Amount__c = 0;
    topp1.Deposit_Collected__c = System.today();
    topp1.Deposit_Fed_Reference__c = 'adfaf';
    topp1.Broker_Fees_and_or_YSP__c = 'adffda';
    topp1.Property_Management__c = 'Third Party';
    topp1.StageName = 'Underwriting';
    topp1.Current_Loan_Amount__c = 2000000;
    topp1.Underwriter__c = uwU.Id;
    topp1.Loan_Coordinator__c = lcU.Id;
    topp1.Closer__c = closerU.Id;
    topp1.Kickoff_Date__c = System.today();
    // topp1.Commission_Type__c = 'Direct';
    topp1.StageName = 'UW Hold';
    topp1.StageName = 'Underwriting';
    topp1.IO_Term__c = '120 months';
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.CAF_Analyst__c = analystU2.Id;
    topp1.Second_Production_Analyst__c = analystU4.Id;
    topp1.Underwriter__c = uwU2.Id;
    topp1.Loan_Coordinator__c = lcU2.Id;
    topp1.Closer__c = closerU2.Id;
    topp1.Co_Originator__c = origU4.Id;
    topp1.Final_Spread__c = 2;
    topp1.Final_Swap__c = 2;
    update topp1;
    Test.stopTest();
  }

  static testMethod void opportunity_TermTest07() {
    List<User> newUsers = new List<User>();
    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com'
    );
    //insert p;
    insert origU;

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator2@teada.com'
    );
    //insert p;
    insert origU2;

    User origU3 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator3@teada.com'
    );
    //insert p;
    insert origU3;

    User origU4 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator4@teada.com'
    );
    //insert p;
    insert origU4;

    User analystU = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst@teada.com'
    );
    //insert p;
    insert analystU;

    User analystU2 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst2@teada.com'
    );
    //insert p;
    insert analystU2;

    User analystU3 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst3@teada.com'
    );
    //insert p;
    insert analystU3;

    User analystU4 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst4@teada.com'
    );
    //insert p;
    insert analystU4;

    User uwU = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter@teada.com'
    );
    //insert p;
    insert uwU;

    User uwU2 = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter2@teada.com'
    );
    //insert p;
    insert uwU2;

    User lcU = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord1@teada.com'
    );
    //insert p;
    insert lcU;

    User lcU2 = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord2@teada.com'
    );
    //insert p;
    insert lcU2;

    User closerU = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer1@teada.com'
    );
    //insert p;
    insert closerU;

    User closerU2 = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada.com'
    );
    //insert p;
    insert closerU2;

    Opportunity topp1 = [
      SELECT Id
      FROM Opportunity
      WHERE Name = 'TERM TEST 123'
      LIMIT 1
    ];

    Test.startTest();
    Securitization__c sec = test_Helper.createSecuritization();

    topp1.Term_Sheet_Issued__c = System.today();
    //topp1.StageName = 'Term Sheet Issued';
    topp1.Loan_Effective_Date__c = System.today();
    topp1.Deal_Intro_Source__c = 'Email';
    topp1.Bridge_Borrower__c = 'No';
    topp1.Are_Assets_Coming_Off_Bridge_Line__c = 'No';
    topp1.Term_Sheet_Signed__c = System.today();
    topp1.OwnerId = origU.Id;
    topp1.CAF_Analyst__c = analystU.Id;
    topp1.Second_Production_Analyst__c = analystU3.Id;
    topp1.Co_Originator__c = origU3.Id;
    topp1.IO_Term__c = '0 months';
    topp1.Deposit_Amount__c = 0;
    topp1.Deposit_Collected__c = System.today();
    topp1.Deposit_Fed_Reference__c = 'adfaf';
    topp1.Broker_Fees_and_or_YSP__c = 'adffda';
    topp1.Property_Management__c = 'Third Party';
    topp1.StageName = 'Underwriting';
    topp1.Current_Loan_Amount__c = 2000000;
    topp1.Underwriter__c = uwU.Id;
    topp1.Loan_Coordinator__c = lcU.Id;
    topp1.Closer__c = closerU.Id;
    topp1.Kickoff_Date__c = System.today();
    // topp1.Commission_Type__c = 'Direct';
    // topp1.StageName = 'UW Hold';
    // topp1.StageName = 'Underwriting';
    topp1.IO_Term__c = '120 months';
    // topp1.Final_Loan_Amount__c = 1000000;
    // topp1.CAF_Analyst__c = analystU2.Id;
    // topp1.Second_Production_Analyst__c = analystU4.Id;
    // topp1.Underwriter__c = uwU2.Id;
    // topp1.Loan_Coordinator__c = lcU2.Id;
    // topp1.Closer__c = closerU2.Id;
    // topp1.Co_Originator__c = origU4.Id;
    topp1.Final_Spread__c = 2;
    topp1.Final_Swap__c = 2;
    topp1.Trigger_Field__c = 'Term Underwriting Model;Model Name Test';

    topp1.Anticipated_Closing_Date__c = System.today() + 30;

    update topp1;
    Test.stopTest();
  }

  static testMethod void opportunity_TermTest08() {
    List<User> newUsers = new List<User>();
    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com'
    );
    //insert p;
    insert origU;

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator2@teada.com'
    );
    //insert p;
    insert origU2;

    User origU3 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator3@teada.com'
    );
    //insert p;
    insert origU3;

    User origU4 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator4@teada.com'
    );
    //insert p;
    insert origU4;

    User analystU = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst@teada.com'
    );
    //insert p;
    insert analystU;

    User analystU2 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst2@teada.com'
    );
    //insert p;
    insert analystU2;

    User analystU3 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst3@teada.com'
    );
    //insert p;
    insert analystU3;

    User analystU4 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst4@teada.com'
    );
    //insert p;
    insert analystU4;

    User uwU = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter@teada.com'
    );
    //insert p;
    insert uwU;

    User uwU2 = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter2@teada.com'
    );
    //insert p;
    insert uwU2;

    User lcU = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord1@teada.com'
    );
    //insert p;
    insert lcU;

    User lcU2 = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord2@teada.com'
    );
    //insert p;
    insert lcU2;

    User closerU = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer1@teada.com'
    );
    //insert p;
    insert closerU;

    User closerU2 = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada.com'
    );
    //insert p;
    insert closerU2;

    Opportunity topp1 = [
      SELECT Id
      FROM Opportunity
      WHERE Name = 'TERM TEST 123'
      LIMIT 1
    ];

    Test.startTest();
    Securitization__c sec = test_Helper.createSecuritization();

    topp1.Term_Sheet_Issued__c = System.today();
    topp1.Trigger_Field__c = 'Originations Model;Model Name Test';
    //topp1.StageName = 'Term Sheet Issued';
    topp1.Loan_Effective_Date__c = System.today();
    topp1.Deal_Intro_Source__c = 'Email';
    topp1.Bridge_Borrower__c = 'No';
    topp1.Are_Assets_Coming_Off_Bridge_Line__c = 'No';
    topp1.Term_Sheet_Signed__c = System.today();
    topp1.OwnerId = origU.Id;
    topp1.CAF_Analyst__c = analystU.Id;
    topp1.Second_Production_Analyst__c = analystU3.Id;
    topp1.Co_Originator__c = origU3.Id;
    topp1.IO_Term__c = '0 months';
    topp1.Deposit_Amount__c = 0;
    topp1.Deposit_Collected__c = System.today();
    topp1.Deposit_Fed_Reference__c = 'adfaf';
    topp1.Broker_Fees_and_or_YSP__c = 'adffda';
    topp1.Property_Management__c = 'Third Party';
    topp1.StageName = 'Underwriting';
    // topp1.Current_Loan_Amount__c = 2000000;
    topp1.Underwriter__c = uwU.Id;
    topp1.Loan_Coordinator__c = lcU.Id;
    topp1.Closer__c = closerU.Id;
    topp1.Kickoff_Date__c = System.today();
    // topp1.Commission_Type__c = 'Direct';
    // topp1.StageName = 'UW Hold';
    // topp1.StageName = 'Underwriting';
    topp1.IO_Term__c = '120 months';
    topp1.Final_Loan_Amount__c = 1000000;
    // topp1.CAF_Analyst__c = analystU2.Id;
    // topp1.Second_Production_Analyst__c = analystU4.Id;
    // topp1.Underwriter__c = uwU2.Id;
    // topp1.Loan_Coordinator__c = lcU2.Id;
    // topp1.Closer__c = closerU2.Id;
    // topp1.Co_Originator__c = origU4.Id;
    topp1.Final_Spread__c = 2;
    topp1.Final_Swap__c = 2;
    // topp1.Trigger_Field__c = 'Term Underwriting Model;Model Name Test';

    topp1.Anticipated_Closing_Date__c = System.today() + 30;
    topp1.Final_Loan_Amount__c = null;
    topp1.OwnerId = origU2.Id;
    update topp1;
    Test.stopTest();
  }

  static testMethod void opportunity_TermTest09() {
    List<User> newUsers = new List<User>();
    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com'
    );
    //insert p;
    insert origU;

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator2@teada.com'
    );
    //insert p;
    insert origU2;

    User origU3 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator3@teada.com'
    );
    //insert p;
    insert origU3;

    User origU4 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator4@teada.com'
    );
    //insert p;
    insert origU4;

    User analystU = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst@teada.com'
    );
    //insert p;
    insert analystU;

    User analystU2 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst2@teada.com'
    );
    //insert p;
    insert analystU2;

    User analystU3 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst3@teada.com'
    );
    //insert p;
    insert analystU3;

    User analystU4 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst4@teada.com'
    );
    //insert p;
    insert analystU4;

    User uwU = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter@teada.com'
    );
    //insert p;
    insert uwU;

    User uwU2 = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter2@teada.com'
    );
    //insert p;
    insert uwU2;

    User lcU = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord1@teada.com'
    );
    //insert p;
    insert lcU;

    User lcU2 = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord2@teada.com'
    );
    //insert p;
    insert lcU2;

    User closerU = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer1@teada.com'
    );
    //insert p;
    insert closerU;

    User closerU2 = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada.com'
    );
    //insert p;
    insert closerU2;

    Opportunity topp1 = [
      SELECT Id
      FROM Opportunity
      WHERE Name = 'TERM TEST 123'
      LIMIT 1
    ];

    Test.startTest();
    Securitization__c sec = test_Helper.createSecuritization();

    topp1.Term_Sheet_Issued__c = System.today();
    // topp1.Trigger_Field__c = 'Originations Model;Model Name Test';
    //topp1.StageName = 'Term Sheet Issued';
    topp1.Loan_Effective_Date__c = System.today();
    topp1.Deal_Intro_Source__c = 'Email';
    topp1.Bridge_Borrower__c = 'No';
    topp1.Are_Assets_Coming_Off_Bridge_Line__c = 'No';
    topp1.Term_Sheet_Signed__c = System.today();
    topp1.OwnerId = origU.Id;
    topp1.CAF_Analyst__c = analystU.Id;
    topp1.Second_Production_Analyst__c = analystU3.Id;
    topp1.Co_Originator__c = origU3.Id;
    topp1.IO_Term__c = '0 months';
    topp1.Deposit_Amount__c = 0;
    topp1.Deposit_Collected__c = System.today();
    topp1.Deposit_Fed_Reference__c = 'adfaf';
    topp1.Broker_Fees_and_or_YSP__c = 'adffda';
    topp1.Property_Management__c = 'Third Party';
    topp1.StageName = 'Underwriting';
    topp1.Current_Loan_Amount__c = 2000000;
    topp1.Underwriter__c = uwU.Id;
    topp1.Loan_Coordinator__c = lcU.Id;
    topp1.Closer__c = closerU.Id;
    topp1.Kickoff_Date__c = System.today();
    // topp1.Commission_Type__c = 'Direct';
    // topp1.StageName = 'UW Hold';
    // topp1.StageName = 'Underwriting';
    topp1.IO_Term__c = '120 months';
    topp1.Final_Loan_Amount__c = 1000000;
    // topp1.CAF_Analyst__c = analystU2.Id;
    // topp1.Second_Production_Analyst__c = analystU4.Id;
    // topp1.Underwriter__c = uwU2.Id;
    // topp1.Loan_Coordinator__c = lcU2.Id;
    // topp1.Closer__c = closerU2.Id;
    // topp1.Co_Originator__c = origU4.Id;
    topp1.Final_Spread__c = 2;
    topp1.Final_Swap__c = 2;
    topp1.Trigger_Field__c = 'Term Underwriting Model;Model Name Test';

    topp1.Anticipated_Closing_Date__c = System.today() + 30;
    // topp1.Final_Loan_Amount__c = null;
    // topp1.OwnerId = origU2.Id;
    // topp1.StageName = 'Underwriting';
    update topp1;
    Test.stopTest();
  }

  static testMethod void opportunity_TermTest10() {
    List<User> newUsers = new List<User>();
    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com'
    );
    //insert p;
    insert origU;

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator2@teada.com'
    );
    //insert p;
    insert origU2;

    User origU3 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator3@teada.com'
    );
    //insert p;
    insert origU3;

    User origU4 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator4@teada.com'
    );
    //insert p;
    insert origU4;

    User analystU = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst@teada.com'
    );
    //insert p;
    insert analystU;

    User analystU2 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst2@teada.com'
    );
    //insert p;
    insert analystU2;

    User analystU3 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst3@teada.com'
    );
    //insert p;
    insert analystU3;

    User analystU4 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst4@teada.com'
    );
    //insert p;
    insert analystU4;

    User uwU = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter@teada.com'
    );
    //insert p;
    insert uwU;

    User uwU2 = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter2@teada.com'
    );
    //insert p;
    insert uwU2;

    User lcU = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord1@teada.com'
    );
    //insert p;
    insert lcU;

    User lcU2 = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord2@teada.com'
    );
    //insert p;
    insert lcU2;

    User closerU = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer1@teada.com'
    );
    //insert p;
    insert closerU;

    User closerU2 = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada.com'
    );
    //insert p;
    insert closerU2;

    Opportunity topp1 = [
      SELECT Id
      FROM Opportunity
      WHERE Name = 'TERM TEST 123'
      LIMIT 1
    ];

    Test.startTest();
    Securitization__c sec = test_Helper.createSecuritization();

    topp1.Term_Sheet_Issued__c = System.today();
    topp1.Trigger_Field__c = 'Originations Model;Model Name Test';
    topp1.Pres_Deal_Id__c = '123';
    //topp1.StageName = 'Term Sheet Issued';
    topp1.Loan_Effective_Date__c = System.today();
    topp1.Deal_Intro_Source__c = 'Email';
    topp1.Bridge_Borrower__c = 'No';
    topp1.Are_Assets_Coming_Off_Bridge_Line__c = 'No';
    topp1.Term_Sheet_Signed__c = System.today();
    topp1.OwnerId = origU.Id;
    topp1.CAF_Analyst__c = analystU.Id;
    topp1.Second_Production_Analyst__c = analystU3.Id;
    topp1.Co_Originator__c = origU3.Id;
    topp1.IO_Term__c = '0 months';
    topp1.Deposit_Amount__c = 0;
    topp1.Deposit_Collected__c = System.today();
    topp1.Deposit_Fed_Reference__c = 'adfaf';
    topp1.Broker_Fees_and_or_YSP__c = 'adffda';
    topp1.Property_Management__c = 'Third Party';
    topp1.StageName = 'Underwriting';
    topp1.Current_Loan_Amount__c = 2000000;
    topp1.Underwriter__c = uwU.Id;
    topp1.Loan_Coordinator__c = lcU.Id;
    topp1.Closer__c = closerU.Id;
    topp1.Kickoff_Date__c = System.today();
    // topp1.Commission_Type__c = 'Direct';
    topp1.StageName = 'UW Hold';
    topp1.StageName = 'Underwriting';
    topp1.IO_Term__c = '120 months';
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.CAF_Analyst__c = analystU2.Id;
    topp1.Second_Production_Analyst__c = analystU4.Id;
    topp1.Underwriter__c = uwU2.Id;
    topp1.Loan_Coordinator__c = lcU2.Id;
    topp1.Closer__c = closerU2.Id;
    topp1.Co_Originator__c = origU4.Id;
    topp1.Final_Spread__c = 2;
    topp1.Final_Swap__c = 2;
    topp1.Trigger_Field__c = 'Term Underwriting Model;Model Name Test';

    topp1.Anticipated_Closing_Date__c = System.today() + 30;
    topp1.Final_Loan_Amount__c = null;
    topp1.OwnerId = origU2.Id;
    topp1.StageName = 'Underwriting';
    topp1.StageName = 'Approved by Committee';
    update topp1;
    Test.stopTest();
  }

  static testMethod void opportunity_TermTest11() {
    List<User> newUsers = new List<User>();
    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com'
    );
    //insert p;
    insert origU;

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator2@teada.com'
    );
    //insert p;
    insert origU2;

    User origU3 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator3@teada.com'
    );
    //insert p;
    insert origU3;

    User origU4 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator4@teada.com'
    );
    //insert p;
    insert origU4;

    User analystU = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst@teada.com'
    );
    //insert p;
    insert analystU;

    User analystU2 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst2@teada.com'
    );
    //insert p;
    insert analystU2;

    User analystU3 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst3@teada.com'
    );
    //insert p;
    insert analystU3;

    User analystU4 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst4@teada.com'
    );
    //insert p;
    insert analystU4;

    User uwU = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter@teada.com'
    );
    //insert p;
    insert uwU;

    User uwU2 = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter2@teada.com'
    );
    //insert p;
    insert uwU2;

    User lcU = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord1@teada.com'
    );
    //insert p;
    insert lcU;

    User lcU2 = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord2@teada.com'
    );
    //insert p;
    insert lcU2;

    User closerU = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer1@teada.com'
    );
    //insert p;
    insert closerU;

    User closerU2 = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada.com'
    );
    //insert p;
    insert closerU2;

    Opportunity topp1 = [
      SELECT Id
      FROM Opportunity
      WHERE Name = 'TERM TEST 123'
      LIMIT 1
    ];

    Test.startTest();
    Securitization__c sec = test_Helper.createSecuritization();

    topp1.Term_Sheet_Issued__c = System.today();
    topp1.Trigger_Field__c = 'Originations Model;Model Name Test';
    topp1.Pres_Deal_Id__c = '123';
    //topp1.StageName = 'Term Sheet Issued';
    topp1.Loan_Effective_Date__c = System.today();
    topp1.Deal_Intro_Source__c = 'Email';
    topp1.Bridge_Borrower__c = 'No';
    topp1.Are_Assets_Coming_Off_Bridge_Line__c = 'No';
    topp1.Term_Sheet_Signed__c = System.today();
    topp1.OwnerId = origU.Id;
    topp1.CAF_Analyst__c = analystU.Id;
    topp1.Second_Production_Analyst__c = analystU3.Id;
    topp1.Co_Originator__c = origU3.Id;
    topp1.IO_Term__c = '0 months';
    topp1.Deposit_Amount__c = 0;
    topp1.Deposit_Collected__c = System.today();
    topp1.Deposit_Fed_Reference__c = 'adfaf';
    topp1.Broker_Fees_and_or_YSP__c = 'adffda';
    topp1.Property_Management__c = 'Third Party';
    topp1.StageName = 'Underwriting';
    topp1.Current_Loan_Amount__c = 2000000;
    topp1.Underwriter__c = uwU.Id;
    topp1.Loan_Coordinator__c = lcU.Id;
    topp1.Closer__c = closerU.Id;
    topp1.Kickoff_Date__c = System.today();
    // topp1.Commission_Type__c = 'Direct';
    topp1.StageName = 'UW Hold';
    topp1.StageName = 'Underwriting';
    topp1.IO_Term__c = '120 months';
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.CAF_Analyst__c = analystU2.Id;
    topp1.Second_Production_Analyst__c = analystU4.Id;
    topp1.Underwriter__c = uwU2.Id;
    topp1.Loan_Coordinator__c = lcU2.Id;
    topp1.Closer__c = closerU2.Id;
    topp1.Co_Originator__c = origU4.Id;
    topp1.Final_Spread__c = 2;
    topp1.Final_Swap__c = 2;
    topp1.Trigger_Field__c = 'Term Underwriting Model;Model Name Test';

    topp1.Anticipated_Closing_Date__c = System.today() + 30;
    topp1.Final_Loan_Amount__c = null;
    topp1.OwnerId = origU2.Id;
    topp1.StageName = 'Underwriting';
    topp1.StageName = 'Approved by Committee';
    topp1.Final_Loan_Amount__c = 2000000;
    topp1.StageName = 'Closed Won';
    topp1.Servicer_Name__c = 'Midland';
    topp1.Servicer_Commitment_Id__c = '12345';
    topp1.First_Payment_Date__c = System.today() + 30;
    topp1.Last_Payment_Date__c = System.today() + 30;
    topp1.Delinquent_30_Days__c = 1;
    topp1.Delinquent_60_Days__c = 0;
    topp1.Delinquent_90_Days__c = 0;
    topp1.Delinquent_120_Days__c = 3;
    topp1.Current_UPB__c = 300000;
    topp1.Onboarded_at_Servicer__c = System.today() + 30;
    topp1.Onboarding_File_Sent_to_Servicer__c = System.today() + 30;
    topp1.P_I__c = 2000;
    topp1.T_I__c = 3333;
    topp1.Servicer_Status__c = 'Active';
    topp1.Servicer_Provided_Portfolio_Name__c = 'CAF 2020';
    update topp1;

    topp1.Servicer_Name__c = 'Midland1';
    topp1.Servicer_Commitment_Id__c = '123455';

    update topp1;
    Test.stopTest();
  }

  static testMethod void opportunity_TermTest12() {
    List<User> newUsers = new List<User>();
    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com'
    );
    //insert p;
    insert origU;

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator2@teada.com'
    );
    //insert p;
    insert origU2;

    User origU3 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator3@teada.com'
    );
    //insert p;
    insert origU3;

    User origU4 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator4@teada.com'
    );
    //insert p;
    insert origU4;

    User analystU = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst@teada.com'
    );
    //insert p;
    insert analystU;

    User analystU2 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst2@teada.com'
    );
    //insert p;
    insert analystU2;

    User analystU3 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst3@teada.com'
    );
    //insert p;
    insert analystU3;

    User analystU4 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst4@teada.com'
    );
    //insert p;
    insert analystU4;

    User uwU = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter@teada.com'
    );
    //insert p;
    insert uwU;

    User uwU2 = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter2@teada.com'
    );
    //insert p;
    insert uwU2;

    User lcU = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord1@teada.com'
    );
    //insert p;
    insert lcU;

    User lcU2 = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord2@teada.com'
    );
    //insert p;
    insert lcU2;

    User closerU = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer1@teada.com'
    );
    //insert p;
    insert closerU;

    User closerU2 = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada.com'
    );
    //insert p;
    insert closerU2;

    Opportunity topp1 = [
      SELECT Id
      FROM Opportunity
      WHERE Name = 'TERM TEST 123'
      LIMIT 1
    ];

    Test.startTest();
    Securitization__c sec = test_Helper.createSecuritization();

    topp1.Term_Sheet_Issued__c = System.today();
    topp1.Trigger_Field__c = 'Originations Model;Model Name Test';
    topp1.Pres_Deal_Id__c = '123';
    //topp1.StageName = 'Term Sheet Issued';
    topp1.Loan_Effective_Date__c = System.today();
    topp1.Deal_Intro_Source__c = 'Email';
    topp1.Bridge_Borrower__c = 'No';
    topp1.Are_Assets_Coming_Off_Bridge_Line__c = 'No';
    topp1.Term_Sheet_Signed__c = System.today();
    topp1.OwnerId = origU.Id;
    topp1.CAF_Analyst__c = analystU.Id;
    topp1.Second_Production_Analyst__c = analystU3.Id;
    topp1.Co_Originator__c = origU3.Id;
    topp1.IO_Term__c = '0 months';
    topp1.Deposit_Amount__c = 0;
    topp1.Deposit_Collected__c = System.today();
    topp1.Deposit_Fed_Reference__c = 'adfaf';
    topp1.Broker_Fees_and_or_YSP__c = 'adffda';
    topp1.Property_Management__c = 'Third Party';
    topp1.StageName = 'Underwriting';
    topp1.Current_Loan_Amount__c = 2000000;
    topp1.Underwriter__c = uwU.Id;
    topp1.Loan_Coordinator__c = lcU.Id;
    topp1.Closer__c = closerU.Id;
    topp1.Kickoff_Date__c = System.today();
    // topp1.Commission_Type__c = 'Direct';
    topp1.StageName = 'UW Hold';
    topp1.StageName = 'Underwriting';
    topp1.IO_Term__c = '120 months';
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.CAF_Analyst__c = analystU2.Id;
    topp1.Second_Production_Analyst__c = analystU4.Id;
    topp1.Underwriter__c = uwU2.Id;
    topp1.Loan_Coordinator__c = lcU2.Id;
    topp1.Closer__c = closerU2.Id;
    topp1.Co_Originator__c = origU4.Id;
    topp1.Final_Spread__c = 2;
    topp1.Final_Swap__c = 2;
    topp1.Trigger_Field__c = 'Term Underwriting Model;Model Name Test';

    topp1.Anticipated_Closing_Date__c = System.today() + 30;
    topp1.Final_Loan_Amount__c = null;
    topp1.OwnerId = origU2.Id;
    topp1.StageName = 'Underwriting';
    topp1.StageName = 'Approved by Committee';
    topp1.Final_Loan_Amount__c = 2000000;
    topp1.StageName = 'Closed Won';
    topp1.Servicer_Name__c = 'Midland';
    topp1.First_Payment_Date__c = System.today() + 30;
    topp1.Last_Payment_Date__c = System.today() + 30;
    topp1.Delinquent_30_Days__c = 1;
    topp1.Delinquent_60_Days__c = 0;
    topp1.Delinquent_90_Days__c = 0;
    topp1.Delinquent_120_Days__c = 3;
    topp1.Current_UPB__c = 300000;
    topp1.Onboarded_at_Servicer__c = System.today() + 30;
    topp1.Onboarding_File_Sent_to_Servicer__c = System.today() + 30;
    topp1.P_I__c = 2000;
    topp1.T_I__c = 3333;
    topp1.Servicer_Status__c = 'Active';
    topp1.Servicer_Provided_Portfolio_Name__c = 'CAF 2020';
    topp1.Current_UPB__c = 0;
    update topp1;
    Test.stopTest();
  }

  static testMethod void opportunity_TermTest13() {
    List<User> newUsers = new List<User>();
    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com'
    );
    //insert p;
    insert origU;

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator2@teada.com'
    );
    //insert p;
    insert origU2;

    User origU3 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator3@teada.com'
    );
    //insert p;
    insert origU3;

    User origU4 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator4@teada.com'
    );
    //insert p;
    insert origU4;

    User analystU = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst@teada.com'
    );
    //insert p;
    insert analystU;

    User analystU2 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst2@teada.com'
    );
    //insert p;
    insert analystU2;

    User analystU3 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst3@teada.com'
    );
    //insert p;
    insert analystU3;

    User analystU4 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst4@teada.com'
    );
    //insert p;
    insert analystU4;

    User uwU = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter@teada.com'
    );
    //insert p;
    insert uwU;

    User uwU2 = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter2@teada.com'
    );
    //insert p;
    insert uwU2;

    User lcU = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord1@teada.com'
    );
    //insert p;
    insert lcU;

    User lcU2 = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord2@teada.com'
    );
    //insert p;
    insert lcU2;

    User closerU = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer1@teada.com'
    );
    //insert p;
    insert closerU;

    User closerU2 = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada.com'
    );
    //insert p;
    insert closerU2;

    Opportunity topp1 = [
      SELECT Id
      FROM Opportunity
      WHERE Name = 'TERM TEST 123'
      LIMIT 1
    ];

    Test.startTest();
    Securitization__c sec = test_Helper.createSecuritization();

    topp1.Term_Sheet_Issued__c = System.today();
    topp1.Trigger_Field__c = 'Originations Model;Model Name Test';
    topp1.Pres_Deal_Id__c = '123';
    //topp1.StageName = 'Term Sheet Issued';
    topp1.Loan_Effective_Date__c = System.today();
    topp1.Deal_Intro_Source__c = 'Email';
    topp1.Bridge_Borrower__c = 'No';
    topp1.Are_Assets_Coming_Off_Bridge_Line__c = 'No';
    topp1.Term_Sheet_Signed__c = System.today();
    topp1.OwnerId = origU.Id;
    topp1.CAF_Analyst__c = analystU.Id;
    topp1.Second_Production_Analyst__c = analystU3.Id;
    topp1.Co_Originator__c = origU3.Id;
    topp1.IO_Term__c = '0 months';
    topp1.Deposit_Amount__c = 0;
    topp1.Deposit_Collected__c = System.today();
    topp1.Deposit_Fed_Reference__c = 'adfaf';
    topp1.Broker_Fees_and_or_YSP__c = 'adffda';
    topp1.Property_Management__c = 'Third Party';
    topp1.StageName = 'Underwriting';
    topp1.Current_Loan_Amount__c = 2000000;
    topp1.Underwriter__c = uwU.Id;
    topp1.Loan_Coordinator__c = lcU.Id;
    topp1.Closer__c = closerU.Id;
    topp1.Kickoff_Date__c = System.today();
    // topp1.Commission_Type__c = 'Direct';
    topp1.StageName = 'UW Hold';
    topp1.StageName = 'Underwriting';
    topp1.IO_Term__c = '120 months';
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.CAF_Analyst__c = analystU2.Id;
    topp1.Second_Production_Analyst__c = analystU4.Id;
    topp1.Underwriter__c = uwU2.Id;
    topp1.Loan_Coordinator__c = lcU2.Id;
    topp1.Closer__c = closerU2.Id;
    topp1.Co_Originator__c = origU4.Id;
    topp1.Final_Spread__c = 2;
    topp1.Final_Swap__c = 2;
    topp1.Trigger_Field__c = 'Term Underwriting Model;Model Name Test';

    topp1.Anticipated_Closing_Date__c = System.today() + 30;
    topp1.Final_Loan_Amount__c = null;
    topp1.OwnerId = origU2.Id;
    topp1.StageName = 'Underwriting';
    topp1.StageName = 'Approved by Committee';
    topp1.Final_Loan_Amount__c = 2000000;
    topp1.StageName = 'Closed Won';
    topp1.Servicer_Name__c = 'Midland';
    topp1.First_Payment_Date__c = System.today() + 30;
    topp1.Last_Payment_Date__c = System.today() + 30;
    topp1.Delinquent_30_Days__c = 1;
    topp1.Delinquent_60_Days__c = 0;
    topp1.Delinquent_90_Days__c = 0;
    topp1.Delinquent_120_Days__c = 3;
    topp1.Current_UPB__c = 300000;
    topp1.Onboarded_at_Servicer__c = System.today() + 30;
    topp1.Onboarding_File_Sent_to_Servicer__c = System.today() + 30;
    topp1.P_I__c = 2000;
    topp1.T_I__c = 3333;
    topp1.Servicer_Status__c = 'Active';
    topp1.Servicer_Provided_Portfolio_Name__c = 'CAF 2020';
    topp1.Current_UPB__c = 0;
    Account acct = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];

    update topp1;

    opportunity_Extension ext = new opportunity_Extension();

    opportunity_Helper.compileClearToCloseTabData(topp1.Id);
    Set<Id> setOpportunityId = new Set<Id>();
    setOpportunityId.add(topp1.Id);

    Property__c prop = new Property__c();
    prop.Property_Type__c = 'SFR';
    prop.Deal__c = topp1.Id;
    prop.Calc_AveValue__c = 100000;
    prop.Name = 'test';
    prop.Property_Name__c = 'test Street';
    prop.City__c = 'test';
    prop.State__c = 'test';
    prop.ZipCode__c = 'test';
    insert prop;

    list<Property__c> propList = new List<Property__c>();
    propList.add(prop);

    map<id, opportunity> isVSOppMap = new Map<id, opportunity>();
    isVSOppMap.put(topp1.id, topp1);

    opportunity_Helper.getMapFromOppIdToProperties(setOpportunityId);
    opportunity_Helper.propertiesHaveBeenRedBellSynced(propList);
    opportunity_Helper.checkClosedWonContacts(isVSOppMap);

    Test.stopTest();
  }

  static testMethod void opportunity_TermTest14() {
    Test.startTest();

    Account brokerAcc = test_Helper.createBrokerAccount();
    Contact brokerCon = test_Helper.createBrokerContact(brokerAcc);
    Opportunity topp3 = new opportunity();
    topp3.name = '123445';
    topp3.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    topp3.StageName = 'Initial Review';
    topp3.AccountId = brokerAcc.Id;
    topp3.Contact__c = brokerCon.Id;
    topp3.Loan_Size__c = 100;
    topp3.CloseDate = Date.newInstance(2014, 4, 17);
    insert topp3;

    Test.stopTest();
  }

  // static testMethod void reverse_ICApprovalTest() {
  //   Opportunity topp1 = [
  //     SELECT Id
  //     FROM Opportunity
  //     WHERE Name = 'TERM TEST 123'
  //     LIMIT 1
  //   ];

  //   topp1.StageName = 'Approved by Committee';
  //   topp1.IC_Approval_Date__c = System.today();
  //   topp1.IC_Approval__c = 'Approved';
  //   topp1.Current_Loan_Amount__c = 1000000;

  //   Test.startTest();
  //   update topp1;

  //   topp1.Current_Loan_Amount__c = 2000000;
  //   update topp1;

  //   Test.stopTest();

  //   Opportunity updOppt = [
  //     SELECT Id, IC_Approval_Date__c, StageName
  //     FROM Opportunity
  //     WHERE Name = 'TERM TEST 123'
  //     LIMIT 1
  //   ];

  //   System.assertEquals(
  //     null,
  //     updOppt.IC_Approval_Date__c,
  //     'IC_Approval_Date__c should be null'
  //   );
  //   System.assertEquals(
  //     'Underwriting',
  //     updOppt.StageName,
  //     'StageName should be Underwriting'
  //   );
  // }

  static testMethod void opportunity_SABTest() {
    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com'
    );
    //insert p;
    insert origU;

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator2@teada.com'
    );
    //insert p;
    insert origU2;

    User origU3 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator3@teada.com'
    );
    //insert p;
    insert origU3;

    User origU4 = new User(
      Alias = 'orig',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator4@teada.com'
    );
    //insert p;
    insert origU4;

    User analystU = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst@teada.com'
    );
    //insert p;
    insert analystU;

    User analystU2 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst2@teada.com'
    );
    //insert p;
    insert analystU2;

    User analystU3 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst3@teada.com'
    );
    //insert p;
    insert analystU3;

    User analystU4 = new User(
      Alias = 'analyst',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Analyst']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'analyst4@teada.com'
    );
    //insert p;
    insert analystU4;

    User uwU = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter@teada.com'
    );
    //insert p;
    insert uwU;

    User uwU2 = new User(
      Alias = 'underw',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'underwriter2@teada.com'
    );
    //insert p;
    insert uwU2;

    User lcU = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord1@teada.com'
    );
    //insert p;
    insert lcU;

    User lcU2 = new User(
      Alias = 'loanco',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'coord2@teada.com'
    );
    //insert p;
    insert lcU2;

    User closerU = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer1@teada.com'
    );
    //insert p;
    insert closerU;

    User closerU2 = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Term Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada.com'
    );
    //insert p;
    insert closerU2;
    Test.startTest();

    Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
    Contact cont = [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
    Opportunity sab = new opportunity();
    sab.Pres_Deal_Id__c = '12345';
    sab.name = '123445';
    sab.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Single_Asset_Loan'
    ]
    .Id;
    sab.StageName = 'Initial Review';
    sab.AccountId = acc.Id;
    sab.Contact__c = cont.Id;
    sab.Loan_Size__c = 100;
    sab.Deal_Intro_Source__c = 'Email';
    sab.Bridge_Borrower__c = 'No';
    sab.Are_Assets_Coming_Off_Bridge_Line__c = 'No';
    sab.Term_Sheet_Signed__c = System.today();
    sab.Underwriter__c = uwU2.Id;
    sab.OwnerId = origU.Id;
    sab.Loan_Coordinator__c = lcU.Id;
    sab.Closer__c = lcU.Id;
    sab.CAF_Analyst__c = analystU.Id;
    sab.Second_Production_Analyst__c = analystU3.Id;
    sab.Co_Originator__c = origU3.Id;
    sab.Term_Sheet_Issued__c = System.today();
    sab.CloseDate = Date.newInstance(2014, 4, 17);
    sab.Broker_Fees__c = 1;
    insert sab;

    Test.stopTest();
  }

  static testMethod void opportunity_BridgeTest1() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
    User u = new User(
      Alias = 'standt',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'afafadfavvte@teada.com'
    );
    //insert p;
    insert u;

    Test.startTest();

    Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
    Contact cont = [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
    Opportunity bridgedeal = test_Helper.createBridgeDeal(acc, cont);
    bridgedeal.Pres_Deal_Id__c = '123';
    bridgedeal.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    update bridgedeal;
    bridgedeal.Loan_Size__c = 2000000;
    update bridgedeal;
    bridgedeal.Loan_Size__c = 7000000;
    update bridgedeal;
    bridgedeal.Loan_Size__c = 2000000;
    update bridgedeal;
    bridgedeal.Loan_Size__c = 20000000;
    update bridgedeal;

    bridgedeal.LOC_Loan_Type__c = 'Credit Line';
    bridgedeal.Product_Sub_Type__c = 'Renovation';
    bridgedeal.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    update bridgedeal;
    bridgedeal.Requested_ARV_LTV__c = 75;
    bridgedeal.Requested_Max_Reno_Cost_Reimbursement__c = 75;
    bridgedeal.Requested_Reno_Limit__c = 75;
    bridgedeal.Requested_Total_Loan_LTC__c = 75;
    update bridgedeal;
    bridgedeal.Product_Sub_Type__c = 'No Renovation';
    update bridgedeal;
    bridgedeal.LOC_Commitment__c = 3000000;
    bridgedeal.StageName = 'Closed Won';
    bridgedeal.LOC_Term__c = '12 Months';
    bridgedeal.CloseDate = Date.newInstance(2014, 4, 17);
    bridgedeal.Loan_Effective_Date__c = Date.newInstance(2014, 4, 17);
    update bridgedeal;
    bridgedeal.LOC_Loan_Type__c = 'Single Asset (1-4 Unit)';
    bridgedeal.Product_Sub_Type__c = 'Renovation';
    update bridgedeal;

    Database.executeBatch(new loc_Batchable());

    Test.stopTest();
  }

  static testMethod void opportunity_LOCTest() {
    Test.startTest();

    Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
    Contact cont = [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
    Opportunity locdeal = test_Helper.createLOCDeal(acc, cont);
    locdeal.Loan_Size__c = 8000000;
    update locdeal;
    locdeal.Loan_Size__c = 1000000;
    update locdeal;

    locdeal.StageName = 'Rejected';
    locdeal.Deal_Lost_Reason__c = 'Background';

    Test.stopTest();
  }

  static testMethod void opportunity_BridgeTest1A() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
    User u = new User(
      Alias = 'standt',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'afafadfavvte@teada.com'
    );
    //insert p;
    insert u;

    Test.startTest();

    Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
    Contact cont = [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
    Opportunity bridgedeal = new opportunity();
    bridgedeal.Pres_Deal_Id__c = '123';
    bridgedeal.name = 'test opp';
    bridgedeal.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    bridgedeal.LOC_Loan_Type__c = 'Credit Line';
    bridgedeal.Product_Sub_Type__c = 'Renovation';
    bridgedeal.LOC_Commitment__c = 3000000;
    bridgedeal.StageName = 'Closed Won';
    bridgedeal.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    bridgedeal.LOC_Term__c = '12 Months';
    bridgedeal.CloseDate = Date.newInstance(2014, 4, 17);
    bridgedeal.Loan_Effective_Date__c = Date.newInstance(2014, 4, 17);
    bridgedeal.AccountId = acc.Id;
    bridgedeal.Contact__c = cont.Id;
    bridgedeal.Requested_ARV_LTV__c = 75;
    bridgedeal.Requested_Max_Reno_Cost_Reimbursement__c = 70;
    bridgedeal.Requested_Reno_Limit__c = 90;
    bridgedeal.Requested_Total_Loan_LTC__c = 80;
    insert bridgedeal;

    Deal_Contact__c dc = new Deal_Contact__c();
    dc.Deal__c = bridgedeal.Id;
    dc.Company_Name__c = 'Test Company';
    dc.Date_Established__c = System.today();
    dc.Business_Tax_ID_EIN__c = 'test';
    insert dc;

    bridgedeal.Product_Sub_Type__c = 'No Renovation';
    update bridgedeal;

    bridgedeal.LOC_Loan_Type__c = 'Single Asset (1-4 Unit)';
    bridgedeal.Product_Sub_Type__c = 'Renovation';
    update bridgedeal;

    Database.executeBatch(new loc_Batchable());

    Test.stopTest();
  }

  static testMethod void opportunity_UnitTest2() {
    Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
    Contact cont = [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
    Opportunity opp = test_Helper.createTermDeal(acc, cont);

    //Contact c1 = new Contact
    test.startTest();
    List<Deal_Contact__c> conts = new List<Deal_Contact__c>();
    conts.add(
      new Deal_Contact__c(
        Deal__c = opp.Id,
        Account__c = acc.Id,
        Vendor_Type__c = 'Legal Counsel'
      )
    );
    conts.add(
      new Deal_Contact__c(
        Deal__c = opp.Id,
        Account__c = acc.Id,
        Vendor_Type__c = 'Insurance Review'
      )
    );
    conts.add(
      new Deal_Contact__c(
        Deal__c = opp.Id,
        Account__c = acc.Id,
        Vendor_Type__c = 'Legal Counsel'
      )
    );
    conts.add(
      new Deal_Contact__c(
        Deal__c = opp.Id,
        Account__c = acc.Id,
        Vendor_Type__c = 'Title and Escrow'
      )
    );
    conts.add(
      new Deal_Contact__c(
        Deal__c = opp.Id,
        Account__c = acc.Id,
        Vendor_Type__c = 'Rent Deposit Bank'
      )
    );

    insert conts;
    update conts;

    insert new Deal_Contact__c(
      Deal__c = opp.Id,
      Company_Name__c = 'Test Company',
      Date_Established__c = System.today(),
      Business_Tax_ID_EIN__c = 'test'
    );
    insert new Deal_Contact__c(
      Deal__c = opp.Id,
      Company_Name__c = 'Test Company',
      Date_Established__c = System.today(),
      Business_Tax_ID_EIN__c = 'test'
    );
    insert new Deal_Contact__c(
      Deal__c = opp.Id,
      Contact__c = cont.Id,
      Is_Guarantor__c = true,
      Sponsor_Tier__c = 'Tier 1',
      Equifax__c = 600,
      Experian__c = 650,
      TransUnion__c = 725,
      Liquidity__c = 300000,
      Experience__c = 4
    );
    //insert new Deal_Contact__c(Deal__c = opp.Date_Established__c = 1995);
    Test.stopTest();
  }

  static testMethod void opportunity_SABTest1() {
    Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
    Contact cont = [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
    Opportunity opp = test_Helper.createSABDeal(acc, cont);
    opp.LOC_Loan_Type__c = 'Single Asset (1-4 Unit)';
    opp.Product_Sub_Type__c = 'Renovation';
    update opp;

    Deal_Document__c doc = new Deal_Document__c(Deal__c = opp.Id);
    insert doc;
    doc.Document_Loaded__c = true;
    doc.Reviewed__c = true;
    update doc;
    doc.Reviewed__c = false;
    update doc;
    doc.Document_Loaded__c = false;
    doc.Reviewed__c = true;
    update doc;
  }

  static testMethod void opportunity_UnitTestCRE() {
    Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
    Contact cont = [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
    Opportunity opp = test_Helper.createCREDeal(acc, cont);
  }

  static testMethod void opportunity_UnitTestBTR() {
    Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
    Contact cont = [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
    Opportunity opp = test_Helper.createBTRDeal(acc, cont);
  }

  static testMethod void opportunity_CancellationTest() {
    Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
    Contact cont = [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
    Opportunity opp = test_Helper.createCREDeal(acc, cont);

    Test.startTest();

    opp.StageName = 'Withdrawn';
    opp.Deal_Lost_Reason__c = 'Background';
    update opp;

    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Initial Review';
    update opp;

    opp.StageName = 'Rejected';
    opp.Deal_Lost_Reason__c = 'Background';
    update opp;

    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Opportunity'
        AND DeveloperName = 'Single_Asset_Bridge_Loan'
    ]
    .Id;
    opp.StageName = 'Initial Review';
    opp.CloseDate = System.today() + 10;
    update opp;

    opp.StageName = 'Rejected';
    opp.Deal_Lost_Reason__c = 'Background';
    update opp;

    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Opportunity'
        AND DeveloperName = 'Single_Asset_Bridge_Loan'
    ]
    .Id;
    opp.StageName = 'Initial Review';
    opp.CloseDate = System.today() + 10;
    update opp;

    opp.StageName = 'Withdrawn';
    opp.Deal_Lost_Reason__c = 'Background';
    update opp;

    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Opportunity'
        AND DeveloperName = 'Single_Asset_Bridge_Loan'
    ]
    .Id;
    opp.StageName = 'Initial Review';
    opp.CloseDate = System.today() + 10;
    update opp;

    opp.StageName = 'Rejected';
    opp.Deal_Lost_Reason__c = 'Background';
    update opp;

    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Single_Asset_Loan'
    ]
    .Id;
    opp.StageName = 'Initial Review';
    opp.CloseDate = System.today() + 10;
    update opp;

    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Single_Asset_Loan'
    ]
    .Id;
    opp.StageName = 'Rejected';
    opp.Deal_Lost_Reason__c = 'Background';
    update opp;

    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Single_Asset_Loan'
    ]
    .Id;
    opp.StageName = 'Initial Review';
    opp.CloseDate = System.today() + 10;
    update opp;

    opp.StageName = 'Withdrawn';
    opp.Deal_Lost_Reason__c = 'Background';
    update opp;

    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    opp.StageName = 'Initial Review';
    opp.CloseDate = System.today() + 10;
    update opp;

    opp.StageName = 'Withdrawn';
    opp.Deal_Lost_Reason__c = 'Background';
    update opp;

    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    opp.StageName = 'Initial Review';
    opp.CloseDate = System.today() + 10;
    update opp;

    opp.StageName = 'Rejected';
    opp.Deal_Lost_Reason__c = 'Background';
    update opp;

    Test.stopTest();
  }

  static testMethod void opportunity_UnitTest4() {
    Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
    Contact cont = [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
    Opportunity opp = test_Helper.createTermDeal2(acc, cont);

    EmailMessage e = new EmailMessage();
    e.relatedtoid = opp.Id;

    e.Subject = 'CAF Welcome Email';

    insert e;
  }

  static testMethod void opportunity_UnitTest5() {
    /* Account a = new Account();
    a.Name = 'Alston & Bird';
    a.BillingCountry = 'United States';
    a.BillingState = 'California';
    a.Introductions_Source__c = 'Hotline';
    a.Introduction_Subsource__c = 'Main';
    a.Alternate_Phone__c = '55555555355';
    insert a;*/
    System.debug(
      'RS999 - 1 Total Number of SOQL Queries allowed in this apex code context: ' +
      Limits.getLimitQueries()
    );
    Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
    Contact cont = [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
    //  cont.AccountId = acc.Id;
    // update cont;
    System.debug(
      'RS999 - 2 Total Number of SOQL Queries allowed in this apex code context: ' +
      Limits.getLimitQueries()
    );
    Opportunity opp = new Opportunity();
    opp.Name = 'test';
    opp.CloseDate = System.today();
    opp.StageName = 'Initial Review';
    opp.Loan_Size__c = 2000000;
    opp.AccountId = acc.Id;
    opp.Contact__c = cont.Id;
    opp.Final_Loan_Amount__c = 1000000;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_Source__c = 'Main';
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    opp.GLC_Approved__c = true;
    opp.Background_Check_Completed__c = true;
    insert opp;
    System.debug(
      'RS999 - 3 Total Number of SOQL Queries allowed in this apex code context: ' +
      Limits.getLimitQueries()
    );
    insert new deal_contact__c(
      deal__c = opp.Id,
      Contact__c = cont.Id,
      entity_type__c = 'Sponsor',
      Account__c = acc.id
    );
    System.debug(
      'RS999 - 4 Total Number of SOQL Queries allowed in this apex code context: ' +
      Limits.getLimitQueries()
    );
    Deal_Document__c doc = new Deal_Document__c(
      Deal__c = opp.Id,
      Document_Loaded__c = true,
      Is_Deleted__c = false
    );

    insert doc;
    System.debug(
      'RS999 - 5 Total Number of SOQL Queries allowed in this apex code context: ' +
      Limits.getLimitQueries()
    );
    Document_Information__c docInfo = new Document_Information__c(
      Deal__c = opp.Id,
      Doc_String__c = 'Loan Document;Title Policies|Miscellaneous'
    );

    Test.startTest();
    insert docInfo;
    System.debug(
      'RS999 - 6 Total Number of SOQL Queries allowed in this apex code context: ' +
      Limits.getLimitQueries()
    );
    Opportunity opp2 = new Opportunity();
    opp2.Name = 'test';
    opp2.id = opp.id;
    opp2.CloseDate = System.today();
    opp2.Final_Spread__c = 2;
    opp2.Final_Swap__c = 2;
    opp2.StageName = 'Closed Won';
    opp2.Type = 'Term Loan';
    opp2.Loan_Size__c = 2000000;
    opp2.AccountId = acc.Id;
    opp2.Contact__c = cont.Id;
    opp2.Final_Loan_Amount__c = 100;
    opp2.Deal_Intro_Source__c = 'Hotline';
    opp2.Deal_Intro_Sub_Source__c = 'Main';
    opp2.Apex_Context__c = true;
    opp2.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    opp2.GLC_Approved__c = false;
    opp2.Background_Check_Completed__c = false;

    update opp2;
    System.debug(
      'RS999 - 7 Total Number of SOQL Queries allowed in this apex code context: ' +
      Limits.getLimitQueries()
    );
    Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
    newMap.put(opp2.id, opp2);
    opportunity_Helper.attachDealContactIFClosedWON(newMap);

    Property__c prop = new Property__c();
    prop.Property_Type__c = 'SFR';
    prop.Deal__c = opp.Id;
    prop.Calc_AveValue__c = 100000;
    prop.Name = 'test';
    prop.Property_Name__c = 'test Street';
    prop.City__c = 'test';
    prop.State__c = 'test';
    prop.ZipCode__c = 'test';
    insert prop;
    System.debug(
      'RS999 - 8 Total Number of SOQL Queries allowed in this apex code context: ' +
      Limits.getLimitQueries()
    );
    opp.Commission_Type__c = 'Internal';
    update opp;
    System.debug(
      'RS999 - 9 Total Number of SOQL Queries allowed in this apex code context: ' +
      Limits.getLimitQueries()
    );
    opp.Term_Loan_Type__c = '5 Year';
    opp.YM_Prepayment_Penalty__c = '48 Months';
    update opp;
    System.debug(
      'RS999 - 10 Total Number of SOQL Queries allowed in this apex code context: ' +
      Limits.getLimitQueries()
    );
    opp.Term_Loan_Type__c = '10 Year';
    opp.YM_Prepayment_Penalty__c = '114 Months';
    update opp;
    System.debug(
      'RS999 - 11 Total Number of SOQL Queries allowed in this apex code context: ' +
      Limits.getLimitQueries()
    );
    List<String> docIds = new List<String>();
    docIds.add(doc.id);

    opportunity_Helper.getFiles(opp.id, docInfo.id);
    opportunity_Helper.reviewDocuments(docIds);
    Test.stopTest();

    Map<Id, Opportunity> newoppmap = new Map<Id, Opportunity>();
    Map<Id, Opportunity> oldoppmap = new Map<Id, Opportunity>();

    /*newoppmap.put(opp.id,opp);
        oldoppmap.put(opp2.id,opp2);
        
        opportunity_Helper.beforeUpdate(newoppmap,oldoppmap); */
  }
  static testMethod void opportunity_UnitTest6() {
    id recType = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get('Broker')
      .getRecordTypeId();

    Account a = new Account();
    a.Name = 'Alston & Bird';
    a.BillingCountry = 'United States';
    a.BillingState = 'California';
    a.Introductions_Source__c = 'Hotline';
    a.Introduction_Subsource__c = 'Main';
    a.Alternate_Phone__c = '55555555355';
    a.RecordTypeId = recType;
    insert a;
    system.debug('a id ' + a.recordTypeId);
    Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
    Contact cont = [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
    cont.AccountId = acc.Id;
    update cont;

    Opportunity opp = new Opportunity();
    opp.Name = 'test';
    opp.CloseDate = System.today();
    opp.StageName = 'Initial Review';
    opp.Loan_Size__c = 2000000;
    opp.AccountId = a.Id;
    opp.Contact__c = cont.Id;
    opp.Final_Loan_Amount__c = 100;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_Source__c = 'Main';
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    opp.GLC_Approved__c = true;
    opp.Background_Check_Completed__c = true;
    insert opp;
  }

  @isTest
  public static void securitizationDealTest() {
    Account testAcc = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Helper Account'
    ];
    Contact testCtc = [SELECT Id FROM Contact WHERE AccountId = :testAcc.Id];
    Opportunity testDeal = Test_Helper.createTermDeal(testAcc, testCtc);

    Securitization__c testSc = Test_Helper.createSecuritization();
    testDeal.Securitized__c = false;
    testDeal.Securitization__c = null;
    Map<Id, Opportunity> oldTestMap = new Map<Id, Opportunity>{
      testDeal.Id => testDeal
    };

    Opportunity newTestDeal = testDeal.clone(true, true, true, true);
    newTestDeal.Securitization__c = testSc.Id;
    newTestDeal.Securitized__c = true;

    Map<Id, Opportunity> newTestMap = new Map<Id, Opportunity>{
      newTestDeal.Id => newTestDeal
    };

    opportunity_Helper.beforeUpdate(newTestMap, oldTestMap);
    opportunity_Helper.afterUpdate(newTestMap, oldTestMap);

    update newTestDeal;

    Securitization__c testSc2 = testSc.clone(false, true, false, false);
    testSc2.Name = 'Test 2';
    insert testSc2;

    oldTestMap.put(newTestDeal.Id, newTestDeal);
    Opportunity newerTestDeal = newTestDeal.clone(true, true, true, true);
    newerTestDeal.Securitization__c = testSc2.Id;
    newTestMap.put(newerTestDeal.Id, newerTestDeal);

    opportunity_Helper.beforeUpdate(newTestMap, oldTestMap);
    opportunity_Helper.afterUpdate(newTestMap, oldTestMap);
    update newerTestDeal;
  }

  @isTest
  public static void fundingVehiclesTests() {
    Account testAcc = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Helper Account'
    ];
    Contact testCtc = [SELECT Id FROM Contact WHERE AccountId = :testAcc.Id];
    Opportunity testDeal = Test_Helper.createTermDeal(testAcc, testCtc);

    Funding_Vehicle__c testFv = Test_Helper.createFundingVehicle(false, null);

    testDeal.Warehouse_Line__c = null;
    Map<Id, Opportunity> oldTestMap = new Map<Id, Opportunity>{
      testDeal.Id => testDeal
    };

    Opportunity newTestDeal = testDeal.clone(true, true, true, true);
    newTestDeal.Warehouse_Line__c = 'Churchill';
    Map<Id, Opportunity> newTestMap = new Map<Id, Opportunity>{
      newTestDeal.Id => newTestDeal
    };

    opportunity_Helper.beforeUpdate(newTestMap, oldTestMap);
    opportunity_Helper.afterUpdate(newTestMap, oldTestMap);

    update newTestDeal;

    Securitization__c testSc2 = Test_Helper.createSecuritization();

    Funding_Vehicle__c testFv2 = [
      SELECT Id, Securitization__c
      FROM Funding_Vehicle__c
      WHERE Securitization__c = :testSc2.Id
    ];

    oldTestMap.put(newTestDeal.Id, newTestDeal);
    Opportunity newerTestDeal = newTestDeal.clone(true, true, true, true);

    newerTestDeal.Securitized__c = true;
    newerTestDeal.Securitization__c = testSc2.Id;
    newTestMap.put(newerTestDeal.Id, newerTestDeal);

    opportunity_Helper.beforeUpdate(newTestMap, oldTestMap);
    opportunity_Helper.afterUpdate(newTestMap, oldTestMap);

    update newerTestDeal;
  }
}