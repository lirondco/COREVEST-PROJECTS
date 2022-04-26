@isTest(seeAllData=true)
private class InterfaceEmail_Tests {


    static void setupTestData(){
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u){
            List<EmailTemplate> emailTemplates = test_Helper.createEmailTemplates(new List<String>{
                'TERM_Term_Sheet_Request_VF'
                , 'BRIDGE_Term_Sheet_Outside_Guidelines_VF'
                , 'BRIDGE_Term_Sheet_Within_Guidelines_VF'
            });
        }
        Email_Addresses__c BETH = InterfaceEmail_LightningController.queryEmailAddress('Beth O\'Brien');
        // Email_Addresses__c RYAN = InterfaceEmail_LightningController.queryEmailAddress('Ryan McBride');
        Email_Addresses__c CHRIS = InterfaceEmail_LightningController.queryEmailAddress('Chris Hoeffel');
        Email_Addresses__c BRIDGE_LIST = InterfaceEmail_LightningController.queryEmailAddress('Bridge Term Sheet Mailing List');
        Email_Addresses__c TERM_LIST = InterfaceEmail_LightningController.queryEmailAddress('Term Sheet Mailing List');
        upsert new List<Email_Addresses__c>{BETH,CHRIS,BRIDGE_LIST,TERM_LIST};
  
    }

    static TestMethod void InterfaceEmail_Tests_UnitTest(){
        List<RecordType> opptyRecordTypes = [SELECT Id FROM RecordType WHERE sObjectType = 'Opportunity'];
        
        Id termLoanRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Term Loan').getRecordTypeId();
        Id bridgeLoanRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Bridge Loan').getRecordTypeId();

        
        Account acc = test_Helper.createAccount();
        Contact cont = test_Helper.createContact( acc );
        Opportunity opp = test_Helper.createOpportunity( acc, cont );
        ContentVersion testCv=new Contentversion();

        testCv.title='ABC';
        testCv.PathOnClient ='test';
        testCv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        insert testCv;

        Deal_Document__c dealDoc = new Deal_Document__c();
        dealDoc.ContentVersion_Id__c = testCv.Id;
        dealDoc.Type__c= 'Term Sheet';
        dealDoc.Document_Loaded__c = true;
        dealDoc.Include_for_Term_Sheet_Approval__c = true;
        dealDoc.Deal__c = opp.Id;
        insert dealDoc;
        
        opp.RecordTypeId = opptyRecordTypes[0].Id;
        opp.Loan_Effective_Date__c = system.today();
        update opp;

        Attachment a = new Attachment(Name='Test',ParentId=opp.Id,Body=blob.valueOf('test'));

        Test.startTest();
        InterfaceEmail_LightningController.Person person = new InterfaceEmail_LightningController.Person().CurrentUser();
        InterfaceEmail_LightningController.returnDeal(opp.Id);

        if (opptyRecordTypes.size() > 1){
            //opp.RecordTypeId = opptyRecordTypes[1].Id;
            opp.RecordTypeId = termLoanRecordTypeId;
            opp.LOC_Program_Type__c = 'Custom';
            opp.Approved_Term_Sheet_Name__c = null;
            update opp;
            
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(opp.Id);
            //req.setSkipEntryCriteria(true);
            Approval.ProcessResult result = Approval.process(req);
            //String status = result.getInstanceStatus();
            //String customStatus = 'Submitted';

            //Id processInstanceId = result.getInstanceId();
            
            List<ProcessInstance> pList = [SELECT Id,(Select Id From Workitems), Status, TargetObjectId, ProcessDefinition.Name FROM ProcessInstance WHERE TargetObjectId = : opp.Id ORDER BY CreatedDate DESC LIMIT 10 ];
            System.debug('pList >>>>>> '+pList);
            System.debug('pList >>>>>> '+pList[0].Workitems);
            List<Id> newWorkItemIds = new List<Id>();
            if(pList != null && !pList.isEmpty()) {

                for (List<ProcessInstanceWorkitem> wis : pList[0].Workitems) {
                    for (ProcessInstanceWorkitem wi : wis ) {
                        newWorkItemIds.add(wi.id);
                    }
                }

                // Instantiate the new ProcessWorkitemRequest object and populate it
                Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
                req2.setComments('Approving request.');
                req2.setAction('Approve');
                req2.setWorkitemId(newWorkItemIds.get(0));
                
                // Submit the request for approval
                Approval.ProcessResult result2 =  Approval.process(req2);
                
                pList = [SELECT Id, (Select Id From Workitems), Status, TargetObjectId, ProcessDefinition.Name FROM ProcessInstance WHERE TargetObjectId = : opp.Id ORDER BY CreatedDate DESC LIMIT 10 ];
                
                System.debug('pList >>>>>> '+pList);
                System.debug('pList >>>>>> '+pList[0].Workitems);
            }

            InterfaceEmail_LightningController.returnDeal(opp.Id);
        }

        if (opptyRecordTypes.size() > 2){
            opp.RecordTypeId = opptyRecordTypes[2].Id;
            update opp;
            InterfaceEmail_LightningController.returnDeal(opp.Id);
        }
        List<EmailTemplate> e = InterfaceEmail_LightningController.queryEmailTemplate('TERM_Term_Sheet_Request_VF');
        InterfaceEmail_LightningController.queryAttachments( new List<Id>{UserInfo.getUserId()});
        InterfaceEmail_LightningController.queryContentVersions( new List<Id>{UserInfo.getUserId()});

        Attachment att = new Attachment();
        att.Name='Test';
        att.Body=Blob.valueOf('test');
        InterfaceEmail_LightningController.constructFileAttachment(att);

        ContentVersion cv = new ContentVersion();
        cv.PathOnClient='/';
        cv.VersionData=blob.valueOf('test');
        InterfaceEmail_LightningController.constructFileAttachment(cv);

        Map<String,String> m = new Map<String,String>();
        m.put('recipients', 'test@test.com');
        m.put('ccUsers', 'test@test.com');
        List<Id> aIds = new List<Id>();
        List<Id> cIds = new List<Id>();

        try {
            Messaging.reserveSingleEmailCapacity(2);
            InterfaceEmail_LightningController.sendMail(
            new List<String>{'test@test.com'}, 'Subject','html', new List<Messaging.EmailFileAttachment>(),
            new List<String>{'test@test.com'}, 'Test', null, null, null, null, null
            );

            InterfaceEmail_LightningController.sendMail(
            new String[]{'wluk@mkpartners.com'}, null, null, null, null,
            'WLUK', false, false, cont.Id, e[0].Id, opp.Id
            );
            InterfaceEmail_LightningController.sendEmail(JSON.serialize(m), JSON.serialize(aIds), JSON.serialize(cIds));

        } catch (Exception exc){
            System.debug(exc);
        }
        Test.stopTest();
    }

}