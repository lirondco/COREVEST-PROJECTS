@isTest
private class ApprovalHistory_Tests {

    //static List<Account> testAccounts = testDataFactory.createTestRecords(new Account[10]);

    @isTest (SeeAllData=true)
    static void ApprovalHistory_Tests_UnitTest(){
        User capMarketsUser;
        User acceptableUser;
        String capMarketsRoleName = ApprovalAttachments_lightningController.CAPITAL_MARKET;
        String acceptableRoleName = 'Bridge';
        Id profileId = Approval_TestDataFactory.findProfile().Id;
        Set<String> roleNames = new Set<String>{capMarketsRoleName, acceptableRoleName};
        List<User> userList = [
            SELECT Id,UserRole.Name
            FROM User
            WHERE UserRole.Name
            IN :roleNames
        ];

        for (User u : userList){
            if (u.UserRole.Name == capMarketsRoleName){
                capMarketsUser = u;
            } else if (u.UserRole.Name == acceptableRoleName){
                acceptableUser = u;
            }
            if (null != capMarketsUser
                && null != acceptableUser){
                break;
            }
        }

        if (null == capMarketsUser ){
            UserRole capMarketsUr = Approval_TestDataFactory.createUserRole(capMarketsRoleName);
            capMarketsUser = Approval_TestDataFactory.createUser(0, capMarketsUr.Id, profileId);
        }

        if (null == acceptableUser){
            UserRole acceptableUr = Approval_TestDataFactory.createUserRole(acceptableRoleName);
            acceptableUser = Approval_TestDataFactory.createUser(1, acceptableUr.Id, profileId);
        }

        Opportunity o = Approval_TestDataFactory.createDeal(capMarketsUser.Id, acceptableUser.Id, 'Approved');
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(o.Id);
        req.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req);
        String status = result.getInstanceStatus();
        String customStatus = 'Submitted';

        Id processInstanceId = result.getInstanceId();
        System.debug(processInstanceId);
        List<Id> workItemIds = result.getnewworkitemids();
        System.debug(workItemIds);

        List<Approval_History__c> ahList = new List<Approval_History__c>();
        Approval_History__c ahc = new Approval_History__c(
            Process_Instance_Id__c = processInstanceId,
            Parent_Status__c = status,
            Deal__c = o.Id,
            Name = 'Pricing Review Request: ' + 'Example',
            Approver__c = UserInfo.getName(),
            Actor__c = UserInfo.getUserId(),
            Role__c = 'Submitter',
            Date_Acted__c = System.now(),
            Status__c = customStatus,
            Status_Text__c = customStatus,
            Comments__c = 'comments'
        );
        insert ahc;

        for (Integer i = 0; i < workItemIds.size(); i++){
            Approval_History__c a = new Approval_History__c(
                Process_Instance_Id__c = processInstanceId,
                Process_Id__c = workItemIds[i],
                Parent_Status__c = status,
                Deal__c = o.Id,
                Name = 'Pricing Review Approval: ' + 'Example',
                Approver__c = 'Approver',
                Status__c = 'Pending',
                Status_Text__c = 'Pending'
            );
            ahList.add(a);
        }
        insert ahList;

        Test.startTest();
        List<Approval_History__c> testList = ApprovalHistory_lightningController.returnHistory(workItemIds[0]);
        ApprovalHistory_lightningController.approveDeal(workItemIds[0], 'Capital Markets', o.Id, 'Test Comment', o, 'Term_Pricing_Review');
        // System.assertEquals(testList.size(), );
        ApprovalHistory_lightningController.returnHistoryOpp(o.Id);
        ApprovalAttachments_LightningController.rejectDealForGLCApproval(workItemIds[0], o.Id, 'test', 'Capital Markets');
        ApprovalHistory_lightningController.recallApproval(workItemIds[0]);
        ApprovalHistory_lightningController.recallApproval(workItemIds[0]);
        ApprovalHistory_lightningController.returnAllReviews();
        Test.stopTest();
    }

}