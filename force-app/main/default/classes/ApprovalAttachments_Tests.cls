@isTest
private class ApprovalAttachments_Tests {
  //static List<Account> testAccounts = testDataFactory.createTestRecords(new Account[10]);

  @isTest(SeeAllData=true)
  static void ApprovalAttachments_Tests_UnitTest() {
    User capMarketsUser;
    User acceptableUser;
    String capMarketsRoleName = ApprovalAttachments_lightningController.CAPITAL_MARKET;
    String acceptableRoleName = 'Bridge';
    Id profileId = Approval_TestDataFactory.findProfile().Id;
    Set<String> roleNames = new Set<String>{
      capMarketsRoleName,
      acceptableRoleName
    };

    List<User> userList = [
      SELECT Id, UserRole.Name
      FROM User
      WHERE IsActive = TRUE AND UserRole.Name IN :roleNames
    ];

    for (User u : userList) {
      if (u.UserRole.Name == capMarketsRoleName) {
        capMarketsUser = u;
      } else if (u.UserRole.Name == acceptableRoleName) {
        acceptableUser = u;
      }
      if (null != capMarketsUser && null != acceptableUser) {
        break;
      }
    }

    if (null == capMarketsUser) {
      UserRole capMarketsUr = Approval_TestDataFactory.createUserRole(
        capMarketsRoleName
      );
      capMarketsUser = Approval_TestDataFactory.createUser(
        0,
        capMarketsUr.Id,
        profileId
      );
    }

    if (null == acceptableUser) {
      UserRole acceptableUr = Approval_TestDataFactory.createUserRole(
        acceptableRoleName
      );
      acceptableUser = Approval_TestDataFactory.createUser(
        1,
        acceptableUr.Id,
        profileId
      );
    }

    Opportunity o = Approval_TestDataFactory.createDeal(
      capMarketsUser.Id,
      acceptableUser.Id,
      'Approved'
    );
    o = ApprovalAttachments_lightningController.modifyOpportunity(o);

    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
    req.setObjectId(o.Id);
    req.setSkipEntryCriteria(true);
    Approval.ProcessResult result = Approval.process(req);
    System.debug('this is the result: ' + result);

    List<ProcessInstanceStep> pisList = [
      SELECT Id
      FROM ProcessInstanceStep
      WHERE ProcessInstance.TargetObjectId = :o.Id
    ];

    List<ProcessInstanceWorkItem> piwList = [
      SELECT Id
      FROM ProcessInstanceWorkItem
      WHERE ProcessInstance.TargetObjectId = :o.Id
    ];

    Id pisId;
    if (pisList.size() > 0) {
      pisId = pisList[0].Id;
      ProcessInstanceStep pis = ApprovalAttachments_lightningController.returnInstanceStep(
        pisId
      );
      System.assertEquals(pis.Id, pisId);
    }
    Id piwId;
    Id piwId2;
    if (piwList.size() > 0) {
      piwId = piwList[0].Id;
      piwId2 = piwList[1].Id;
      ApprovalAttachments_lightningController.getApprovalDetails(piwId);
    }

    Approval_History__c ahc = Approval_TestDataFactory.createApprovalHistory(
      piwId,
      pisId
    );
    Approval_History__c ahc2 = Approval_TestDataFactory.createApprovalHistory(
      piwId2,
      pisId
    );
    ApprovalHistory_lightningController.returnHistory(piwId);
    ApprovalHistory_lightningController.returnHistoryOpp(o.Id);

    System.runAs(capMarketsUser) {
      String sMapCap = ApprovalAttachments_lightningController.getApprovalDetails(
        piwId
      );
      Map<String, String> initMapCap = (Map<String, String>) JSON.deserialize(
        sMapCap,
        Map<String, String>.class
      );
      Map<String, String> mCap = new Map<String, String>{
        'Status' => 'Pending'
      };
      System.assertEquals(initMapCap.get('Status'), mCap.get('Status'));
    }
    System.runAs(acceptableUser) {
      String serializedMap = ApprovalAttachments_lightningController.getApprovalDetails(
        piwId
      );
      Map<String, String> initMap = (Map<String, String>) JSON.deserialize(
        serializedMap,
        Map<String, String>.class
      );
      Map<String, String> m = new Map<String, String>{ 'Status' => 'Pending' };
      System.assertEquals(initMap.get('Status'), m.get('Status'));
    }

    ApprovalAttachments_lightningController.returnAttachments(piwId);
    ApprovalAttachments_lightningController.approveDeal(
      piwId,
      acceptableRoleName,
      o.Id,
      'test comments',
      o,
      'test'
    );
    ApprovalAttachments_lightningController.rejectDeal(
      piwId2,
      o.Id,
      'test comments',
      acceptableRoleName
    );


    ApprovalAttachments_lightningController.sendRejectionEmail(o, new List<String>{'test@test.com'});
    ApprovalAttachments_lightningController.returnParentAndChild(piwId);
    Attachment a = Approval_TestDataFactory.createAttachment(o.Id);
    ContentVersion cv = Approval_TestDataFactory.createCv();

    ContentDocumentLink cdl = Approval_TestDataFactory.createCdl(
      cv.ContentDocumentId,
      o.Id
    );
    Email__c e = Approval_TestDataFactory.createEmail(a.Id, cv.Id, o.Id);
    ApprovalAttachments_lightningController.getParentAttachments(e.Id);

    ApprovalAttachments_lightningController.returnUserAndOppId(o.Id);

    // Test.startTest();

    // Test.stopTest();
  }

  @isTest(SeeAllData=true)
  static void ApprovalAttachments_Tests_UnitTest2() {
    User capMarketsUser;
    User acceptableUser;
    String capMarketsRoleName = ApprovalAttachments_lightningController.CAPITAL_MARKET;
    String acceptableRoleName = 'Bridge';
    Id profileId = Approval_TestDataFactory.findProfile().Id;
    Set<String> roleNames = new Set<String>{
      capMarketsRoleName,
      acceptableRoleName
    };

    List<User> userList = [
      SELECT Id, UserRole.Name
      FROM User
      WHERE IsActive = TRUE AND UserRole.Name IN :roleNames
    ];

    for (User u : userList) {
      if (u.UserRole.Name == capMarketsRoleName) {
        capMarketsUser = u;
      } else if (u.UserRole.Name == acceptableRoleName) {
        acceptableUser = u;
      }
      if (null != capMarketsUser && null != acceptableUser) {
        break;
      }
    }

    if (null == capMarketsUser) {
      UserRole capMarketsUr = Approval_TestDataFactory.createUserRole(
        capMarketsRoleName
      );
      capMarketsUser = Approval_TestDataFactory.createUser(
        0,
        capMarketsUr.Id,
        profileId
      );
    }

    if (null == acceptableUser) {
      UserRole acceptableUr = Approval_TestDataFactory.createUserRole(
        acceptableRoleName
      );
      acceptableUser = Approval_TestDataFactory.createUser(
        1,
        acceptableUr.Id,
        profileId
      );
    }

    Opportunity o = Approval_TestDataFactory.createDeal(
      capMarketsUser.Id,
      acceptableUser.Id,
      'Approved'
    );
    o = ApprovalAttachments_lightningController.modifyOpportunity(o);

    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
    req.setObjectId(o.Id);
    req.setSkipEntryCriteria(true);
    Approval.ProcessResult result = Approval.process(req);
    System.debug('this is the result: ' + result);

    List<ProcessInstanceStep> pisList = [
      SELECT Id
      FROM ProcessInstanceStep
      WHERE ProcessInstance.TargetObjectId = :o.Id
    ];

    ApprovalAttachments_lightningController.returnParentAndChild(pisList[0].Id);

    List<ProcessInstanceWorkItem> piwList = [
      SELECT Id
      FROM ProcessInstanceWorkItem
      WHERE ProcessInstance.TargetObjectId = :o.Id
    ];

    Id pisId;
    if (pisList.size() > 0) {
      pisId = pisList[0].Id;
      ProcessInstanceStep pis = ApprovalAttachments_lightningController.returnInstanceStep(
        pisId
      );
      System.assertEquals(pis.Id, pisId);
    }
    Id piwId;
    Id piwId2;
    if (piwList.size() > 0) {
      piwId = piwList[0].Id;
      piwId2 = piwList[1].Id;
      //ApprovalAttachments_lightningController.getApprovalDetails(piwId);
    }
    Test.startTest();
    ApprovalAttachments_lightningController.approveDeal(
      piwId,
      'Capital Markets',
      o.Id,
      'test',
      o,
      'Test'
    );
    Test.stopTest();
  }
}