@isTest
private class AppraisalTests {
    static testmethod void mergeTest(){
        Account acc = Test_Helper.createAccount();
        Contact cont = Test_Helper.createContact( acc );
        Opportunity opp = Test_Helper.createOpportunity( acc, cont );
        opp.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Term_Loan' and sobjecttype = 'Opportunity'].Id;
        List<Property__c> properties = Test_Helper.createProperties(opp);
        Appraisal__c appraisal = Test_Helper.createAppraisal(opp, properties[0]);
        appraisal.Status__c = 'Complete-Delivered';
        update appraisal;
        Test.startTest();
            AppraisalMergeController.initMergeScreen(opp.Id);
        Test.stopTest();
        
    }

    static testmethod void parserTest(){
        StaticResource xml = [SELECT Id, Body FROM StaticResource WHERE Name = 'AppraisalXMLTest' LIMIT 1];
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.xml',
            VersionData = xml.Body,
            IsMajorVersion = true
        );

        insert cv;
        Id docId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id LIMIT 1].ContentDocumentId;
        Account acc = Test_Helper.createAccount();
        Contact cont = Test_Helper.createContact( acc );
        Opportunity opp = Test_Helper.createOpportunity( acc, cont );
        opp.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Term_Loan' and sobjecttype = 'Opportunity'].Id;
        List<Property__c> properties = Test_Helper.createProperties(opp);

        Deal_Document__c doc = new Deal_Document__c(
            Deal__c = opp.Id,
            Property__c = properties[0].Id,
            Document_Type__c = 'Valuations'
        );

        insert doc;

        Test.startTest();
            doc.Attachment_Id__c = docId;
            update doc;
            // system.assert(xml != null);
        Test.stopTest();    

        
    }

    static testmethod void parserTestBBG(){
        StaticResource xml = [SELECT Id, Body FROM StaticResource WHERE Name = 'AppraisalBBGXMLTest' LIMIT 1];
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.xml',
            VersionData = xml.Body,
            IsMajorVersion = true
        );

        insert cv;
        Id docId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id LIMIT 1].ContentDocumentId;
        Account acc = Test_Helper.createAccount();
        Contact cont = Test_Helper.createContact( acc );
        Opportunity opp = Test_Helper.createOpportunity( acc, cont );
        opp.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Term_Loan' and sobjecttype = 'Opportunity'].Id;
        List<Property__c> properties = Test_Helper.createProperties(opp);

        Deal_Document__c doc = new Deal_Document__c(
            Deal__c = opp.Id,
            Property__c = properties[0].Id,
            Document_Type__c = 'Valuations'
        );

        insert doc;

        Test.startTest();
            doc.Attachment_Id__c = docId;
            update doc;
            // system.assert(xml != null);
        Test.stopTest();    

        
    }


}