@isTest
public class Opportunity_Tests_Additional {
  @TestSetup
  static void dataSetup() {
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Swap_Rate__c S = new Swap_Rate__c();
    S.Five_Year_Swap__c = 1;
    S.Seven_Year_Swap__c = 1;
    S.Ten_Year_Swap__c = 1;
    S.Thirty_Year_Swap__c = 1;
    S.CreatedDateTime__c = DateTime.now();
    insert S;

    Opportunity opp = new Opportunity();
    opp.Name = 'TERM TEST 1';
    opp.CloseDate = System.today();
    opp.Rate_Locked__c = false;
    opp.Term_Loan_Type__c = '5 Year';
    opp.StageName = 'Initial Review';
    opp.Loan_Size__c = 2000000;
    opp.AccountId = acc.Id;
    opp.Contact__c = cont.Id;
    opp.Final_Loan_Amount__c = 100;
    opp.Apex_Context__c = true;
    Id id1 = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    opp.RecordTypeId = id1;

    Opportunity opp1 = new Opportunity();
    opp1.Name = 'TERM TEST 2';
    opp1.CloseDate = System.today();
    opp1.Rate_Locked__c = false;
    opp1.Term_Loan_Type__c = '7 Year';
    opp1.StageName = 'Initial Review';
    opp1.Loan_Size__c = 2000000;
    opp1.AccountId = acc.Id;
    opp1.Contact__c = cont.Id;
    opp1.Final_Loan_Amount__c = 100;
    opp1.Apex_Context__c = true;
    opp1.RecordTypeId = id1;

    Opportunity opp2 = new Opportunity();
    opp2.Name = 'TERM TEST 3';
    opp2.CloseDate = System.today();
    opp2.Rate_Locked__c = false;
    opp2.Term_Loan_Type__c = '10 Year';
    opp2.StageName = 'Initial Review';
    opp2.Loan_Size__c = 2000000;
    opp2.AccountId = acc.Id;
    opp2.Contact__c = cont.Id;
    opp2.Final_Loan_Amount__c = 100;
    opp2.Apex_Context__c = true;
    opp2.RecordTypeId = id1;

    Opportunity opp3 = new Opportunity();
    opp3.Name = 'TERM TEST 4';
    opp3.CloseDate = System.today();
    opp3.Rate_Locked__c = false;
    opp3.Term_Loan_Type__c = '30 Year';
    opp3.StageName = 'Initial Review';
    opp3.Loan_Size__c = 2000000;
    opp3.AccountId = acc.Id;
    opp3.Contact__c = cont.Id;
    opp3.Final_Loan_Amount__c = 100;
    opp3.Apex_Context__c = true;
    opp3.RecordTypeId = id1;

    Opportunity opp4 = new Opportunity();
    opp4.Name = 'TERM TEST 5';
    opp4.CloseDate = System.today();
    opp4.Rate_Locked__c = false;
    opp4.Term_Loan_Type__c = '5 Year';
    opp4.StageName = 'Initial Review';
    opp4.Loan_Size__c = 2000000;
    opp4.AccountId = acc.Id;
    opp4.Contact__c = cont.Id;
    opp4.Final_Loan_Amount__c = 100;
    opp4.Apex_Context__c = true;
    opp4.Floor__c = 10;
    opp4.RecordTypeId = id1;

    List<Opportunity> oppLst = new List<Opportunity>();
    oppLst.add(opp);
    oppLst.add(opp1);
    oppLst.add(opp2);
    oppLst.add(opp3);
    oppLst.add(opp4);
    insert oppLst;
  }

  public static testMethod void swapRateHandler_UnitTest() {
    Test.startTest();
    Messaging.InboundEmail email = new Messaging.InboundEmail();
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

    email.subject = 'Create Swap Rate';
    email.fromAddress = 'support@cvest.com';
    email.plainTextBody = '5Yr:.99( 7Yr:.99( 10Yr:.99( 30Yr:.99(';

    SwapRateHandler testInbound = new SwapRateHandler();
    testInbound.handleInboundEmail(email, env);

    email.subject = 'Create Swap Rate';
    email.fromAddress = 'support@cvest.com';
    email.plainTextBody = '5Yr:*.99( 7Yr:.99( 10Yr:.99( 30Yr:.99(';

    testInbound.handleInboundEmail(email, env);
    Test.stopTest();
  }

  public static testMethod void update_Swap_Rate_UnitTest() {
    Test.startTest();
    List<opportunity> o = [SELECT id FROM opportunity LIMIT 5];
    update_Swap_Rate.UpdateRate(o[0].id);
    update_Swap_Rate.UpdateRate(o[1].id);
    update_Swap_Rate.UpdateRate(o[2].id);
    update_Swap_Rate.UpdateRate(o[3].id);
    update_Swap_Rate.UpdateRate(o[4].id);

    Swap_Rate__c S = new Swap_Rate__c();
    S.Five_Year_Swap__c = 2;
    S.Seven_Year_Swap__c = 2;
    S.Ten_Year_Swap__c = 3;
    S.Thirty_Year_Swap__c = 4;
    S.CreatedDateTime__c = DateTime.now() + 1;
    insert S;
    update_Swap_Rate.UpdateRate(o[0].id);
    update_Swap_Rate.UpdateRate(o[1].id);
    update_Swap_Rate.UpdateRate(o[2].id);
    update_Swap_Rate.UpdateRate(o[3].id);
    update_Swap_Rate.UpdateRate(o[4].id);
    Test.stopTest();
  }
}