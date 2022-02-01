@isTest
public with sharing class DuplicateDealsEmailControllerTest {
    @isTest
    public static void testMethod1() {
        Account acc = test_Helper.createAccount();
        Contact cont = test_Helper.createContact(acc);
        Opportunity opp = test_Helper.createOpportunity(acc, cont);
        opp.RecordTypeId = [
          SELECT Id
          FROM RecordType
          WHERE DeveloperName = 'Term_Loan' AND sobjecttype = 'Opportunity'
        ]
        .Id;
    
        Account acc1 = acc.clone(false, false, false, false);
        acc1.Name = 'Steve';
        insert acc1;
        //Account acc1 = test_Helper.createAccount();
        Contact cont1 = test_Helper.createContact(acc1);
        Opportunity opp1 = test_Helper.createOpportunity(acc1, cont1);
        opp1.RecordTypeId = opp.RecordTypeId;
    
        update new List<Opportunity>{ opp, opp1 };
    
    
        // for (Integer i = 0; i < properties1.size(); i++) {
        // }
    
        Test.startTest();
        List<Property__c> properties = test_Helper.createProperties(opp);
    
        opp1.RecordTypeId = opp.RecordTypeId;
        List<Property__c> properties1 = test_Helper.createProperties(opp1);
    
        dupcheck__dcJob__c dupeJob = new dupcheck__dcJob__c();
        dupeJob.dupcheck__sourceObject__c = 'a19';
        dupeJob.dupcheck__name__c = 'Bingo';
        insert dupeJob;
    
        dupcheck__dcGroup__c dupeGroup = new dupcheck__dcGroup__c();
        dupeGroup.dupcheck__dcJob__c = dupeJob.Id;
        dupeGroup.dupcheck__group__c = 1;
        insert dupeGroup;
    
        List<dupcheck__dc3Duplicate__c> dupes = new List<dupcheck__dc3Duplicate__c>();
        for (Integer i = 0; i < properties.size() - 1; i++) {
          dupcheck__dc3Duplicate__c dupe = new dupcheck__dc3Duplicate__c();
          dupe.dupcheck__dcGroup__c = dupeGroup.Id;
          dupe.dupcheck__dcJob__c = dupeJob.Id;
          dupe.dupcheck__SourceObject__c = properties[i].Id;
          dupe.dupcheck__MatchObject__c = properties1[i].Id;
          dupe.dupcheck__Score__c = 100;
          dupes.add(dupe);
        }
    
        dupcheck__dc3Duplicate__c dupe = new dupcheck__dc3Duplicate__c();
        dupe.dupcheck__dcGroup__c = dupeGroup.Id;
        dupe.dupcheck__dcJob__c = dupeJob.Id;
        dupe.dupcheck__SourceObject__c = properties1[properties1.size() - 1].Id;
        dupe.dupcheck__MatchObject__c = properties[properties.size() - 1].Id;
        dupe.dupcheck__Score__c = 100;
        dupes.add(dupe);
    
        insert dupes;
    
        dupeJob.dupcheck__status__c = 'Completed';
        update dupeJOb;
          
        DuplicateDealsEmailController controller = new DuplicateDealsEmailController();
        controller.recid = opp.Id;
        List<Property__c> dupeProps = controller.properties;
        String baseUrl = controller.baseUrl;
        Boolean hasDupes = controller.hasDuplicates;
        Integer numDupes =  controller.numDuplicates;        
        Test.stopTest();

        System.assertEquals(properties.size() * 2, dupeProps.size(), 'DuplicateDealsEmailController.properties.size()');
        System.assertEquals(true, String.isNotEmpty(baseUrl), 'DuplicateDealsEmailController.baseUrl');
        System.assertEquals(true, hasDupes, 'DuplicateDealsEmailController.hasDuplicates');
        System.assertEquals(dupeProps.size(), numDupes, 'DuplicateDealsEmailController.numDuplicates');
    }
}
