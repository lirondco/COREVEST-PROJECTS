@istest
public class Opportunity_Tests_Additional2 {
  @testsetup
  static void datasetup() {
    List<Account> al = new List<Account>();
    Account a0 = new Account();
    a0.Name = 'Berkadia Commercial Mortgage';
    a0.BillingCountry = 'United States';
    a0.BillingState = 'California';
    a0.Introductions_Source__c = 'Hotline';
    a0.Introduction_Subsource__c = 'Main';
    a0.Alternate_Phone__c = '5555555555';
    al.add(a0);

    Account a1 = new Account();
    a1.Name = 'Statebridge Company, LLC';
    a1.BillingCountry = 'United States';
    a1.BillingState = 'California';
    a1.Introductions_Source__c = 'Hotline';
    a1.Introduction_Subsource__c = 'Main';
    a1.Alternate_Phone__c = '5555555555';
    al.add(a1);

    Account a2 = new Account();
    a2.Name = 'Churchill Real Estate';
    a2.BillingCountry = 'United States';
    a2.BillingState = 'California';
    a2.Introductions_Source__c = 'Hotline';
    a2.Introduction_Subsource__c = 'Main';
    a2.Alternate_Phone__c = '5555555555';
    al.add(a2);

    Account a3 = new Account();
    a3.Name = 'FCI Lender Services';
    a3.BillingCountry = 'United States';
    a3.BillingState = 'California';
    a3.Introductions_Source__c = 'Hotline';
    a3.Introduction_Subsource__c = 'Main';
    a3.Alternate_Phone__c = '5555555555';
    al.add(a3);

    insert al;

    List<Contact> cl = new List<Contact>();
    Contact c0 = new Contact();
    c0.FirstName = 'test';
    c0.LastName = 'test';
    c0.MailingCountry = 'United States';
    c0.MailingState = 'California';
    c0.AccountId = al[0].Id;
    c0.MobilePhone = '5555555555';
    c0.Phone = '7777777777';
    c0.Experian__c = 700;
    c0.TransUnion__c = 710;
    c0.Equifax__c = 700;
    c0.Years_of_Experience__c = 10;
    c0.Rental_Units_Owned__c = '5';
    c0.Sponsor_Tier__c = 'Tier 1';
    c0.Experience__c = 5;
    cl.add(c0);

    Contact c1 = new Contact();
    c1.FirstName = 'test';
    c1.LastName = 'test';
    c1.MailingCountry = 'United States';
    c1.MailingState = 'California';
    c1.AccountId = al[1].Id;
    c1.MobilePhone = '5555555555';
    c1.Phone = '7777777777';
    c1.Experian__c = 700;
    c1.TransUnion__c = 710;
    c1.Equifax__c = 700;
    c1.Years_of_Experience__c = 10;
    c1.Rental_Units_Owned__c = '5';
    c1.Sponsor_Tier__c = 'Tier 1';
    c1.Experience__c = 5;
    cl.add(c1);

    Contact c2 = new Contact();
    c2.FirstName = 'test';
    c2.LastName = 'test';
    c2.MailingCountry = 'United States';
    c2.MailingState = 'California';
    c2.AccountId = al[2].Id;
    c2.MobilePhone = '5555555555';
    c2.Phone = '7777777777';
    c2.Experian__c = 700;
    c2.TransUnion__c = 710;
    c2.Equifax__c = 700;
    c2.Years_of_Experience__c = 10;
    c2.Rental_Units_Owned__c = '5';
    c2.Sponsor_Tier__c = 'Tier 1';
    c2.Experience__c = 5;
    cl.add(c2);

    Contact c3 = new Contact();
    c3.FirstName = 'test';
    c3.LastName = 'test';
    c3.MailingCountry = 'United States';
    c3.MailingState = 'California';
    c3.AccountId = al[3].Id;
    c3.MobilePhone = '5555555555';
    c3.Phone = '7777777777';
    c3.Experian__c = 700;
    c3.TransUnion__c = 710;
    c3.Equifax__c = 700;
    c3.Years_of_Experience__c = 10;
    c3.Rental_Units_Owned__c = '5';
    c3.Sponsor_Tier__c = 'Tier 1';
    c3.Experience__c = 5;
    cl.add(c3);
    insert cl;

    System.debug(
      '1.RS 999 Number of Queries used in this apex code so far: ' +
      Limits.getQueries()
    );

    Opportunity opp0 = new Opportunity();
    opp0.Name = 'TERM TEST 0';
    opp0.CloseDate = System.today();
    opp0.Rate_Locked__c = false;
    opp0.Term_Loan_Type__c = '5 Year';
    opp0.StageName = 'Initial Review';
    opp0.Loan_Size__c = 2000000;
    opp0.AccountId = al[0].Id;
    opp0.Contact__c = cl[0].Id;
    opp0.Final_Loan_Amount__c = 100;
    opp0.Final_Swap__c = 1.7;
    opp0.Final_Spread__c = 1.1;
    opp0.Apex_Context__c = true;
    opp0.Loan_Effective_Date__c = date.today();
    Id id1 = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    opp0.RecordTypeId = id1;

    ///////////////////////////////////////////////////////

    Opportunity opp1 = new Opportunity();
    opp1.Name = 'TERM TEST 1';
    opp1.CloseDate = System.today();
    opp1.Rate_Locked__c = false;
    opp1.LOC_Term__c = '24 Months';
    opp1.StageName = 'Initial Review';
    opp1.Loan_Size__c = 2000000;
    opp1.AccountId = al[1].Id;
    opp1.Contact__c = cl[1].Id;
    opp1.Final_Loan_Amount__c = 100;
    opp1.Final_Swap__c = 1.7;
    opp1.Final_Spread__c = 1.1;
    opp1.Loan_Effective_Date__c = date.today();
    opp1.Apex_Context__c = true;
    Id id2 = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp1.RecordTypeId = id2;

    //////////////////////////////////////////////////////////////

    Opportunity opp2 = new Opportunity();
    opp2.Name = 'TERM TEST 2';
    opp2.CloseDate = System.today();
    opp2.Rate_Locked__c = false;
    opp2.Approved_Third_Party_Originators__c = al[2].id;
    opp2.Term_Loan_Type__c = '30 Year';
    opp2.StageName = 'Initial Review';
    opp2.Loan_Size__c = 2000000;
    opp2.AccountId = al[3].Id;
    opp2.Contact__c = cl[3].Id;
    opp2.Final_Loan_Amount__c = 100;
    opp2.Final_Swap__c = 1.7;
    opp2.Final_Spread__c = 1.1;
    opp2.Loan_Effective_Date__c = date.today();
    opp2.Apex_Context__c = true;
    Id id3 = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Opportunity'
        AND DeveloperName = 'Investor_DSCR_Active'
    ]
    .Id;
    opp2.RecordTypeId = id3;

    ///////////////////////////////////////////////
    Opportunity opp3 = new Opportunity();
    opp3.Name = 'TERM TEST 3';
    opp3.CloseDate = System.today();
    opp3.Rate_Locked__c = false;
    opp3.LOC_Term__c = '24 Months';
    opp3.StageName = 'Initial Review';
    opp3.Loan_Size__c = 2000000;
    opp3.AccountId = al[3].Id;
    opp3.Contact__c = cl[3].Id;
    opp3.Final_Loan_Amount__c = 100;
    opp3.Final_Swap__c = 1.7;
    opp3.Final_Spread__c = 1.1;
    opp3.Loan_Effective_Date__c = date.today();
    opp3.Apex_Context__c = true;
    Id id4 = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Opportunity'
        AND DeveloperName = 'Acquired_Bridge_Loan'
    ]
    .Id;
    opp3.RecordTypeId = id4;

    Opportunity opp4 = new Opportunity();
    opp4.Name = 'TERM TEST 5';
    opp4.CloseDate = System.today();
    opp2.Approved_Third_Party_Originators__c = al[1].id;
    opp4.Rate_Locked__c = false;
    opp4.Term_Loan_Type__c = '30 Year';
    opp4.StageName = 'Initial Review';
    opp4.Loan_Size__c = 2000000;
    opp4.AccountId = al[3].Id;
    opp4.Contact__c = cl[3].Id;
    opp4.Final_Loan_Amount__c = 100;
    opp4.Final_Swap__c = 1.7;
    opp4.Final_Spread__c = 1.1;
    opp4.Apex_Context__c = true;
    opp4.Floor__c = 10;
    opp4.Loan_Effective_Date__c = date.today();
    opp4.RecordTypeId = id3;

    ///////////////////////////////////////////////

    List<Opportunity> oppLst = new List<Opportunity>();
    oppLst.add(opp0);
    oppLst.add(opp1);
    oppLst.add(opp2);
    oppLst.add(opp3);
    oppLst.add(opp4);
    insert oppLst;

    System.debug(
      '2.RS 999 Number of Queries used in this apex code so far: ' +
      Limits.getQueries()
    );
  }

  public static testMethod void UnitTest1() {
    Test.startTest();
    List<opportunity> o = [
      SELECT id, name, OwnerId, Underwriter__c, Record_Type_Name__c, Contact__c
      FROM opportunity
      LIMIT 5
    ];

    List<Loan_Version__c> loanVersionList = new List<Loan_Version__c>();
    Loan_Version__c loanVersion = new Loan_Version__c();
    loanVersion.Deal__c = o[0].id;
    loanVersion.Finalized__c = True;
    loanVersion.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Loan_Version__c' AND DeveloperName = 'Loan_Agreement'].Id;      
    loanVersionList.add(loanVersion);
      
    Loan_Version__c loanVersion1 = new Loan_Version__c();    
    loanVersion1.Deal__c = o[0].id;
    loanVersion1.Finalized__c = True;    
    loanVersion1.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Loan_Version__c' AND DeveloperName = 'Schedule_of_Lender_Cost'].Id;      
    loanVersionList.add(loanVersion1);      

    Loan_Version__c loanVersion2 = new Loan_Version__c();
    loanVersion2.Deal__c = o[1].id;
    loanVersion2.Finalized__c = True;
    loanVersion2.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Loan_Version__c' AND DeveloperName = 'Loan_Agreement'].Id;      
    loanVersionList.add(loanVersion2);
      
    Loan_Version__c loanVersion3 = new Loan_Version__c();    
    loanVersion3.Deal__c = o[1].id;
    loanVersion3.Finalized__c = True;    
    loanVersion3.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Loan_Version__c' AND DeveloperName = 'Schedule_of_Lender_Cost'].Id;      
    loanVersionList.add(loanVersion3);     

    Loan_Version__c loanVersion4 = new Loan_Version__c();
    loanVersion4.Deal__c = o[2].id;
    loanVersion4.Finalized__c = True;
    loanVersion4.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Loan_Version__c' AND DeveloperName = 'Loan_Agreement'].Id;      
    loanVersionList.add(loanVersion4);
      
    Loan_Version__c loanVersion5 = new Loan_Version__c();    
    loanVersion5.Deal__c = o[2].id;
    loanVersion5.Finalized__c = True;    
    loanVersion5.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Loan_Version__c' AND DeveloperName = 'Schedule_of_Lender_Cost'].Id;      
    loanVersionList.add(loanVersion5);   

    Loan_Version__c loanVersion6 = new Loan_Version__c();
    loanVersion6.Deal__c = o[3].id;
    loanVersion6.Finalized__c = True;
    loanVersion6.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Loan_Version__c' AND DeveloperName = 'Loan_Agreement'].Id;      
    loanVersionList.add(loanVersion6);
      
    Loan_Version__c loanVersion7 = new Loan_Version__c();    
    loanVersion7.Deal__c = o[3].id;
    loanVersion7.Finalized__c = True;    
    loanVersion7.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Loan_Version__c' AND DeveloperName = 'Schedule_of_Lender_Cost'].Id;      
    loanVersionList.add(loanVersion7);   

    Loan_Version__c loanVersion8 = new Loan_Version__c();
    loanVersion8.Deal__c = o[4].id;
    loanVersion8.Finalized__c = True;
    loanVersion8.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Loan_Version__c' AND DeveloperName = 'Loan_Agreement'].Id;      
    loanVersionList.add(loanVersion8);
      
    Loan_Version__c loanVersion9 = new Loan_Version__c();    
    loanVersion9.Deal__c = o[4].id;
    loanVersion9.Finalized__c = True;    
    loanVersion9.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Loan_Version__c' AND DeveloperName = 'Schedule_of_Lender_Cost'].Id;      
    loanVersionList.add(loanVersion9);       
      
	Insert loanVersionList;
     
    ///////////////////////////////////////////
    /*List<Account> berkadiaAccs = [
      SELECT Id
      FROM Account
      WHERE Name = 'Berkadia Commercial Mortgage'
      LIMIT 1
    ];

    List<Account> statebridgeAccs = [
      SELECT Id
      FROM Account
      WHERE Name = 'Statebridge Company, LLC'
      LIMIT 1
    ];

    List<Account> fciAccs = [
      SELECT Id
      FROM Account
      WHERE Name = 'FCI Lender Services'
      LIMIT 1
    ];

      Id berkadiaAccId = berkadiaAccs[0].Id;
      Id statebridgeAccId = statebridgeAccs[0].Id;
      Id fciAccId = fciAccs[0].Id;      */
    ///////////////////////////////////////

    System.debug(
      '3.RS 999 Number of Queries used in this apex code so far: ' +
      Limits.getQueries()
    );
    Map<Id, Opportunity> closedWonIds = new Map<Id, Opportunity>();
    closedWonIds.put(o[0].Id, o[0]);
    closedWonIds.put(o[1].Id, o[1]);
    closedWonIds.put(o[2].Id, o[2]);
    closedWonIds.put(o[3].Id, o[3]);

    /*  List<Opportunity> bridgeOppsToUpdate = [
        SELECT Id
        FROM Opportunity
        WHERE
          Id IN :closedWonIds.keySet()
          AND RecordType__c = 'Bridge'
          AND Id NOT IN (
            SELECT Deal__c
            FROM Deal_Contact__c
            WHERE Account__c = :statebridgeAccId
          )
      ];        */

    //System.debug('bridgeOppsToUpdate = '+bridgeOppsToUpdate)     ;

    o[0].StageName = 'Closed Won';
    o[0].Final_Loan_Amount__c = 100;
    o[0].Final_Swap__c = 1;
    o[0].Final_Spread__c = 	1;
     
    update o[0];
    o[1].StageName = 'Closed Won';
    o[1].Final_Loan_Amount__c = 100;
    o[1].Final_Swap__c = 1;
    o[1].Final_Spread__c = 	1;    
    update o[1];
    o[2].StageName = 'Closed Won';
    o[2].Final_Loan_Amount__c = 100;
    o[2].Final_Swap__c = 1;
    o[2].Final_Spread__c = 	1;       
    update o[2];
    o[3].Final_Loan_Amount__c = 100;
    o[3].Final_Swap__c = 1;
    o[3].Final_Spread__c = 	1;       
    o[3].StageName = 'Closed Won';
    update o[3];
   /* o[4].StageName = 'Closed Won';
    o[4].Final_Loan_Amount__c = 100;
    o[5].Final_Swap__c = 1;
    o[4].Final_Spread__c = 	1;       
    update o[4];*/

    opportunity_Helper.attachVendors(closedWonIds);
    // opportunity_Helper.createApprovalHistory(closedWonIds);
    // opportunity_Helper.emailReversedIcApprovalAlert(closedWonIds);
    // raj attachDealContactIFClosedWON
    // raj getMapFromOppIdToDealDocs

    Test.stopTest();
  }
}