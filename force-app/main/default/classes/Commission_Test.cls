@isTest
private class Commission_Test {
  //term
  //Term no Comm total current quarter
  //

  @testSetup
  static void setup() {
    commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    insert settings;
    List<Period> periodQuery = [
      SELECT StartDate, EndDate
      FROM Period
      WHERE
        Type = 'Quarter'
        AND (StartDate = THIS_FISCAL_QUARTER
        OR StartDate = LAST_FISCAL_QUARTER)
      ORDER BY StartDate
    ];

    Date startdate = periodQuery[1].StartDate;
    //QuotaAmount,
    //QuotaOwnerId,
    //QuotaOwner.Name,
    //ProductFamily
    //StartDate
    List<ForecastingType> fts = [
      SELECT Id, HasProductFamily
      FROM ForecastingType
      WHERE isActive = TRUE
    ];
    ForecastingType ft = new ForecastingType();
    for (ForecastingType f : fts) {
      if (f.HasProductFamily == true) {
        ft = f;
        break;
      }
    }

    User origU = new User(
      Alias = 'orig',
      Email = 'standarduser@cvest.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originator@teada.com',
      ForecastEnabled = true
    );

    insert origU;

    ForecastingQuota fqTerm = new ForecastingQuota();
    fqTerm.QuotaAmount = 100;
    fqTerm.QuotaOwnerId = origU.Id;
    fqTerm.ProductFamily = 'Term';
    fqTerm.StartDate = startdate;
    fqTerm.ForecastingTypeId = ft.Id;
    insert fqTerm;
    ForecastingQuota fqBridge = new ForecastingQuota();
    fqBridge.QuotaAmount = 100;
    fqBridge.QuotaOwnerId = origU.Id;
    fqBridge.ProductFamily = 'Bridge';
    fqBridge.StartDate = startdate;
    fqBridge.ForecastingTypeId = ft.Id;
    insert fqBridge;
  }

  @isTest
  static void Commissiontest1() {
    // 1st term condition

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account a = new Account();
    a.Name = 'test';
    a.BillingCountry = 'United States';
    a.BillingState = 'California';
    a.Introductions_Source__c = 'Hotline';
    a.Introduction_Subsource__c = 'Main';
    a.Alternate_Phone__c = '5555555555';
    insert a;

    Contact c = new Contact();
    c.FirstName = 'test';
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

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = a.Id;
    topp1.Contact__c = c.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    // topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;

    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    system.debug('caf fee' + topp1.CAF_Upfront_Fee__c);
    system.debug('caf fee' + topp1.Name);

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];
    Test.startTest();
    commDetailUpdate.Approval_Status__c = 'Approved';

    update commDetailUpdate;
    Test.stopTest();
  }
  @isTest
  static void Commissiontest2() {
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp2 = new Opportunity();
    topp2.Name = 'test';
    topp2.CloseDate = System.today();
    topp2.StageName = 'Closed Won';
    topp2.Loan_Size__c = 2000000;
    topp2.AccountId = acc.Id;
    topp2.Contact__c = cont.Id;
    topp2.OwnerId = origU.id;
    topp2.CAF_YSP__c = null;
    topp2.Type = 'Term Loan';
    topp2.CAF_Upfront_Fee__c = 2;
    topp2.Final_Loan_Amount__c = 30000000;
    topp2.Deal_Intro_Source__c = 'Hotline';
    topp2.Deal_Intro_Sub_Source__c = 'Main';
    topp2.Apex_Context__c = true;
    topp2.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp2;

    topp2.CAF_Upfront_Fee__c = 2;
    update topp2;

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 100000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;

    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;
    list<account> myaccountTotalTermAmount = [
      SELECT Borrowed_on_Term_Loans__c
      FROM account
      WHERE id = :acc.id
    ];
    system.debug('Acc Total' + myaccountTotalTermAmount);

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];

    commDetailUpdate.Approval_Status__c = 'Approved';

    update commDetailUpdate;
  }

  //Term w Comm Total current quarter
  @isTest
  static void Commissiontest3() {
    // 1st term condition
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;
    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;
    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;
    Commission_Total__c myCommissionTotal = new Commission_Total__c();
    myCommissionTotal.OwnerId = origU.id;
    myCommissionTotal.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal;

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];

    commDetailUpdate.Approval_Status__c = 'Approved';

    update commDetailUpdate;
  }
  @isTest
  static void Commissiontest4() {
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings
    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;
    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp2 = new Opportunity();
    topp2.Name = 'test';
    topp2.CloseDate = System.today();
    topp2.StageName = 'Closed Won';
    topp2.Loan_Size__c = 2000000;
    topp2.AccountId = acc.Id;
    topp2.Contact__c = cont.Id;
    topp2.OwnerId = origU.id;
    topp2.CAF_YSP__c = null;
    topp2.Type = 'Term Loan';
    topp2.CAF_Upfront_Fee__c = 2;
    topp2.Final_Loan_Amount__c = 30000000;
    topp2.Deal_Intro_Source__c = 'Hotline';
    topp2.Deal_Intro_Sub_Source__c = 'Main';
    topp2.Apex_Context__c = true;
    topp2.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp2;
    topp2.CAF_Upfront_Fee__c = 2;
    update topp2;

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;
    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;

    Commission_Total__c myCommissionTotal = new Commission_Total__c();
    myCommissionTotal.OwnerId = origU.id;
    myCommissionTotal.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal;

    list<account> myaccountTotalTermAmount = [
      SELECT Borrowed_on_Term_Loans__c
      FROM account
      WHERE id = :acc.id
    ];
    system.debug('Acc Total' + myaccountTotalTermAmount);

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];

    commDetailUpdate.Approval_Status__c = 'Approved';
    test.startTest();
    update commDetailUpdate;
    test.stopTest();
  }
  // Term w Comm Total last quarter
  @isTest
  static void Commissiontest5() {
    // 1st term condition
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;
    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = quarterStartDateLastQ.addDays(3);
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;
    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;

    Commission_Total__c myCommissionTotal = new Commission_Total__c();
    myCommissionTotal.OwnerId = origU.id;
    myCommissionTotal.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal;

    Commission_Total__c myCommissionTotal2 = new Commission_Total__c();
    myCommissionTotal2.OwnerId = origU.id;
    myCommissionTotal2.Quarter_Start_Date__c = quarterStartDateLastQ;
    myCommissionTotal2.Quarter_End_Date__c = quarterEndDateLastQ;
    insert myCommissionTotal2;

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];

    commDetailUpdate.Approval_Status__c = 'Approved';

    update commDetailUpdate;
  }
  @isTest
  static void Commissiontest6() {
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;
    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp2 = new Opportunity();
    topp2.Name = 'test';
    topp2.CloseDate = quarterStartDateLastQ.addDays(5);
    topp2.StageName = 'Closed Won';
    topp2.Loan_Size__c = 2000000;
    topp2.AccountId = acc.Id;
    topp2.Contact__c = cont.Id;
    topp2.OwnerId = origU.id;
    topp2.CAF_YSP__c = null;
    topp2.Type = 'Term Loan';
    topp2.CAF_Upfront_Fee__c = 2;
    topp2.Final_Loan_Amount__c = 30000000;
    topp2.Deal_Intro_Source__c = 'Hotline';
    topp2.Deal_Intro_Sub_Source__c = 'Main';
    topp2.Apex_Context__c = true;
    topp2.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp2;
    topp2.CAF_Upfront_Fee__c = 2;
    update topp2;

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = quarterStartDateLastQ.addDays(5);
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;
    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;
    Commission_Total__c myCommissionTotal = new Commission_Total__c();
    myCommissionTotal.OwnerId = origU.id;
    myCommissionTotal.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal;

    Commission_Total__c myCommissionTotal2 = new Commission_Total__c();
    myCommissionTotal2.OwnerId = origU.id;
    myCommissionTotal2.Quarter_Start_Date__c = quarterStartDateLastQ;
    myCommissionTotal2.Quarter_End_Date__c = quarterEndDateLastQ;
    insert myCommissionTotal2;

    list<account> myaccountTotalTermAmount = [
      SELECT Borrowed_on_Term_Loans__c
      FROM account
      WHERE id = :acc.id
    ];
    system.debug('Acc Total' + myaccountTotalTermAmount);

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];

    commDetailUpdate.Approval_Status__c = 'Approved';
    test.startTest();
    update commDetailUpdate;
    test.stopTest();
  }
  // Term w last quarter commission only
  @isTest
  static void Commissiontest7() {
    // 1st term condition
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings
    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@cvest.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originatooor@teada.com'
    );

    insert origU2;

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;
    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;

    Commission_Total__c myCommissionTotal2 = new Commission_Total__c();
    myCommissionTotal2.OwnerId = origU.id;
    myCommissionTotal2.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal2.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal2;

    Commission_Total__c myCommissionTotal3 = new Commission_Total__c();
    myCommissionTotal3.OwnerId = origU2.id;
    myCommissionTotal3.Quarter_Start_Date__c = quarterStartDateLastQ;
    myCommissionTotal3.Quarter_End_Date__c = quarterEndDateLastQ;
    insert myCommissionTotal3;

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Internal_Referral__c = origU2.id;
    commDetail.Internal_Referral_Fee__c = '50%';
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];

    commDetailUpdate.Approval_Status__c = 'Approved';

    update commDetailUpdate;
  }
  @isTest
  static void Commissiontest8() {
    // 1st term condition
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings
    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp2 = new Opportunity();
    topp2.Name = 'test';
    topp2.CloseDate = System.today();
    topp2.StageName = 'Closed Won';
    topp2.Loan_Size__c = 2000000;
    topp2.AccountId = acc.Id;
    topp2.Contact__c = cont.Id;
    topp2.OwnerId = origU.id;
    topp2.CAF_YSP__c = null;
    topp2.Type = 'Term Loan';
    topp2.CAF_Upfront_Fee__c = 2;
    topp2.Final_Loan_Amount__c = 30000000;
    topp2.Deal_Intro_Source__c = 'Hotline';
    topp2.Deal_Intro_Sub_Source__c = 'Main';
    topp2.Apex_Context__c = true;
    topp2.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp2;
    topp2.CAF_Upfront_Fee__c = 2;
    update topp2;

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;
    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;

    Commission_Total__c myCommissionTotal2 = new Commission_Total__c();
    myCommissionTotal2.OwnerId = origU.id;
    myCommissionTotal2.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal2.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal2;

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];

    commDetailUpdate.Approval_Status__c = 'Approved';
    test.startTest();
    update commDetailUpdate;
    test.stopTest();
  }

  @isTest
  static void Commissiontest9() {
    // 1st term condition
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings
    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@cvest.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originatooor@teada.com'
    );

    insert origU2;

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp2 = new Opportunity();
    topp2.Name = 'test';
    topp2.CloseDate = System.today();
    topp2.StageName = 'Closed Won';
    topp2.Loan_Size__c = 2000000;
    topp2.AccountId = acc.Id;
    topp2.Contact__c = cont.Id;
    topp2.OwnerId = origU.id;
    topp2.CAF_YSP__c = null;
    topp2.Type = 'Term Loan';
    topp2.CAF_Upfront_Fee__c = 2;
    topp2.Final_Loan_Amount__c = 30000000;
    topp2.Deal_Intro_Source__c = 'Hotline';
    topp2.Deal_Intro_Sub_Source__c = 'Main';
    topp2.Apex_Context__c = true;
    topp2.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp2;
    topp2.CAF_Upfront_Fee__c = 2;
    update topp2;

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;
    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;

    Commission_Total__c myCommissionTotal2 = new Commission_Total__c();
    myCommissionTotal2.OwnerId = origU.id;
    myCommissionTotal2.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal2.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal2;

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Internal_Referral__c = origU.id;
    commDetail.Internal_Referral_Fee__c = '50%';
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];

    commDetailUpdate.Approval_Status__c = 'Approved';
    test.startTest();
    update commDetailUpdate;
    test.stopTest();
  }

  @isTest
  static void Commissiontest10() {
    // 1st term condition
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings
    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@cvest.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originatooor@teada.com'
    );

    insert origU2;

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp2 = new Opportunity();
    topp2.Name = 'test';
    topp2.CloseDate = System.today();
    topp2.StageName = 'Closed Won';
    topp2.Loan_Size__c = 2000000;
    topp2.AccountId = acc.Id;
    topp2.Contact__c = cont.Id;
    topp2.OwnerId = origU.id;
    topp2.CAF_YSP__c = null;
    topp2.Type = 'Term Loan';
    topp2.CAF_Upfront_Fee__c = 2;
    topp2.Final_Loan_Amount__c = 30000000;
    topp2.Deal_Intro_Source__c = 'Hotline';
    topp2.Deal_Intro_Sub_Source__c = 'Main';
    topp2.Apex_Context__c = true;
    topp2.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp2;

    topp2.CAF_Upfront_Fee__c = 2;
    update topp2;

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;
    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;

    Commission_Total__c myCommissionTotal2 = new Commission_Total__c();
    myCommissionTotal2.OwnerId = origU.id;
    myCommissionTotal2.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal2.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal2;

    Commission_Total__c myCommissionTotal3 = new Commission_Total__c();
    myCommissionTotal3.OwnerId = origU2.id;
    myCommissionTotal3.Quarter_Start_Date__c = quarterStartDateLastQ;
    myCommissionTotal3.Quarter_End_Date__c = quarterEndDateLastQ;
    insert myCommissionTotal3;

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Internal_Referral__c = origU2.id;
    commDetail.Internal_Referral_Fee__c = '50%';
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];

    commDetailUpdate.Approval_Status__c = 'Approved';
    test.startTest();
    update commDetailUpdate;
    test.stopTest();
  }
  @isTest
  static void Commissiontest11() {
    // 1st term condition
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings
    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@cvest.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originatooor@teada.com'
    );

    insert origU2;

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = quarterStartDateLastQ.addDays(5);
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;

    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;

    Commission_Total__c myCommissionTotal2 = new Commission_Total__c();
    myCommissionTotal2.OwnerId = origU.id;
    myCommissionTotal2.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal2.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal2;

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Internal_Referral__c = origU2.id;
    commDetail.Internal_Referral_Fee__c = '50%';
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];

    commDetailUpdate.Approval_Status__c = 'Approved';

    update commDetailUpdate;
  }

  @isTest
  static void Commissiontest12() {
    // 1st term condition
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings
    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@cvest.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originatooor@teada.com'
    );

    insert origU2;

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp2 = new Opportunity();
    topp2.Name = 'test';
    topp2.CloseDate = quarterStartDateLastQ.addDays(5);
    topp2.StageName = 'Closed Won';
    topp2.Loan_Size__c = 2000000;
    topp2.AccountId = acc.Id;
    topp2.Contact__c = cont.Id;
    topp2.OwnerId = origU.id;
    topp2.CAF_YSP__c = null;
    topp2.Type = 'Term Loan';
    topp2.CAF_Upfront_Fee__c = 2;
    topp2.Final_Loan_Amount__c = 30000000;
    topp2.Deal_Intro_Source__c = 'Hotline';
    topp2.Deal_Intro_Sub_Source__c = 'Main';
    topp2.Apex_Context__c = true;
    topp2.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp2;

    topp2.CAF_Upfront_Fee__c = 2;
    update topp2;

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = quarterStartDateLastQ.addDays(5);
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;
    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;

    Commission_Total__c myCommissionTotal2 = new Commission_Total__c();
    myCommissionTotal2.OwnerId = origU.id;
    myCommissionTotal2.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal2.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal2;

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Internal_Referral__c = origU2.id;
    commDetail.Internal_Referral_Fee__c = '50%';
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];

    commDetailUpdate.Approval_Status__c = 'Approved';
    test.startTest();
    update commDetailUpdate;
    test.stopTest();
  }

  @isTest
  static void Commissiontest13() {
    // 1st term condition
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings
    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@cvest.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originatooor@teada.com'
    );

    insert origU2;

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = quarterStartDateLastQ.addDays(5);
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;
    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;

    Commission_Total__c myCommissionTotal2 = new Commission_Total__c();
    myCommissionTotal2.OwnerId = origU.id;
    myCommissionTotal2.Quarter_Start_Date__c = quarterStartDateLastQ;
    myCommissionTotal2.Quarter_End_Date__c = quarterEndDateLastQ;
    insert myCommissionTotal2;

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Internal_Referral__c = origU2.id;
    commDetail.Internal_Referral_Fee__c = '50%';
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];

    commDetailUpdate.Approval_Status__c = 'Approved';

    update commDetailUpdate;
  }

  @isTest
  static void Commissiontest14() {
    // 1st term condition
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings
    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@cvest.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originatooor@teada.com'
    );

    insert origU2;

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp2 = new Opportunity();
    topp2.Name = 'test';
    topp2.CloseDate = quarterStartDateLastQ.addDays(5);
    topp2.StageName = 'Closed Won';
    topp2.Loan_Size__c = 2000000;
    topp2.AccountId = acc.Id;
    topp2.Contact__c = cont.Id;
    topp2.OwnerId = origU.id;
    topp2.CAF_YSP__c = null;
    topp2.Type = 'Term Loan';
    topp2.CAF_Upfront_Fee__c = 2;
    topp2.Final_Loan_Amount__c = 30000000;
    topp2.Deal_Intro_Source__c = 'Hotline';
    topp2.Deal_Intro_Sub_Source__c = 'Main';
    topp2.Apex_Context__c = true;
    topp2.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp2;

    topp2.CAF_Upfront_Fee__c = 2;
    update topp2;

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = quarterStartDateLastQ.addDays(5);
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;
    topp1.CAF_Upfront_Fee__c = 2;
    update topp1;

    Commission_Total__c myCommissionTotal2 = new Commission_Total__c();
    myCommissionTotal2.OwnerId = origU.id;
    myCommissionTotal2.Quarter_Start_Date__c = quarterStartDateLastQ;
    myCommissionTotal2.Quarter_End_Date__c = quarterEndDateLastQ;
    insert myCommissionTotal2;

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Internal_Referral__c = origU2.id;
    commDetail.Internal_Referral_Fee__c = '50%';
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Detail__c commDetailUpdate = [
      SELECT Approval_Status__c
      FROM Commission_Detail__c
      WHERE id = :commDetail.Id
    ];

    commDetailUpdate.Approval_Status__c = 'Approved';
    test.startTest();
    update commDetailUpdate;
    test.stopTest();
  }

  // Bridge
  @isTest
  static void Commissiontest15() {
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.Type = 'Bridge Loan';
    topp1.Loan_Effective_Date__c = system.today();
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    insert topp1;

    Commission__c myCommission = new Commission__c();
    myCommission.Commission_Amount1__c = 1230;
    myCommission.Deal__c = topp1.id;
    myCommission.Owner__c = origU.id;
    myCommission.Loan_Type__c = 'Bridge Loan';
    insert myCommission;
  }

  @isTest
  static void Commissiontest21() {
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@cvest.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originatoor@teada.com'
    );

    insert origU2;

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.Type = 'Bridge Loan';

    topp1.Loan_Effective_Date__c = system.today();
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    insert topp1;

    Advance__c adv = new Advance__c(
      Deal__c = topp1.Id,
      Status__c = 'Pending',
      Wire_Date__c = quarterStartDateLastQ.addDays(5)
    );
    insert adv;

    Commission_Detail__c myCommissionDetail = new Commission_Detail__c();
    myCommissionDetail.Deal__c = topp1.Id;
    myCommissionDetail.OwnerId = origU.id;
    insert myCommissionDetail;

    Commission__c myCommission = new Commission__c();
    myCommission.Commission_Amount1__c = 1230;
    myCommission.Deal__c = topp1.id;
    myCommission.Owner__c = origU.id;
    myCommission.Advance__c = adv.id;
    myCommission.Loan_Type__c = 'Bridge Loan';
    insert myCommission;
  }

  @isTest
  static void Commissiontest22() {
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@cvest.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originatoor@teada.com'
    );

    insert origU2;

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Internal_Referral__c = origU2.id;
    topp1.Internal_Referral_Fee__c = '50%';
    topp1.Apex_Context__c = true;
    topp1.Type = 'Bridge Loan';

    topp1.Loan_Effective_Date__c = system.today();
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    insert topp1;

    Advance__c adv = new Advance__c(
      Deal__c = topp1.Id,
      Status__c = 'Pending',
      Wire_Date__c = quarterStartDateLastQ.addDays(5)
    );
    insert adv;

    Commission_Detail__c myCommissionDetail = new Commission_Detail__c();
    myCommissionDetail.Deal__c = topp1.Id;
    myCommissionDetail.OwnerId = origU.id;
    insert myCommissionDetail;

    Commission_Total__c myCommissionTotal = new Commission_Total__c();
    myCommissionTotal.OwnerId = origU2.id;
    myCommissionTotal.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal;

    Commission_Total__c myCommissionTotal1 = new Commission_Total__c();
    myCommissionTotal1.OwnerId = origU.id;
    myCommissionTotal1.Quarter_Start_Date__c = quarterStartDateLastQ;
    myCommissionTotal1.Quarter_End_Date__c = quarterEndDateLastQ;
    insert myCommissionTotal1;

    Commission__c myCommission = new Commission__c();
    myCommission.Commission_Amount1__c = 1230;
    myCommission.Deal__c = topp1.id;
    myCommission.Owner__c = origU.id;
    myCommission.Advance__c = adv.id;
    myCommission.Loan_Type__c = 'Bridge Loan';
    insert myCommission;
  }
  @isTest
  static void Commissiontest23() {
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@cvest.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originatoor@teada.com'
    );

    insert origU2;

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Internal_Referral__c = origU2.id;
    topp1.Internal_Referral_Fee__c = '50%';

    topp1.Apex_Context__c = true;
    topp1.Type = 'Bridge Loan';

    topp1.Loan_Effective_Date__c = system.today();
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    insert topp1;

    Advance__c adv = new Advance__c(
      Deal__c = topp1.Id,
      Status__c = 'Pending',
      Wire_Date__c = quarterStartDateLastQ.addDays(5)
    );
    insert adv;

    Commission_Total__c myCommissionTotal = new Commission_Total__c();
    myCommissionTotal.OwnerId = origU.id;
    myCommissionTotal.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal;

    Commission_Total__c myCommissionTotal1 = new Commission_Total__c();
    myCommissionTotal1.OwnerId = origU.id;
    myCommissionTotal1.Quarter_Start_Date__c = quarterStartDateLastQ;
    myCommissionTotal1.Quarter_End_Date__c = quarterEndDateLastQ;
    insert myCommissionTotal1;

    Commission__c myCommission = new Commission__c();
    myCommission.Commission_Amount1__c = 1230;
    myCommission.Deal__c = topp1.id;
    myCommission.Owner__c = origU.id;
    myCommission.Advance__c = adv.id;
    myCommission.Loan_Type__c = 'Bridge Loan';
    insert myCommission;
  }
  @isTest
  static void Commissiontest24() {
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    User origU2 = new User(
      Alias = 'orig',
      Email = 'standarduser@cvest.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Relationship Manager']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'originatoor@teada.com'
    );

    insert origU2;

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Internal_Referral__c = origU2.id;
    topp1.Internal_Referral_Fee__c = '50%';
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.Type = 'Bridge Loan';

    topp1.Loan_Effective_Date__c = system.today();
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    insert topp1;

    Advance__c adv = new Advance__c(
      Deal__c = topp1.Id,
      Status__c = 'Pending',
      Wire_Date__c = quarterStartDateLastQ.addDays(5)
    );
    insert adv;

    Commission_Total__c myCommissionTotal1 = new Commission_Total__c();
    myCommissionTotal1.OwnerId = origU.id;
    myCommissionTotal1.Quarter_Start_Date__c = quarterStartDateLastQ;
    myCommissionTotal1.Quarter_End_Date__c = quarterEndDateLastQ;
    insert myCommissionTotal1;

    Commission__c myCommission = new Commission__c();
    myCommission.Commission_Amount1__c = 1230;
    myCommission.Deal__c = topp1.id;
    myCommission.Owner__c = origU.id;
    myCommission.Advance__c = adv.id;
    myCommission.Loan_Type__c = 'Bridge Loan';
    insert myCommission;
  }
  static testMethod void Commissiontest25() {
    //internal
    /*  Account acc = test_Helper.createAccount();
        Contact cont = test_Helper.createContact( acc );
        Opportunity opp = test_Helper.createOpportunity( acc, cont ); */

    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account a = new Account();
    a.Name = 'test';
    a.BillingCountry = 'United States';
    a.BillingState = 'California';
    a.Introductions_Source__c = 'Hotline';
    a.Introduction_Subsource__c = 'Main';
    a.Alternate_Phone__c = '5555555555';
    insert a;

    Contact c = new Contact();
    c.FirstName = 'test';
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

    Opportunity opp = new Opportunity();
    opp.Name = 'test opportunity';
    opp.CloseDate = System.today();
    opp.StageName = 'Initial Review';
    opp.Loan_Size__c = 200000001;
    opp.AccountId = a.Id;
    opp.Contact__c = c.Id;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_Source__c = 'Main';
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert opp;

    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 300000001;
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Commission_Type__c = 'Direct';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;
    opp.Amount = 30000000;
    opp.Internal_Referral__c = UserInfo.getUserId();
    opp.Internal_Referral_Fee__c = '20%';

    update opp;

    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Pending';
    property.Override_Origination_Fee__c = 10001;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;

    Commission_Total__c myCommissionTotal = new Commission_Total__c();
    myCommissionTotal.OwnerId = origU.id;
    myCommissionTotal.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal;

    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Wire_Date__c = quarterStartDate
    );
    insert adv;
    Test.startTest();

    Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 50000001;
    padv.Renovation_Reserve__c = 50000001;
    padv.Origination_Fee__c = 1000;

    insert padv;

    update opp;
    adv.Wire_Date__c = quarterStartDate.addDays(4);

    // adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    system.debug('Deal Amount' + opp.Amount);
    test.stopTest();
  }
  static testMethod void Commissiontest26() {
    //internal
    /*  Account acc = test_Helper.createAccount();
        Contact cont = test_Helper.createContact( acc );
        Opportunity opp = test_Helper.createOpportunity( acc, cont ); */

    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account a = new Account();
    a.Name = 'test';
    a.BillingCountry = 'United States';
    a.BillingState = 'California';
    a.Introductions_Source__c = 'Hotline';
    a.Introduction_Subsource__c = 'Main';
    a.Alternate_Phone__c = '5555555555';
    insert a;

    Contact c = new Contact();
    c.FirstName = 'test';
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

    Opportunity opp = new Opportunity();
    opp.Name = 'test opportunity';
    opp.CloseDate = System.today();
    opp.StageName = 'Initial Review';
    opp.Loan_Size__c = 200000001;
    opp.AccountId = a.Id;
    opp.Contact__c = c.Id;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_Source__c = 'Main';
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert opp;

    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 300000001;
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Commission_Type__c = 'Direct';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;
    opp.Amount = 30000000;
    opp.Internal_Referral__c = UserInfo.getUserId();
    opp.Internal_Referral_Fee__c = '20%';

    update opp;

    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Pending';
    property.Override_Origination_Fee__c = 10001;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;

    Commission_Total__c myCommissionTotal = new Commission_Total__c();
    myCommissionTotal.OwnerId = origU.id;
    myCommissionTotal.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal;

    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Wire_Date__c = quarterStartDateLastQ
    );
    insert adv;
    Test.startTest();

    Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 50000001;
    padv.Renovation_Reserve__c = 50000001;
    padv.Origination_Fee__c = 1000;

    insert padv;

    update opp;
    adv.Wire_Date__c = quarterStartDateLastQ.addDays(2);

    // adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    system.debug('Deal Amount' + opp.Amount);
    test.stopTest();
  }

  static testMethod void Commissiontest27() {
    //internal
    /*  Account acc = test_Helper.createAccount();
        Contact cont = test_Helper.createContact( acc );
        Opportunity opp = test_Helper.createOpportunity( acc, cont ); */

    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account a = new Account();
    a.Name = 'test';
    a.BillingCountry = 'United States';
    a.BillingState = 'California';
    a.Introductions_Source__c = 'Hotline';
    a.Introduction_Subsource__c = 'Main';
    a.Alternate_Phone__c = '5555555555';
    insert a;

    Contact c = new Contact();
    c.FirstName = 'test';
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

    Opportunity opp = new Opportunity();
    opp.Name = 'test opportunity';
    opp.CloseDate = System.today();
    opp.StageName = 'Initial Review';
    opp.Loan_Size__c = 200000001;
    opp.AccountId = a.Id;
    opp.Contact__c = c.Id;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_Source__c = 'Main';
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert opp;

    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 300000001;
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Commission_Type__c = 'Direct';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;
    opp.Amount = 30000000;
    opp.Internal_Referral__c = UserInfo.getUserId();
    opp.Internal_Referral_Fee__c = '20%';

    update opp;

    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Pending';
    property.Override_Origination_Fee__c = 10001;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;

    Commission_Detail__c myCommissionDetail = new Commission_Detail__c();
    myCommissionDetail.Deal__c = opp.Id;
    myCommissionDetail.OwnerId = origU.id;
    insert myCommissionDetail;

    Commission_Total__c myCommissionTotal = new Commission_Total__c();
    myCommissionTotal.OwnerId = origU.id;
    myCommissionTotal.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal;

    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Wire_Date__c = quarterStartDateLastQ
    );
    insert adv;
    Test.startTest();

    Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 50000001;
    padv.Renovation_Reserve__c = 50000001;
    padv.Origination_Fee__c = 1000;

    insert padv;

    update opp;
    adv.Wire_Date__c = quarterStartDateLastQ.addDays(2);

    // adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    system.debug('Deal Amount' + opp.Amount);
    test.stopTest();
  }
  static testMethod void Commissiontest28() {
    //internal
    /*  Account acc = test_Helper.createAccount();
        Contact cont = test_Helper.createContact( acc );
        Opportunity opp = test_Helper.createOpportunity( acc, cont ); */

    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account a = new Account();
    a.Name = 'test';
    a.BillingCountry = 'United States';
    a.BillingState = 'California';
    a.Introductions_Source__c = 'Hotline';
    a.Introduction_Subsource__c = 'Main';
    a.Alternate_Phone__c = '5555555555';
    insert a;

    Contact c = new Contact();
    c.FirstName = 'test';
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

    Opportunity opp = new Opportunity();
    opp.Name = 'test opportunity';
    opp.CloseDate = System.today();
    opp.StageName = 'Initial Review';
    opp.Loan_Size__c = 200000001;
    opp.AccountId = a.Id;
    opp.Contact__c = c.Id;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_Source__c = 'Main';
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert opp;

    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 300000001;
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Commission_Type__c = 'Direct';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;
    opp.Amount = 30000000;
    opp.Internal_Referral__c = UserInfo.getUserId();
    opp.Internal_Referral_Fee__c = '20%';

    update opp;

    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Pending';
    property.Override_Origination_Fee__c = 10001;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;

    Commission_Total__c myCommissionTotal = new Commission_Total__c();
    myCommissionTotal.OwnerId = origU.id;
    myCommissionTotal.Quarter_Start_Date__c = quarterStartDate;
    myCommissionTotal.Quarter_End_Date__c = quarterEndDate;
    insert myCommissionTotal;

    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Wire_Date__c = quarterStartDate
    );
    insert adv;
    Test.startTest();

    Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 50000001;
    padv.Renovation_Reserve__c = 50000001;
    padv.Origination_Fee__c = 1000;

    insert padv;

    update opp;
    adv.Wire_Date__c = system.today();

    // adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    system.debug('Deal Amount' + opp.Amount);
    test.stopTest();
  }
  static testMethod void Commissiontest29() {
    //internal
    /*  Account acc = test_Helper.createAccount();
        Contact cont = test_Helper.createContact( acc );
        Opportunity opp = test_Helper.createOpportunity( acc, cont ); */

    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account a = new Account();
    a.Name = 'test';
    a.BillingCountry = 'United States';
    a.BillingState = 'California';
    a.Introductions_Source__c = 'Hotline';
    a.Introduction_Subsource__c = 'Main';
    a.Alternate_Phone__c = '5555555555';
    insert a;

    Contact c = new Contact();
    c.FirstName = 'test';
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

    Opportunity opp = new Opportunity();
    opp.Name = 'test opportunity';
    opp.CloseDate = System.today();
    opp.StageName = 'Initial Review';
    opp.Loan_Size__c = 200000001;
    opp.AccountId = a.Id;
    opp.Contact__c = c.Id;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_Source__c = 'Main';
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert opp;

    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 300000001;
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Commission_Type__c = 'Direct';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;
    opp.Amount = 30000000;
    opp.Internal_Referral__c = UserInfo.getUserId();
    opp.Internal_Referral_Fee__c = '20%';

    update opp;

    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Pending';
    property.Override_Origination_Fee__c = 10001;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;

    Commission_Total__c myCommissionTotal = new Commission_Total__c();
    myCommissionTotal.OwnerId = UserInfo.getUserId();
    myCommissionTotal.Quarter_Start_Date__c = quarterStartDateLastQ;
    myCommissionTotal.Quarter_End_Date__c = quarterEndDateLastQ;
    insert myCommissionTotal;

    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Wire_Date__c = quarterStartDateLastQ
    );
    insert adv;

    Test.startTest();

    Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 50000001;
    padv.Renovation_Reserve__c = 50000001;
    padv.Origination_Fee__c = 1000;

    insert padv;

    update opp;
    adv.Wire_Date__c = system.today();

    // adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    system.debug('Deal Amount' + opp.Amount);
    test.stopTest();
  }
  @isTest
  static void Commissiontest30() {
    // 1st term condition
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission_Total__c myCommissionTotal = new Commission_Total__c();
    myCommissionTotal.OwnerId = UserInfo.getUserId();
    myCommissionTotal.Quarter_Start_Date__c = quarterStartDateLastQ;
    myCommissionTotal.Quarter_End_Date__c = quarterEndDateLastQ;
    myCommissionTotal.Total_Term_Commission__c = 10000;

    insert myCommissionTotal;

    Commission__c myCommission = new Commission__c();
    myCommission.Commission_Amount1__c = 1230;
    myCommission.Deal__c = topp1.id;
    myCommission.Owner__c = origU.id;
    myCommission.Commission_Detail__c = commDetail.id;
    myCommission.Commission_Total__c = myCommissionTotal.id;

    myCommission.Loan_Type__c = 'Term Loan';
    insert myCommission;

    delete myCommission;
  }
  @isTest
  static void Commissiontest31() {
    // 1st term condition
    /* commissionAutomationSetting__c settings = new commissionAutomationSetting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      SkipProcessBuilder__c = true
    );
    // insert settings */
    // insert settings

    Date quarterStartDate = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDate = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER
    ]
    .EndDate;

    Date quarterStartDateLastQ = [
      SELECT StartDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .StartDate;

    Date quarterEndDateLastQ = [
      SELECT EndDate
      FROM Period
      WHERE type = 'Quarter' AND StartDate = LAST_FISCAL_QUARTER
    ]
    .EndDate;

    //Total Borrowed on term (account) under 5 million no split;Final Loan Amount under 5 million
    User origU = [SELECT Id FROM User WHERE UserName = 'originator@teada.com'];

    Account acc = test_Helper.createAccount();
    acc.Alternate_Phone__c = '7777777777';
    update acc;
    Contact cont = test_Helper.createContact(acc);
    cont.MobilePhone = '2222222222';
    cont.Phone = '9999999999';

    Opportunity topp1 = new Opportunity();
    topp1.Name = 'test';
    topp1.CloseDate = System.today();
    topp1.StageName = 'Closed Won';
    topp1.Loan_Size__c = 2000000;
    topp1.AccountId = acc.Id;
    topp1.Contact__c = cont.Id;
    topp1.OwnerId = origU.id;
    topp1.CAF_YSP__c = null;
    topp1.Type = 'Term Loan';
    topp1.CAF_Upfront_Fee__c = 2;
    topp1.Final_Loan_Amount__c = 1000000;
    topp1.Deal_Intro_Source__c = 'Hotline';
    topp1.Deal_Intro_Sub_Source__c = 'Main';
    topp1.Apex_Context__c = true;
    topp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert topp1;

    Commission_Detail__c commDetail = new Commission_Detail__c();
    commDetail.Deal__c = topp1.Id;
    commDetail.Commission_Type__c = 'Direct';
    commDetail.OwnerId = origU.Id;
    commDetail.Approval_Status__c = 'Pending';

    insert commDetail;

    Commission__c myCommission = new Commission__c();
    myCommission.Commission_Amount1__c = 1230;
    myCommission.Deal__c = topp1.id;
    myCommission.Owner__c = origU.id;
    myCommission.Commission_Detail__c = commDetail.id;

    myCommission.Loan_Type__c = 'Term Loan';
    insert myCommission;

    Commission_Total__c myCommissionTotal = new Commission_Total__c();
    myCommissionTotal.OwnerId = UserInfo.getUserId();
    myCommissionTotal.Quarter_Start_Date__c = quarterStartDateLastQ;
    myCommissionTotal.Quarter_End_Date__c = quarterEndDateLastQ;
    myCommissionTotal.Total_Term_Commission__c = 10000;
    insert myCommissionTotal;

    myCommission.Commission_Amount1__c = 123000;

    myCommission.Commission_total__c = myCommissionTotal.Id;
    update myCommission;
  }
}
