@isTest
private class SABAdvanceMemoExtensionTest {
  static testMethod void testMethod1() {
    Account acc = Test_Helper.createAccount();
    Contact cont = Test_Helper.createContact(acc);
    Opportunity opp = Test_Helper.createBridgeDeal(acc, cont);
    List<Property__c> properties = Test_Helper.createProperties(opp);

    Loan_Fee__c Loan_Fee = new Loan_Fee__c(
      Deal__c = opp.Id,
      Fee_Amount__c = 1000,
      Reference__c = '121212',
      Vendor__c = acc.Id
    );

    Advance__c adv = new Advance__c(Name = 'Tesst', Deal__c = opp.Id);
    insert adv;

    Property_Advance__c propAdv = new Property_Advance__c(
      Name = 'test',
      Advance__c = adv.Id,
      Property__C = properties[0].Id
    );
    insert propAdv;

    Test.startTest();
    SABAdvanceMemoExtension obj = new SABAdvanceMemoExtension();
    obj.filtersJSON =
      '{"recordId":"' +
      adv.Id +
      '","loantype":"1211","liquidcashreserves":"111","corevestapprovalmanager":"111","otheradjustments":"111","priorcvloans":"1111","everdeliquent":"11"}';
    obj.getData();
    SABAdvanceMemoExtension.getUrlAndInstance();
    Test.stopTest();
  }

  static testMethod void testMethodSuccess() {
    Account acc = Test_Helper.createAccount();
    Contact cont = Test_Helper.createContact(acc);
    Opportunity opp = Test_Helper.createBridgeDeal(acc, cont);
    opp.Active_States__c = 'California;Nevada';
    update opp;

    insert new deal_contact__c(
      Deal__c = opp.Id,
      Contact__c = cont.Id,
	  Deal_Contact_Type__c = 'Individual',
      Entity_Type__c = 'Sponsor'
    );
    insert new deal_contact__c(
      Deal__c = opp.Id,
      Contact__c = cont.Id,
	  Deal_Contact_Type__c = 'Individual',
      Entity_Type__c = 'Guarantor'
    );
    List<Property__c> properties = Test_Helper.createProperties(opp);
    Loan_Fee__c Loan_Fee = new Loan_Fee__c(
      Deal__c = opp.Id,
      Fee_Amount__c = 1000,
      Reference__c = '121212',
      vendor__c = acc.Id
    );

    Advance__c adv = new Advance__c(Name = 'Test', Deal__c = opp.Id);
    insert adv;
    Test.startTest();
    Property_Advance__c propAdv = new Property_Advance__c(
      Name = 'test',
      Advance__c = adv.Id,
      Property__c = properties[0].Id
    );
    insert propAdv;

    SABAdvanceMemoExtension obj = new SABAdvanceMemoExtension();
    obj.filtersJSON =
      '{"recordId":"' +
      adv.Id +
      '","loantype":"1211","liquidcashreserves":"111","corevestapprovalmanager":"111","otheradjustments":"111","priorcvloans":"1111","everdeliquent":"11"}';
    obj.getData();
    SABAdvanceMemoExtension.getUrlAndInstance();
    Test.stopTest();
  }

  static testMethod void testMethodFail() {
    Test.startTest();
    SABAdvanceMemoExtension obj = new SABAdvanceMemoExtension();
    obj.filtersJSON = '{"recordId":"1234","loantype":"1211","liquidcashreserves":"111","corevestapprovalmanager":"111","otheradjustments":"111","priorcvloans":"1111","everdeliquent":"11"}';
    obj.getData();

    SABAdvanceMemoExtension.WrapperData wd = new SABAdvanceMemoExtension.WrapperData();

    wd.corevestapprovalmanager = '1000';
    wd.priorcvloans = '1000';
    wd.everdeliquent = '1000';
    wd.loantype = '1000';

    Test.stopTest();
  }
}