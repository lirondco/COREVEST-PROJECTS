@isTest
public with sharing class ResoluteVendorAssignmentTest {
    @TestSetup
    static void makeData(){
        EmailTemplate et = new EmailTemplate();
        et.Name = ResoluteVendorAssignment.EMAIL_TEMPLATE_NAME;
        et.DeveloperName = ResoluteVendorAssignment.EMAIL_TEMPLATE_NAME.replace(' ', '_');
        et.isActive = true;
        et.TemplateType = 'text';
        et.FolderId = UserInfo.getUserId();

        insert et;
    }
    @isTest
    public static void testCheckForRtl() {
        Account acc = Test_Helper.createAccount();
        Contact ctc = Test_Helper.createContact(acc);
        Opportunity deal = Test_Helper.createBridgeDeal(acc, ctc);
        Opportunity deal2 = Test_Helper.createBridgeDeal(acc, ctc);


        deal.Loan_Effective_Date__c = System.today();
        deal.StageName = 'Closed Won';
        deal.Warehouse_Line__c = 'Churchill';
        deal2.Loan_Effective_Date__c = System.today();
        deal2.StageName = 'Closed Won';
        deal2.Warehouse_Line__c = '2021-RTL1';
        
        Test.startTest();
        update new List<Opportunity>{deal, deal2};
        Test.stopTest();

        Map<Id, Opportunity> opps = new Map<Id, Opportunity>([SELECT Id, StageName, RecordType__c, Warehouse_Line__c, Contact__c FROM Opportunity LIMIT 2]);

        Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>{deal2.Id => opps.get(deal.Id)};
        Map<Id,Opportunity> newMap = new Map<Id,Opportunity>{deal2.Id => opps.get(deal2.Id)};

        ResoluteVendorAssignment.checkForRtl(oldMap, newMap);

        List<Deal_Contact__c> dcs = [SELECT Id FROM Deal_Contact__C WHERE Deal__c = :deal2.Id];

        System.assertEquals(true, dcs.size() > 0, 'A deal contact should\'ve been created.');
    }


}
