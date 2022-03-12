@isTest
private class util_Tests {

    //static List<Account> testAccounts = testDataFactory.createTestRecords(new Account[10]);

    static TestMethod void util_Tests_UnitTest(){
        Account acc = test_Helper.createAccount();
		Contact cont = test_Helper.createContact( acc );
        Opportunity opp = test_Helper.createOpportunity( acc, cont );
        List<Property__c> props = test_Helper.createProperties( opp );

        Test.startTest();
            util.queryOppAndChildren(opp.Id, 'Opportunity', 'Property__c', 'Properties__r');
            util.queryRecordAndChildren(opp.Id, 'Opportunity', 'Property__c', 'Properties__r');
            util.getFieldTypeMap('Opportunity');
            util.getFieldDescribeMap('Opportunity');
            // util.getMappedObjectById('Opportunity',opp.id);
            util.getFullObjectById('Opportunity',opp.Id);
            util.queryRecords('SELECT Id FROM User LIMIT 1');
            util.queryRecords('Opportunity', 'Name != null', 'CreatedDate ASC');
            util.queryRecordAllFields(opp.Id);
            util.queryRecordsAllFields(new Set<Id>{opp.Id});
            util.idToSObject(opp.Id);
            Decimal d;
            util.fixNull(d);
            util.compileRecordTypeMap('Opportunity');
            util.getAllFieldNamesForObject('Opportunity');
            util.getActiveMappedFieldNamesForObject('Opportunity');
            util.getActiveMappingsForObject('Opportunity');
            util.getActiveMappedSelectFields('Opportunity');
        Test.stopTest();
    }

}