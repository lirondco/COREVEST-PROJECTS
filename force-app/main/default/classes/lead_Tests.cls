@isTest
private class lead_Tests {
  //static List<Account> testAccounts = testDataFactory.createTestRecords(new Account[10]);

  static testMethod void lead_Tests_UnitTest() {
    Lead_Settings__c setting = new Lead_Settings__c(
      Name = 'CAF Website',
      Round_Robin_Max__c = 6,
      Round_Robin_Value__c = 1
    );
    insert setting;
    Test.startTest();
    Lead l = new Lead(
      FirstName = 'Test1',
      LastName = 'Tester',
      Company = 'Test Company1',
      Email = 'test111@test.com',
      Phone = '5555555555',
      MobilePhone = '5555555555',
      Introduction_Source__c = 'Event',
      Applicant_Type__c = 'Lender',
      OwnerId = UserInfo.getUserId(),
      utm_Campaign_Name__c  = 'test',
      utm_Campaign_Content__c  = 'test',
      utm_Campaign_Medium__c  = 'test',
      utm_Campaign_Source__c  = 'test',
      utm_Campaign_Term__c  = 'test'
    );
    Lead l2 = new Lead(
      FirstName = 'Test2',
      LastName = 'Tester1',
      Company = 'None',
      Email = 'test222@test.com',
      Introduction_Source__c = 'Event',
      Applicant_Type__c = 'Borrower',
      OwnerId = UserInfo.getUserId()
    );

    Lead l3 = new Lead(
      FirstName = 'Test3',
      LastName = 'Tester3',
      email = 'test3@tester.com',
      Company = 'Test Company3',
      Introduction_Source__c = 'Pre-Prod',
      Introduction_Subsource__c = 'Pre-Prod Main Application',
      Applicant_Type__c = 'Broker',
      OwnerId = UserInfo.getUserId()
    );

    Lead l4 = new Lead(
      FirstName = 'Test3',
      LastName = 'Tester3',
      email = 'test4@tester.com',
      Company = 'Test Company3',
      Introduction_Source__c = 'Hotline',
      OwnerId = UserInfo.getUserId()
    );

    Lead l5 = new Lead(
      FirstName = 'Test3',
      LastName = 'Tester3',
      email = 'tes5t@tester.com',
      Company = 'Test Company3',
      Status = 'Unqualified',
      Introduction_Source__c = 'Hotline'
    );

    List<Lead> leads = new List<Lead>{ l };
    insert leads;

    insert l2;
    insert l3;
    insert l4;
    insert l5;

    l4.Status = 'Unqualified';
    update l4;

    l3.Introduction_Source__c = 'Event';
    update l3;

    l.Applicant_Type__c = 'Borrower';
    update l;

    l2.Applicant_Type__c = 'Lender';
    update l2;

    l3.Applicant_Type__c = 'Broker';
    update l3;

    Lead testLead4 = new Lead(
      FirstName = 'Test4',
      LastName = 'Tester',
      Company = 'Test Company',
      Email = 'test111@test.com',
      Introduction_Source__c = 'Event',
      OwnerId = UserInfo.getUserId()
    );
    insert testLead4;
    testLead4.Phone = '6666666666';
    testLead4.MobilePhone = '8888888888';
    testLead4.Status = 'Unqualified';
    testLead4.Disposition__c = 'Low Fico';
    update testLead4;

    Test.stopTest();

    Lead_Settings__c settingsAfter = Lead_Settings__c.getInstance(
      'CAF Website'
    );
    //System.assertEquals(settingsAfter.Round_Robin_Value__c, 3);

    List<Lead> newLeads = [
      SELECT Id, Round_Robin_Value__c
      FROM Lead
      WHERE Round_Robin_Value__c > 0
      ORDER BY round_robin_value__c ASC
    ];
    //system.assertEquals(newLeads.size(), 2);
    //system.assertEquals(newLeads[0].Round_Robin_Value__c, 1);
    //system.assertEquals(newList[1].Round_Robin_Value__c, 2);
    //system.assertEquals(newLeads[1].Round_Robin_Value__c, 2);

    Set<Id> leadIds = new Set<Id>();
    for (Lead ll : leads) {
      leadIds.add(ll.Id);
    }

    list<lead> leadList = new List<lead>();
    leadList.add(l2);
    leadList.add(l3);
    leadList.add(l4);
    String JSONlead = JSON.serialize(leadList);
    //lead_Helper.reassignLeads(leadIds);

    lead_Helper.afterInsert(leads);
    lead_Helper.updateleadonMarge(JSONlead);
  }

  @IsTest
  static void methodName() {
    Lead_Settings__c setting = new Lead_Settings__c(
      Name = 'CAF Website',
      Round_Robin_Max__c = 6,
      Round_Robin_Value__c = 1
    );
    insert setting;

    //Account acc = test_Helper.createAccount();
    //Contact cont = test_Helper.createContact(acc);
    //Contact_Converted_Into__c = cont.id,Account_Converted_Into__c=acc.id

    Lead l = new Lead(
      FirstName = 'Test1',
      LastName = 'Test1',
      Company = 'Test Company1',
      Email = 'test111@test.com',
      True_source__c = true,
      Introduction_Source__c = 'Event',
      OwnerId = UserInfo.getUserId()
    );
    Lead l2 = new Lead(
      FirstName = 'Test2',
      LastName = 'Tester1',
      Company = 'Test Company 2',
      Email = 'test222@test.com',
      Introduction_Source__c = 'Event',
      True_source__c = true,
      OwnerId = UserInfo.getUserId()
    );

    Lead l3 = new Lead(
      FirstName = 'Test3',
      LastName = 'Tester3',
      email = 'test@tester.com',
      Company = 'Test Company2',
      Introduction_Source__c = 'Event',
      OwnerId = UserInfo.getUserId(),
      Status = 'Contacted'
    );
    insert l2;
    insert l3;

    Master_Source__c ms = new Master_Source__c();
    ms.First_Name__c = 'Test1';
    ms.Last_Name__c = 'Test1';
    ms.Mobile__c = '1234567890';
    ms.Email__c = 'test111@test.com';
    insert ms;

    List<Lead> leads = new List<Lead>{ l };
    insert leads;

    list<Source__c> slist = new List<Source__c>();
    Source__c ss = new Source__c();
    ss.lead__c = l.id;
    ss.Master_Source__c = ms.id;
    ss.Lead_Name__c = l.FirstName + '' + l.LastName;
    ss.IsConvertedLead__c = true;
    slist.add(ss);
    insert slist;

    Lead testLead4 = new Lead(
      FirstName = 'Test4',
      LastName = 'Tester4',
      Company = 'Test Company3',
      Email = 'test111@test.com',
      Introduction_Source__c = 'Event',
      OwnerId = UserInfo.getUserId()
    );
    insert testLead4;

    Test.startTest();

    UnresponsiveLeadSchedulable.updateLeads();
    Test.stopTest();
  }
  @IsTest
  static void methodName1() {
    Lead_Settings__c setting = new Lead_Settings__c(
      Name = 'CAF Website',
      Round_Robin_Max__c = 6,
      Round_Robin_Value__c = 1
    );
    insert setting;

    Test.startTest();

    Account a = new Account();
    a.Name = 'test';
    a.BillingCountry = 'United States';
    a.BillingState = 'California';
    a.Introductions_Source__c = 'Hotline';
    a.Introduction_Subsource__c = 'Main';
    a.Alternate_Phone__c = '5555555555';
    insert a;

    Contact c = new Contact();
    c.FirstName = 'tester';
    c.LastName = 'test';
    c.MailingCountry = 'United States';
    c.MailingState = 'California';
    c.AccountId = a.Id;
    c.MobilePhone = '5555555555';
    c.Phone = '7777777777';
    c.Experian__c = 700;
    c.TransUnion__c = 710;
    c.Equifax__c = 700;
    c.Years_of_Experience__c = 10;
    c.Rental_Units_Owned__c = '5';
    c.Sponsor_Tier__c = 'Tier 1';
    c.Experience__c = 5;
    insert c;

    Opportunity o = new Opportunity();
    o.Name = 'test';
    o.CloseDate = System.today();
    o.StageName = 'Initial Review';
    o.Loan_Size__c = 2000000;
    o.AccountId = a.Id;
    o.Contact__c = c.Id;
    o.Deal_Intro_Source__c = 'Hotline';
    o.Deal_Intro_Sub_Source__c = 'Main';
    o.Apex_Context__c = false;
    insert o;

    Lead olead = new Lead(
      LastName = 'Marc',
      FirstName = 'Benioff',
      Status = 'Open',
      email = 'm.benioff@salesforce.com',
      Introduction_Source__c = 'Event',
      Contact_Converted_Into__c = c.id,
      Account_Converted_Into__c = a.id /*,Deal_Converted_Into__c = o.id*/
    );
    insert olead;
    System.debug(':::::olead::::' + olead);
    Database.LeadConvert lc = new database.LeadConvert();
    lc.setLeadId(olead.id);
    lc.setDoNotCreateOpportunity(true);
    lc.setConvertedStatus('Qualified');
    Database.LeadConvertResult lcr = Database.convertLead(lc);
    System.debug(':::::Database.LeadConvertResult::::' + lcr.isSuccess());
    System.assert(lcr.isSuccess());
    Test.stopTest();
  }
}