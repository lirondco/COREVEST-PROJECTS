@isTest
public with sharing class Test_Helper {
  public static List<EmailTemplate> createEmailTemplates(
    List<String> devNames
  ) {
    List<EmailTemplate> eList = new List<EmailTemplate>();
    for (String devName : devNames) {
      eList.add(
        new EmailTemplate(
          DeveloperName = devName,
          Body = '',
          TemplateType = 'Text',
          FolderId = UserInfo.getUserId(),
          Name = devName
        )
      );
    }
    insert eList;
    return eList;
  }

  // public static Folder createFolder(){
  //  Folder f = new Folder(
  //      AccessType = 'Public'
  //      , DeveloperName = 'Test'
  //      , Type = 'Email template'
  //  );
  //  insert f;
  //  return f;
  // }

  public static void setupProduct2() {
    Product2 prod = new Product2(
      Name = 'Single Rental Loan',
      ProductCode = 'Single_Rental_Loan'
    );
    insert prod;
    Product2 prod1 = new Product2(Name = 'SAB Loan', ProductCode = 'SAB_Loan');
    insert prod1;
    Product2 prod3 = new Product2(
      Name = 'Term Loan',
      ProductCode = 'Term_Loan'
    );
    insert prod3;
    Product2 prod2 = new Product2(
      Name = 'Bridge Loan',
      ProductCode = 'Bridge_Loan'
    );
    insert prod2;

    Id pricebookId = test.getStandardPricebookId();

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = prod.Id,
      UnitPrice = 0,
      IsActive = true
    );
    insert pbe;
    PricebookEntry pbe1 = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = prod1.Id,
      UnitPrice = 0,
      isActive = true
    );
    insert pbe1;
    PricebookEntry pbe2 = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = prod2.Id,
      UnitPrice = 0,
      isActive = true
    );
    insert pbe2;
    PricebookEntry pbe3 = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = prod3.Id,
      UnitPrice = 0,
      isActive = true
    );
    insert pbe3;
  }

  private static String nameRandomiser() {
    return String.valueOf(Math.random() * 1000000);
  }

  public static Account createAccount() {
    Account a = new Account();
    a.Name = 'Test Helper Account' + nameRandomiser();
    a.BillingCountry = 'United States';
    a.BillingState = 'California';
    a.Introductions_Source__c = 'Hotline';
    a.Introduction_Subsource__c = 'Main';
    a.Alternate_Phone__c = '5555555555';
    insert a;
    return a;
  }

  public static Account createBorrowerAccount() {
    Account borAcc = new Account();
    borAcc.Name = 'Borrower Helper Account';
    borAcc.BillingCountry = 'United States';
    borAcc.BillingState = 'California';
    borAcc.Introductions_Source__c = 'Event';
    borAcc.Introduction_Subsource__c = 'AAPL';
    borAcc.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Account' AND DeveloperName = 'Borrower'
    ]
    .Id;
    insert borAcc;
    borAcc.Alternate_Phone__c = '2222222222';
    update borAcc;
    return borAcc;
  }

  public static Account createBrokerAccount() {
    Account brokerAcc = new Account();
    brokerAcc.Name = 'Broker Helper Account';
    brokerAcc.BillingCountry = 'United States';
    brokerAcc.BillingState = 'California';
    brokerAcc.Introductions_Source__c = 'Event';
    brokerAcc.Introduction_Subsource__c = 'AAPL';
    brokerAcc.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Account' AND DeveloperName = 'Broker'
    ]
    .Id;
    insert brokerAcc;
    brokerAcc.Alternate_Phone__c = '2222222222';
    update brokerAcc;
    return brokerAcc;
  }

  public static Contact createContact(Account a) {
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
    return c;
  }

  public static Contact createBorContact(Account borAcc) {
    Contact borCon = new Contact();
    borCon.FirstName = 'test';
    borCon.LastName = 'test';
    borCon.MailingCountry = 'United States';
    borCon.MailingState = 'California';
    borCon.AccountId = borAcc.Id;
    borCon.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Contact' AND DeveloperName = 'Borrower'
    ]
    .Id;
    insert borCon;
    borCon.MobilePhone = '2222222222';
    borCon.Phone = '7777777777';
    update borCon;
    return borCon;
  }

  public static Contact createBrokerContact(Account brokerAcc) {
    Contact brokerCon = new Contact();
    brokerCon.FirstName = 'test';
    brokerCon.LastName = 'test';
    brokerCon.MailingCountry = 'United States';
    brokerCon.MailingState = 'California';
    brokerCon.AccountId = brokerAcc.Id;
    brokerCon.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Contact' AND DeveloperName = 'Broker'
    ]
    .Id;
    insert brokerCon;
    brokerCon.MobilePhone = '2222222222';
    brokerCon.Phone = '7777777777';
    update brokerCon;
    return brokerCon;
  }

  public static Opportunity createOpportunity(Account a, Contact c) {
    Opportunity o = new Opportunity();
    o.Name = 'test';
    o.CloseDate = System.today();
    o.StageName = 'Initial Review';
    o.Loan_Size__c = 2000000;
    o.AccountId = a.Id;
    o.Contact__c = c.Id;
    o.Deal_Intro_Source__c = 'Hotline';
    o.Deal_Intro_Sub_Source__c = 'Main';
    o.Apex_Context__c = true;
    o.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert o;
    o.Apex_Context__c = true;
    return o;
  }

  public static Opportunity createTermDeal(Account borAcc, Contact c) {
    Opportunity termdeal = new Opportunity();
    termdeal.Name = 'test';
    termdeal.CloseDate = System.today();
    termdeal.StageName = 'Initial Review';
    termdeal.Loan_Size__c = 2000000;
    termdeal.AccountId = borAcc.Id;
    termdeal.Contact__c = c.Id;
    termdeal.Deal_Intro_Source__c = 'Hotline';
    termdeal.Deal_Intro_Sub_Source__c = 'Main';
    termdeal.Apex_Context__c = true;
    termdeal.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    termdeal.Recourse__c = 'Recourse';
    termdeal.Term_Loan_Type__c = '5 Year';
    termdeal.IO_Term__c = '60 months';
    insert termdeal;
    return termdeal;
  }

  public static Opportunity createTermDeal2(Account borAcc, Contact c) {
    Opportunity termdeal2 = new Opportunity();
    termdeal2.Name = 'test';
    termdeal2.CloseDate = System.today();
    termdeal2.StageName = 'Initial Review';
    termdeal2.Loan_Size__c = 60000000;
    termdeal2.AccountId = borAcc.Id;
    termdeal2.Contact__c = c.Id;
    termdeal2.Deal_Intro_Source__c = 'Hotline';
    termdeal2.Deal_Intro_Sub_Source__c = 'Main';
    termdeal2.Apex_Context__c = true;
    termdeal2.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    termdeal2.Recourse__c = 'Non-Recourse';
    termdeal2.Term_Loan_Type__c = '10 Year';
    insert termdeal2;
    termdeal2.Apex_Context__c = true;
    return termdeal2;
  }

  public static Opportunity createTermDeal3(Account borAcc, Contact c) {
    Opportunity termdeal3 = new Opportunity();
    termdeal3.Name = 'test';
    termdeal3.CloseDate = System.today();
    termdeal3.StageName = 'Initial Review';
    termdeal3.Loan_Size__c = 700000;
    termdeal3.AccountId = borAcc.Id;
    termdeal3.Contact__c = c.Id;
    termdeal3.Deal_Intro_Source__c = 'Hotline';
    termdeal3.Deal_Intro_Sub_Source__c = 'Main';
    termdeal3.Apex_Context__c = true;
    termdeal3.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    termdeal3.Recourse__c = 'Non-Recourse';
    termdeal3.Term_Loan_Type__c = '7 Year';
    termdeal3.IO_Term__c = '0 months';
    insert termdeal3;
    termdeal3.Apex_Context__c = true;
    return termdeal3;
  }

  public static Opportunity createBridgeDeal(Account a, Contact c) {
    Opportunity bridgedeal = new Opportunity();
    bridgedeal.Name = 'test';
    bridgedeal.CloseDate = System.today();
    bridgedeal.StageName = 'Initial Review';
    bridgedeal.Loan_Size__c = 2000000;
    bridgedeal.AccountId = a.Id;
    bridgedeal.Contact__c = c.Id;
    bridgedeal.Deal_Intro_Source__c = 'Hotline';
    bridgedeal.Deal_Intro_Sub_Source__c = 'Main';
    bridgedeal.Apex_Context__c = true;
    bridgedeal.Commission_Type__c = 'Internal';
    bridgedeal.LOC_Loan_Type__c = 'Credit Line';
    bridgedeal.Product_Sub_Type__c = 'No Renovation';
    bridgedeal.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    bridgedeal.Exit_Fee__c = 0;
    bridgedeal.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    insert bridgedeal;
    return bridgedeal;
  }

  public static Opportunity createLOCDeal(Account a, Contact c) {
    Opportunity locdeal = new Opportunity();
    locdeal.Name = 'test';
    locdeal.CloseDate = System.today();
    locdeal.StageName = 'Initial Review';
    locdeal.Loan_Size__c = 10000000;
    locdeal.AccountId = a.Id;
    locdeal.Contact__c = c.Id;
    locdeal.Deal_Intro_Source__c = 'Hotline';
    locdeal.Deal_Intro_Sub_Source__c = 'Main';
    locdeal.Commission_Type__c = 'Internal';
    locdeal.LOC_Loan_Type__c = 'Credit Line';
    locdeal.Product_Sub_Type__c = 'Renovation';
    locdeal.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    locdeal.Exit_Fee__c = 0;
    locdeal.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    insert locdeal;
    return locdeal;
  }

  public static Opportunity createCREDeal(Account a, Contact c) {
    Opportunity credeal = new Opportunity();
    credeal.Name = 'test';
    credeal.CloseDate = System.today() + 10;
    credeal.StageName = 'Initial Review';
    credeal.Loan_Size__c = 2000000;
    credeal.AccountId = a.Id;
    credeal.Contact__c = c.Id;
    credeal.Deal_Intro_Source__c = 'Hotline';
    credeal.Deal_Intro_Sub_Source__c = 'Main';
    credeal.Apex_Context__c = true;
    credeal.Commission_Type__c = 'Internal';
    credeal.LOC_Loan_Type__c = 'Multifamily/CRE';
    credeal.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    insert credeal;
    return credeal;
  }

  public static Opportunity createBTRDeal(Account a, Contact c) {
    Opportunity btrdeal = new Opportunity();
    btrdeal.Name = 'test';
    btrdeal.CloseDate = System.today() + 10;
    btrdeal.StageName = 'Initial Review';
    btrdeal.Loan_Size__c = 2000000;
    btrdeal.AccountId = a.Id;
    btrdeal.Contact__c = c.Id;
    btrdeal.Deal_Intro_Source__c = 'Hotline';
    btrdeal.Deal_Intro_Sub_Source__c = 'Main';
    btrdeal.Apex_Context__c = true;
    btrdeal.Commission_Type__c = 'Internal';
    btrdeal.LOC_Loan_Type__c = 'Build to Rent';
    btrdeal.Product_Sub_Type__c = 'Build to Rent';
    btrdeal.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    insert btrdeal;
    return btrdeal;
  }

  public static Opportunity createSABDeal(Account a, Contact c) {
    Opportunity sabdeal = new Opportunity();
    sabdeal.Name = 'test';
    sabdeal.CloseDate = System.today();
    sabdeal.StageName = 'Initial Review';
    sabdeal.Loan_Size__c = 2000000;
    sabdeal.AccountId = a.Id;
    sabdeal.Contact__c = c.Id;
    sabdeal.Deal_Intro_Source__c = 'Hotline';
    sabdeal.Deal_Intro_Sub_Source__c = 'Main';
    sabdeal.Apex_Context__c = true;
    sabdeal.LOC_Loan_Type__c = 'Single Asset (1-4 Unit)';
    // sabdeal.RecordTypeId = '0120a0000019k5RAAQ';
    insert sabdeal;
    sabdeal.LOC_Loan_Type__c = 'Credit Line';
    update sabdeal;
    sabdeal.LOC_Loan_Type__c = 'Single Asset (5-10 Unit)';
    update sabdeal;
    return sabdeal;
  }

  public static List<Property__c> createProperties(Opportunity o) {
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
          Status__c = 'Active'
        )
      );
    }

    insert properties;
    return properties;
  }

  public static Appraisal__c createAppraisal(Opportunity o, Property__c p) {
    Appraisal__c app = new Appraisal__c(Deal__c = o.Id, Property__c = p.Id);
    insert app;
    return app;
  }

  public static Securitization__c createSecuritization() {
    Securitization__c sec = new Securitization__c();
    sec.Name = 'Test';
    insert sec;
    return sec;
  }

  public static Funding_Vehicle__c createFundingVehicle(
    Boolean isSecuritization,
    Securitization__c sec
  ) {
    Funding_Vehicle__c fv = new Funding_Vehicle__c();
    fv.Name = 'Test';
    fv.Funding_Vehicle_Type__c = isSecuritization
      ? 'Securitization'
      : 'Warehouse Line';
    fv.Securitization__c = isSecuritization ? sec.Id : null;
    String devName = isSecuritization ? 'Securitization' : 'Warehouse_Line';
    fv.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Funding_Vehicle__c' AND DeveloperName = :devName
    ]
    .Id;
    insert fv;
    return fv;
  }

  public static List<Integration_Mapping__c> createIntegrationMappings() {
    List<Integration_Mapping__c> ims = new List<Integration_Mapping__c>{
      new Integration_Mapping__c(
        Salesforce_Object__c = 'Account',
        Salesforce_Field__c = 'Id',
        Integration_Object__c = 'Account',
        Integration_Field__c = 'Id',
        Active__c = true,
        Required__c = true,
        Key__c = 'Account'
      ),
      new Integration_Mapping__c(
        Salesforce_Object__c = 'Contact',
        Salesforce_Field__c = 'Id',
        Integration_Object__c = 'Contact',
        Integration_Field__c = 'Id',
        Active__c = true,
        Required__c = true,
        Key__c = 'Contact'
      ),
      new Integration_Mapping__c(
        Salesforce_Object__c = 'Opportunity',
        Salesforce_Field__c = 'Id',
        Integration_Object__c = 'Opportunity',
        Integration_Field__c = 'Id',
        Active__c = true,
        Required__c = true,
        Key__c = 'Opportunity'
      ),
      new Integration_Mapping__c(
        Salesforce_Object__c = 'Opportunity',
        Salesforce_Field__c = 'AccountId',
        Integration_Object__c = 'Opportunity',
        Integration_Field__c = 'AccountId',
        Active__c = true,
        Required__c = true,
        Key__c = ''
      ),
      new Integration_Mapping__c(
        Salesforce_Object__c = 'Opportunity',
        Salesforce_Field__c = 'Loan_Size__c',
        Integration_Object__c = 'Opportunity',
        Integration_Field__c = 'LoanSize',
        Active__c = true,
        Required__c = true,
        Key__c = ''
      ),
      new Integration_Mapping__c(
        Salesforce_Object__c = 'Opportunity',
        Salesforce_Field__c = 'CloseDate',
        Integration_Object__c = 'Opportunity',
        Integration_Field__c = 'CloseDate',
        Active__c = true,
        Required__c = true,
        Key__c = ''
      ),
      new Integration_Mapping__c(
        Salesforce_Object__c = 'Opportunity',
        Salesforce_Field__c = 'IsPrivate',
        Integration_Object__c = 'Opportunity',
        Integration_Field__c = 'IsPrivate',
        Active__c = true,
        Required__c = true,
        Key__c = ''
      ),
      new Integration_Mapping__c(
        Salesforce_Object__c = 'TermLoan',
        Salesforce_Field__c = 'Id',
        Integration_Object__c = 'TermLoan',
        Integration_Field__c = 'Id',
        Active__c = true,
        Required__c = true,
        Key__c = 'TermLoan'
      ),
      new Integration_Mapping__c(
        Salesforce_Object__c = 'TermLoan',
        Salesforce_Field__c = 'AccountId',
        Integration_Object__c = 'TermLoan',
        Integration_Field__c = 'AccountId',
        Active__c = true,
        Required__c = true,
        Key__c = ''
      ),
      new Integration_Mapping__c(
        Salesforce_Object__c = 'TermLoan',
        Salesforce_Field__c = 'Loan_Size__c',
        Integration_Object__c = 'TermLoan',
        Integration_Field__c = 'LoanSize',
        Active__c = true,
        Required__c = true,
        Key__c = ''
      ),
      new Integration_Mapping__c(
        Salesforce_Object__c = 'TermLoan',
        Salesforce_Field__c = 'CloseDate',
        Integration_Object__c = 'TermLoan',
        Integration_Field__c = 'CloseDate',
        Active__c = true,
        Required__c = true,
        Key__c = ''
      ),
      new Integration_Mapping__c(
        Salesforce_Object__c = 'TermLoan',
        Salesforce_Field__c = 'IsPrivate',
        Integration_Object__c = 'TermLoan',
        Integration_Field__c = 'IsPrivate',
        Active__c = true,
        Required__c = true,
        Key__c = ''
      ),
      new Integration_Mapping__c(
        Salesforce_Object__c = 'TermLoan',
        Salesforce_Field__c = 'Pres_Deal_Id__c',
        Integration_Object__c = 'TermLoan',
        Integration_Field__c = 'PresId',
        Active__c = true,
        Required__c = true,
        Key__c = ''
      )
    };

    insert ims;
    return ims;
  }

  public static List<PRES_Settings__c> createCustomSettings() {
    List<PRES_Settings__c> settings = new List<PRES_Settings__c>{
      new PRES_Settings__c(
        Name = 'LOC',
        Username__c = 'test',
        Password__c = 'test',
        URL__c = 'test',
        Logs_Enabled__c = true
      ),
      new PRES_Settings__c(
        Name = 'TERM',
        Username__c = 'test',
        Password__c = 'test',
        URL__c = 'test',
        Logs_Enabled__c = true
      )
    };

    insert settings;
    return settings;
  }

  public static User createBridgeOperationsUser() {
    User u = new User(
      Alias = 'clos',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Bridge Operations']
      .Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'closer2@teada22.com'
    );
    insert u;
    return u;
  }
}