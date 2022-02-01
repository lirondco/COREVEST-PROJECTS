public without sharing class ApprovalHistory_lightningController {
  public static final String CAPITAL_MARKET = 'Capital Markets';
  public static final String EXECUTIVE = 'Executive';
  public static final Set<String> acceptableRoles = new Set<String>{
    'Administrator',
    'Bridge',
    'Bridge Manager',
    'Term Manager',
    'Term'
  };

  public static final List<String> IC_APPROVAL_NAMES = new List<String>{
    'Term_IC_Approval',
    'Bridge_IC_Approval',
    'Term_Sub_IC',
    'Bridge_Sub_IC'
  };


  @AuraEnabled
  public static String recallApproval(Id processId) {
    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
    pwr.setAction('Removed');
    pwr.setWorkItemId(processId);

    try {
      Approval.ProcessResult result = Approval.process(pwr);
      System.debug(result.isSuccess());
      if (true == result.isSuccess()) {
        System.debug('inside success conditional');
        List<Approval_History__c> ahList = [
          SELECT Id, Process_Instance_Id__c
          FROM Approval_History__c
          WHERE Process_Id__c = :processId
        ];
        if (ahList.size() > 0) {
          Id processInstanceId = ahList[0].Process_Instance_Id__c;

          List<Approval_History__c> aList = [
            SELECT
              Id,
              Status__c,
              Status_Text__c,
              Parent_Status__c,
              Date_Acted__c
            FROM Approval_History__c
            WHERE Process_Instance_Id__c = :processInstanceId
          ];

          for (Approval_History__c a : aList) {
            a.Parent_Status__c = 'Recalled';
            a.Status__c = 'Recalled';
            a.Status_Text__c = 'Recalled';
            a.Date_Acted__c = System.now();
          }

          update aList;
        }
      }
      return 'Request has been successfully recalled.';
    } catch (Exception e) {
      return 'There was an error recalling this request. Error: ' +
        e.getMessage() +
        ' Please contact your administrator.';
    }
  }

  @AuraEnabled
  public static List<Approval_History__c> returnHistory(Id recordId) {
    // recordId is Process_Instance_Id__c on approval_history__c
    // query approval_history__c based on Process_Instance_Id__c

    // recordId is a proces work

    Approval_History__c ah = [
      SELECT Id, Process_Instance_Id__c, Deal__c
      FROM Approval_History__c
      WHERE Process_Id__c = :recordId
      LIMIT 1
    ];

    if (null != ah.Process_Instance_Id__c) {
      List<Approval_History__c> ahList = [
        SELECT
          Id,
          Actor__c,
          Name,
          Approver__c,
          Comments__c,
          Deal__c,
          Parent_Status__c,
          Process_Id__c,
          Process_Instance_Id__c,
          Status__c,
          Date_Acted__c,
          Time_in_Approval__c,
          Step_Item_Id__c,
          Status_Text__c,
          Approval_Type__c,
          Resolution__c
        FROM Approval_History__c
        WHERE Deal__c = :ah.Deal__c AND Status__c != 'Recalled'
        //WHERE Process_Instance_Id__c = :ah.Process_Instance_Id__c
        // AND Process_Id__c != null
        ORDER BY CreatedDate ASC
      ];
      return ahList;
    }
    return null;
  }

  @AuraEnabled
  public static String returnHistoryOpp(Id recordId) {
    Id submitterId;
    Id processId;

    Opportunity o = [
      SELECT
        Id,
        Approved_by_Capital_Markets__c,
        Approved_by_Underwriter__c,
        OwnerId,
        Owner.Name,
        Approval_Status__c,
        Apex_Context__c,
        RecordType.Name
      FROM Opportunity
      WHERE Id = :recordId
      LIMIT 1
    ];
    // List<UserRole> roleList = [
    // 	SELECT Id,Name
    // 	FROM UserRole
    // ];

    // Map<Id,String> roleMap = new Map<Id,String>();
    // for (UserRole ur : roleList){
    // 	roleMap.put(ur.Id, ur.Name);
    // }

    Map<String, Boolean> permissionMap = ApprovalAttachments_lightningController.compilePermissions();
    Boolean capitalMarketsPricingApprover = permissionMap.get(
      'Capital_Markets_Pricing_Approver'
    );
    Boolean sabPricingApprover = permissionMap.get('SAB_Pricing_Approver');
    Boolean termEntryIntoUWApprover = permissionMap.get(
      'Term_Entry_Into_UW_Approver'
    );
    Boolean termPricingApprover = permissionMap.get('Term_Pricing_Approver');
    Boolean bridgePricingApprover = permissionMap.get(
      'Bridge_Pricing_Approver'
    );
    Boolean bridgeEntryIntoUWApprover = permissionMap.get(
      'Bridge_Entry_Into_UW_Approver'
    );

    system.debug('PERMISSION MAP');
    system.debug(JSON.serialize(permissionMap));
    String roleName = ''; //roleMap.get(UserInfo.getUserRoleId());

    List<Approval_History__c> ahList = [
      SELECT
        Id,
        Actor__c,
        Name,
        Approver__c,
        Comments__c,
        Deal__c,
        Parent_Status__c,
        Process_Id__c,
        Process_Instance_Id__c,
        Status__c,
        Date_Acted__c,
        Time_in_Approval__c,
        Step_Item_Id__c,
        Status_Text__c,
        Verified__c,
        Approval_Type__c,
        Deal__r.Approved_by_Capital_Markets__c,
        Deal__r.Approved_by_Underwriter__c,
        Deal__r.OwnerId,
        Deal__r.Owner.Name,
        Deal__r.Approval_Status__c,
        Deal__r.Apex_Context__c,
        Deal__r.Underwriter__c,
        CreatedDate,
        Resolution__c
      FROM Approval_History__c
      WHERE Deal__c = :recordId
      ORDER BY LastModifiedDate DESC
    ];

    Map<Id, String> idMap = new Map<Id, String>();
    for (Approval_History__c ah : ahList) {
      idMap.put(ah.Process_Id__c, '');
    }

    for (ProcessInstanceWorkItem piw : [
      SELECT
        Id,
        ProcessInstance.ElapsedTimeInDays,
        ProcessInstance.TargetObjectId,
        ProcessInstance.Status,
        ProcessInstance.ProcessDefinition.DeveloperName,
        ActorId
      FROM ProcessInstanceWorkItem
      WHERE Id IN :idMap.keySet()
    ]) {
      idMap.put(piw.Id, piw.ProcessInstance.ProcessDefinition.DeveloperName);
    }

    Boolean allowUnderwriterRecall = false;

    List<OpportunityTeamMember> otmList = [
      SELECT
        Id
      FROM OpportunityTeamMember
      WHERE OpportunityId = :recordId
      AND UserId = :UserInfo.getUserId()
      AND TeamMemberRole = 'Underwriter'
    ];

    for (Approval_History__c ah : ahList) {
      if (
        null == processId &&
        null != ah.Process_Id__c &&
        ah.Status__c == 'Pending'
      ) {
        processId = ah.Process_Id__c;
      }
      if (
        null == submitterId &&
        (ah.Status_Text__c == 'Submitted' ||
        ah.Status_Text__c == 'Re-submitted') &&
        null != ah.Actor__c &&
        ah.Parent_Status__c == 'Pending'
      ) {
        submitterId = ah.Actor__c;
      }
      if (null != ah.Date_Acted__c) {
        ah.Date_Acted__c.format();
      }

      ah.Verified__c = false;
      //String roleName = roleMap.get(UserInfo.getUserRoleId());

      if (ah.Status__c.contains('Pending')) {
        ah.ProcessName__c = idMap.get(ah.Process_Id__c);
        String processName = ah.ProcessName__c;
        system.debug('--processname--');
        system.debug(processName);

        // if(ah.Name.contains('Pricing')){
        //     if (roleName == CAPITAL_MARKET || roleName == EXECUTIVE){
        //         if (null != ah.Deal__r.Approved_by_Capital_Markets__c){
        //             //if (o.Approval_Status__c == 'Approved'){

        //                 //o = modifyOpportunity(o);
        //             //}
        //             //m.put('Verified', 'true');

        //         }else{
        //             ah.Verified__c = true;
        //         }

        //     } else if (acceptableRoles.contains(roleName)){
        //         //if (null != o.Approved_by_Underwriter__c){
        //             //if (o.Approval_Status__c == 'Approved'){
        //                 //o = modifyOpportunity(o);
        //             //}
        //         //}
        //         // else {
        //             //m.put('Verified', 'true');
        //         ah.Verified__c = true;
        //         // }
        //     }
        // }else if(ah.Name.contains('UW Approval') && acceptableRoles.contains(roleName)){
        //    // ah.Verified__c = ApprovalAttachments_lightningController.userInGroup(ApprovalAttachments_lightningController.approvalGroupMap.get(ah.ProcessName__c));
        // 	//m.put('Verified', verified);
        //     //ah.Verified__c
        // }

        if (processName == 'Submit_Term_Deal_to_UW_Approval') {
          if (termEntryIntoUWApprover) {
            ah.Verified__c = true;
          }
        } else if (processName == 'Submit_Bridge_Deal_to_UW_Approval') {
          if (bridgeEntryIntoUWApprover) {
            ah.Verified__c = true;
          }
        } else if (capitalMarketsPricingApprover) {
          if (null != o.Approved_by_Capital_Markets__c) {
            // if (o.Approval_Status__c == 'Approved'){
            //     o = modifyOpportunity(o);

            // }
            // ah.Verified__c = true;
          } else {
            ah.Verified__c = true;
          }
          roleName = 'Capital Markets';
        } else if (processName == 'Bridge_LOC_Pricing_Review') {
          if (bridgePricingApprover) {
            if (null != o.Approved_by_Underwriter__c) {
              // if (o.Approval_Status__c == 'Approved'){
              //     o = modifyOpportunity(o);
              // }
              // ah.Verified__c = true;
            } else {
              ah.Verified__c = true;
            }
          }
          roleName = 'Underwriter';
        } else if (processName == 'Term_Pricing_Review') {
          if (termPricingApprover) {
            if (null != o.Approved_by_Underwriter__c) {
              // if (o.Approval_Status__c == 'Approved'){
              //     o = modifyOpportunity(o);
              // }
              // ah.Verified__c = true;
            } else {
              ah.Verified__c = true;
            }
          }
          roleName = 'Underwriter';
        } else if (processName == 'Custom_SAB_Pricing_Review') {
          if (sabPricingApprover) {
            if (null != o.Approved_by_Underwriter__c) {
              // if (o.Approval_Status__c == 'Approved'){
              //     o = modifyOpportunity(o);
              // }
              // ah.Verified__c = true;
            } else {
              ah.Verified__c = true;
            }
          }
          roleName = 'Underwriter';
        } else if (processName == 'Standard_SAB_Pricing_Review') {
          if (sabPricingApprover) {
            if (null != o.Approved_by_Underwriter__c) {
              // if (o.Approval_Status__c == 'Approved'){
              //     o = modifyOpportunity(o);
              // }
            } else {
              ah.Verified__c = true;
            }
          }
          roleName = 'Underwriter';
        } 
        if (IC_APPROVAL_NAMES.contains(processName) && ah.Actor__c == UserInfo.getUserId()) {
          ah.Verified__c = true;
        }

        if(IC_APPROVAL_NAMES.contains(processName) && (otmList.size() > 0 || ah.Deal__r.Underwriter__c == UserInfo.getUserId()) || IcApprovalController.verifyPermission()){
          allowUnderwriterRecall = true;
        }
      }
    }

    Boolean b = submitterId == UserInfo.getUserId() || allowUnderwriterRecall;

    returnWrapper rw = new returnWrapper();
    rw.ahList = ahList;
    rw.isSubmitter = b;
    rw.processId = processId;
    rw.userRole = roleName;

    String dealName = [SELECT Id, Name FROM Opportunity WHERE id = :recordId]
    .Name;
    //TriVikram added below code to display Chatter Comments
    List<ChatterCommentsWrapper> ChatterCommentsList = new List<ChatterCommentsWrapper>();
    List<FeedItem> allFeeds = [
      SELECT Id, Body, CreatedDate, ParentId, createdBy.Name
      FROM FeedItem
      WHERE
        ParentId IN (
          SELECT Id
          FROM Custom_Chatter_Mapping__c
          WHERE Deal__c = :recordId
        )
    ];
    for (FeedItem feed : allFeeds) {
      ChatterCommentsList.add(
        new ChatterCommentsWrapper(
          'Pricing Review Chatter Comments: ' + dealName,
          feed.createdDate,
          feed.createdBy.Name,
          feed.Body
        )
      );
    }
    rw.ChatterCommentsList = ChatterCommentsList;
    return JSON.serialize(rw);
  }

  @AuraEnabled
  public static String returnAllReviews() {
    List<Approval_History__c> ahList = [
      SELECT
        Id,
        Actor__c,
        Actor__r.Name,
        Name,
        Approver__c,
        Comments__c,
        Date_Acted__c,
        Time_in_Approval__c,
        Deal__c,
        Deal__r.Name,
        Deal__r.Type,
        Deal__r.Owner_Name__c,
        Deal__r.Loan_Size__c,
        Deal__r.LOC_Loan_Type__c,
        Deal__r.Product_Sub_Type__c,
        Deal__r.LOC_Program_Type__c,
        Deal__r.RecordType.DeveloperName,
        Parent_Status__c,
        Process_Id__c,
        Process_Instance_Id__c,
        Status__c,
        Step_Item_Id__c,
        Status_Text__c,
        LastModifiedDate,
        Approval_Type__c,
        Deal_Stage_At_Time_of_Submission__c
      FROM Approval_History__c
      WHERE Parent_Status__c = 'Pending'
      ORDER BY LastModifiedDate DESC
    ];

    Set<Id> processIds = new Set<Id>();
    for (Approval_History__c ahc : ahList) {
      processIds.add(ahc.Process_Instance_Id__c);
    }

    Set<Id> pricingReviewIds = new Set<Id>();
    for (ProcessInstance pi : [
      SELECT Id, ProcessDefinition.Name
      FROM ProcessInstance
      WHERE ID IN :processIds
    ]) {
      if (
        pi.ProcessDefinition.Name.contains(
          'Pricing Review'
        ) /* || pi.ProcessDefinition.Name.contains('Pricing_Review')*/
      ) {
        pricingReviewIds.add(pi.Id);
      }
    }

    Map<Id, historyWrapper> m = new Map<Id, historyWrapper>();

    for (Approval_History__c ahc : ahList) {
      system.debug(ahc.Date_Acted__c);
      if (
        null != ahc.Deal__c &&
        pricingReviewIds.contains(ahc.Process_Instance_Id__c)
      ) {
        if (!m.containsKey(ahc.Deal__c)) {
          historyWrapper hwProto = new historyWrapper();
          m.put(ahc.Deal__c, hwProto);
        }
        historyWrapper hw = m.get(ahc.Deal__c);
        //hw.statusText = ahc.Status_Text__c;
        hw.oppName = ahc.Deal__r.Name;
        hw.oppOwner = ahc.Deal__r.Owner_Name__c;
        if (ahc.Deal__r.Loan_Size__c != null) {
          hw.oppLoanSize = ahc.Deal__r.Loan_Size__c.format();
        }
        hw.recordType = ahc.Deal__r.RecordType.DeveloperName;
        hw.loanType = ahc.Deal__r.Type;
        hw.productType = ahc.Deal__r.LOC_Loan_Type__c;
        hw.productSubType = ahc.Deal__r.Product_Sub_Type__c;
        hw.loanStage = ahc.Deal_Stage_At_Time_of_Submission__c;
        hw.pricingType = ahc.Deal__r.LOC_Program_Type__c;

        if (null != ahc.Process_Instance_Id__c && ahc.Status__c == 'Pending') {
          hw.approvalInstances.add(ahc.Process_Id__c);
          hw.approvalInstancesWrapper.add(
            new List<String>{ ahc.Process_Id__c, ahc.Status_Text__c }
          );
          hw.timeSinceSubmission = ahc.Time_in_Approval__c;
        }

        //hw.approvalInstanceStatus.add(ahc.Status_Text__c);
        if (null == m.get(ahc.Deal__c).lmd)
          hw.lmd = ahc.LastModifiedDate;
        else if (ahc.LastModifiedDate > hw.lmd)
          hw.lmd = ahc.LastModifiedDate;

        if (
          (ahc.Status__c == 'Submitted' ||
          ahc.Status__c == 'Re-submitted') &&
          null != ahc.Date_Acted__c &&
          null == hw.dateSubmitted
        ) {
          hw.dateSubmitted = ahc.Date_Acted__c;
          hw.dateSubmittedFormat = ahc.Date_Acted__c.format();
          hw.submissionStatus = ahc.Status__c;
        } else if (
          (ahc.Status__c == 'Submitted' ||
          ahc.Status__c == 'Re-submitted') &&
          null != ahc.Date_Acted__c &&
          ahc.Date_Acted__c > hw.dateSubmitted
        ) {
          hw.dateSubmitted = ahc.Date_Acted__c;
          hw.submissionStatus = ahc.Status__c;
        } else if (
          ahc.Status__c == 'Re-submitted – Post GLC' &&
          null != ahc.Date_Acted__c &&
          null == hw.dateSubmitted
        ) {
          hw.dateSubmitted = ahc.Date_Acted__c;
          hw.dateSubmittedFormat = ahc.Date_Acted__c.format();
          hw.submissionStatus = ahc.Status__c;
        }

        if (
          ahc.Status__c == 'Re-submitted' ||
          ahc.Status__c == 'Re-submitted – Post GLC'
        )
          hw.reSubmitted = true;
      } else {
        System.debug('this deal does not have Deal__c: ' + ahc.Id);
      }
    }

    if (m.size() > 0 && m.values().size() > 0) {
      return JSON.serialize(m, true);
    }
    return null;
  }

  public class returnWrapper {
    List<Approval_History__c> ahList;
    Boolean isSubmitter;
    String userRole;
    Id processId;
    List<ChatterCommentsWrapper> ChatterCommentsList;
  }

  public class ChatterCommentsWrapper {
    public String Name;
    public DateTime createdDate;
    public String user;
    public String Comments;
    public ChatterCommentsWrapper(
      String Name,
      DateTime createdDate,
      String user,
      String Comments
    ) {
      this.Name = Name;
      this.createdDate = createdDate;
      this.user = user;
      this.Comments = Comments;
    }
  }

  public class historyWrapper {
    List<String> approvalInstances;
    //List<String> approvalInstanceStatus;
    List<List<String>> approvalInstancesWrapper;
    Datetime lmd;
    Datetime dateSubmitted;
    String dateSubmittedFormat;
    String timeSinceSubmission;
    String oppName;
    String oppOwner;
    String oppLoanSize;
    String recordType;
    String loanType;
    String productType;
    String productSubType;
    String loanStage;
    String pricingType;
    // String status;
    String statusText;
    String submissionStatus;
    Boolean reSubmitted;
    Boolean verified;
    historyWrapper() {
      approvalInstances = new List<String>();
      //approvalInstanceStatus = new List<String>();
      approvalInstancesWrapper = new List<List<String>>();
    }
  }

  @AuraEnabled
  public static void approveDeal(
    Id recordId,
    String userRole,
    Id oppId,
    String comments,
    Opportunity opp,
    String approvalName
  ) {
    system.debug(userRole);
    system.debug(approvalName);
    // system.debug(JSON.serialize(opp));
    Opportunity updDeal = new Opportunity(
      Id = oppId,
      Final_Sponsor_Tier__c = 'Tier 1'
    );

    ApprovalAttachments_lightningController.approveDeal(
      recordId,
      userRole,
      oppId,
      comments,
      opp,
      approvalName
    );
  }

  @AuraEnabled
  public static void rejectDeal(
    Id recordId,
    Id oppId,
    String comments,
    String userRole
  ) {
    ApprovalAttachments_lightningController.rejectDeal(
      recordId,
      oppId,
      comments,
      userRole
    );
  }

  @AuraEnabled
  public static void submitGLCApproval(
    Id recordId,
    Id oppId,
    String comments,
    String userRole
  ) {
    ApprovalAttachments_lightningController.rejectDealForGLCApproval(
      recordId,
      oppId,
      comments,
      userRole
    );

    /*
        Opportunity opp = new Opportunity(Id= oppId, GLC_Approval_Comments__c = comments, Needs_GLC_Approval__c = true, GLC_Required__c=true);
        update opp;

        List<Approval_History__c> ahListInit = [
            SELECT Actor__c,Process_Id__c,Status__c,Comments__c,Parent_Status__c,Process_Instance_Id__c,Step_Item_Id__c
            FROM Approval_History__c
            WHERE Process_Id__c = :recordId
            LIMIT 1
        ];

        List<Approval_History__c> ahToUpdate = new List<Approval_History__c>();
        
        if(ahListInit.size() > 0){
            Approval_History__c ah = ahListInit[0];

            // List<Approval_History__c> otherAh = ;

            for(Approval_History__c otherAh : [
                    SELECT Actor__c,Process_Id__c,Status__c,Comments__c,Parent_Status__c,Process_Instance_Id__c,Step_Item_Id__c,Status_Text__c
                    FROM Approval_History__c
                    WHERE Process_Id__c != :recordId
                    AND Process_Instance_Id__c = :ah.Process_Instance_Id__c
                    AND Status__c = 'Pending'
            ]){
                otherAh.Status_Text__c = 'Rejected- Pending GLC approval';
                ahToUpdate.add(otherAh);
            }

            ah.Status_Text__c = 'Rejected- Pending GLC approval';
            ah.Approval_Type__c ='Submitted For GLC';
            // ah.Comments__c = comments;
            
            ahToUpdate.add(ah);

        }

        if(ahToUpdate.size() > 0){
            update ahToUpdate;
        }

        //query process

        // List<Approval_History__c> ahListInit = [
        //  SELECT Actor__c,Process_Id__c,Status__c,Comments__c,Parent_Status__c,Process_Instance_Id__c,Step_Item_Id__c
        //  FROM Approval_History__c
        //  WHERE Process_Id__c = :recordId
        //  LIMIT 1
        // ];
        // */
  }
}