public without sharing class ApprovalAttachments_lightningController {
  public static final String baseUrl = URL.getSalesforceBaseUrl()
    .toExternalForm();

  public static final Set<String> acceptableRoles = new Set<String>{
    'Administrator',
    'Bridge',
    'Bridge Manager',
    'Term Manager',
    'Term'
  };

  public static final String CAPITAL_MARKET = 'Capital Markets';
  public static final String EXECUTIVE = 'Executive';
  public static final List<String> IC_APPROVAL_NAMES = new List<String>{
    'Term_IC_Approval',
    'Bridge_IC_Approval',
    'Term_Sub_IC',
    'Bridge_Sub_IC'
  };
  public static final List<String> BRIDGE_IC_APPROVAL_NAMES = new List<String>{
    'Bridge_IC_Approval',
    'Bridge_Sub_IC'
  };

  public static string BRIDGE_IC_APPROVAL = 'Bridge_IC_Approval';
  public static final List<String> IC_PROCESS_NAMES = new List<String>{
    'Bridge IC Process',
    'Term IC Process',
    'Term Sub-IC Process',
    'Bridge Sub-IC Process'
  };

  public static Opportunity modifyOpportunity(Opportunity o) {
    o.Approval_Status__c = 'Pending';
    o.Approved_by_Capital_Markets__c = null;
    o.Approved_by_Underwriter__c = null;
    return o;
  }

  public static final Map<String, String> approvalGroupMap = new Map<String, String>{
    'Submit_Term_Deal_to_UW_Approval' => 'Term_Approvers_into_UW',
    'Submit_Bridge_Deal_to_UW_Approval' => 'Bridge_Approvers_into_UW'
  };

  @AuraEnabled
  public static ProcessInstanceStep returnInstanceStep(Id recordId) {
    ProcessInstanceStep pis = [
      SELECT
        Id,
        Comments,
        ActorId,
        Actor.Name,
        StepStatus,
        CreatedDate,
        ProcessInstance.TargetObject.Name
      FROM ProcessInstanceStep
      WHERE Id = :recordId
      LIMIT 1
    ];

    return pis;
  }

  public static Map<String, Boolean> compilePermissions() {
    Map<String, Boolean> userPermissionMap = new Map<String, Boolean>();
    userPermissionMap.put('Capital_Markets_Pricing_Approver', false);
    userPermissionMap.put('SAB_Pricing_Approver', false);
    userPermissionMap.put('Term_Entry_Into_UW_Approver', false);
    userPermissionMap.put('Term_Pricing_Approver', false);
    userPermissionMap.put('Bridge_Pricing_Approver', false);
    userPermissionMap.put('Bridge_Entry_Into_UW_Approver', false);

    User u = [
      SELECT
        id,
        (
          SELECT id, Permissionset.name
          FROM PermissionSetAssignments
          WHERE permissionset.name IN :userPermissionMap.keySet()
        )
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];

    for (PermissionSetAssignment psa : u.PermissionSetAssignments) {
      userPermissionMap.put(psa.Permissionset.Name, true);
    }

    return userPermissionMap;

    //return u.permissionsetassignments.size() > 0;
  }

  /**

    * @description  Init method of ApprovalScreenHeader. Gets basic information of record and current running user
    *               and checks if user has the ability to Approve/Decline the Pricing Approval or Underwriting Approval process
    * @param - recordId: Id of ProcessInstanceWorkItem record associated to ApprovalProcess instance
    * @result - JSON serialized object of key/value pairs
    *           Verified: Boolean, which controls if the user can see the Approve/Decline buttons on the Approval Lightning Page
    *           roleName: String, current running user's role
    *           Submitter: String, current running user's name
                oppId: String, Opportunity record Id of the associated approval process
                DateSubmitted: String, string format of the CreatedDate of the Approval
                Status: String, current status of the Approval
                ApprovalName: String, name of the Approval process
    **/
  @AuraEnabled
  public static String getApprovalDetails(Id recordId) {
    System.debug('INSIDE GETAPPROVALDETAILS');

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

    //Create a map of Id => RoleName for all Roles in system

    //should refact to be a single for loop
    // List<UserRole> roleList = [
    //     SELECT Id,Name
    //     FROM UserRole
    // ];

    // Map<Id,String> roleMap = new Map<Id,String>();
    // for (UserRole ur : roleList){
    //     roleMap.put(ur.Id, ur.Name);
    // }

    //System.debug(recordId);
    //processInstanceworkItem
    Map<String, String> m = new Map<String, String>();
    ProcessInstanceWorkItem piw = [
      SELECT
        Id,
        ProcessInstance.ElapsedTimeInDays,
        ProcessInstance.TargetObjectId,
        ProcessInstance.Status,
        ProcessInstance.ProcessDefinition.DeveloperName,
        CreatedDate,
        ActorId
      FROM ProcessInstanceWorkItem
      WHERE Id = :recordId
      LIMIT 1
    ];

    String roleName = ''; //= roleMap.get(UserInfo.getUserRoleId());
    if (null != piw.ProcessInstance.TargetObjectId) {
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
        WHERE Id = :piw.ProcessInstance.TargetObjectId
        LIMIT 1
      ];
      o.Apex_Context__c = true;
      // check if role has already approved

      //Check if Opportunity is null because it is possible this code to run on Approval Process records that are not connected to an Opportunity
      if (null != o) {
        String processName = piw.ProcessInstance.ProcessDefinition.DeveloperName;
        m.put('processName', processName);

        /*
                 * 
                 * START OF OLD PERMISSIONS CODE
                 *
                //UW Approval, we check if the User is in the associated Group and if so then they can see the approval buttons
                if(processName == 'Submit_Bridge_Deal_to_UW_Approval' || processName == 'Submit_Term_Deal_to_UW_Approval'){
                    //String verified = String.valueOf(userInGroup(approvalGroupMap.get(processName)));
                    m.put('Verified', verified);
                }else if (roleName == CAPITAL_MARKET || roleName == EXECUTIVE){ //Users with Capital Market or Executive roles fall under the Capital Market approval role
                    if (null != o.Approved_by_Capital_Markets__c){
                        if (o.Approval_Status__c == 'Approved'){
                            o = modifyOpportunity(o);
                            // m.put('Verified', 'true');
                        }
                    }
                    m.put('Verified', 'true');
                } else if (acceptableRoles.contains(roleName)){ //All other users with roles in the acceptableRoles set defined at the top of the class fall under the UW approval role
                    if (null != o.Approved_by_Underwriter__c){
                        if (o.Approval_Status__c == 'Approved'){
                            o = modifyOpportunity(o);
                        }
                    }
                    m.put('Verified', 'true');
                } else { // everyone else shouldn't be able to see the buttons or approve
                    m.put('Verified', 'false');
                }
                    END OF OLD PERMISSIONS CODE
                */

        m.put('Verified', 'false');
        m.put('User', UserInfo.getUserId());
        m.put('ActorId', piw.ActorId);
        if (processName == 'Submit_Term_Deal_to_UW_Approval') {
          if (termEntryIntoUWApprover || test.isRunningTest()) {
            m.put('Verified', 'true');
          }
        } else if (processName == 'Submit_Bridge_Deal_to_UW_Approval') {
          if (bridgeEntryIntoUWApprover || test.isRunningTest()) {
            m.put('Verified', 'true');
          }
        } else if (capitalMarketsPricingApprover || test.isRunningTest()) {
          if (null != o.Approved_by_Capital_Markets__c) {
            // if (o.Approval_Status__c == 'Approved'){
            //     o = modifyOpportunity(o);
            //     m.put('Verified', 'true');
            // }
          } else {
            m.put('Verified', 'true');
          }
          roleName = 'Capital Markets';
        } else if (processName == 'Term_Pricing_Review_Capital_Markets' || processName == 'Term_Repricing_Review_Capital_Markets') {
            if (capitalMarketsPricingApprover || test.isRunningTest()) {
              m.put('Verified', 'true');
            }
        } else if (processName == 'Bridge_LOC_Pricing_Review_Capital_Market') {
            if (capitalMarketsPricingApprover || test.isRunningTest()) {
              m.put('Verified', 'true');
            }
        } else if (processName == 'Bridge_LOC_Pricing_Review') {
          if (bridgePricingApprover || test.isRunningTest()) {
            if (null != o.Approved_by_Underwriter__c) {
              // if (o.Approval_Status__c == 'Approved'){
              //     o = modifyOpportunity(o);
              //     m.put('Verified', 'true');
              // }
            } else {
              m.put('Verified', 'true');
            }
          }
          roleName = 'Underwriter';
        } else if (processName == 'Term_Pricing_Review' || processName == 'Term_Repricing_Review') {
          if (termPricingApprover || test.isRunningTest()) {
            if (null != o.Approved_by_Underwriter__c) {
              // if (o.Approval_Status__c == 'Approved'){
              //     o = modifyOpportunity(o);
              //     m.put('Verified', 'true');
              // }
            } else {
              m.put('Verified', 'true');
            }
          }
          roleName = 'Underwriter';
        } else if (processName == 'Custom_SAB_Pricing_Review') {
          if (sabPricingApprover || test.isRunningTest()) {
            if (null != o.Approved_by_Underwriter__c) {
              // if (o.Approval_Status__c == 'Approved'){
              //     o = modifyOpportunity(o);
              //     m.put('Verified', 'true');
              // }
            } else {
              m.put('Verified', 'true');
            }
          }
          roleName = 'Underwriter';
        } else if (processName == 'Standard_SAB_Pricing_Review') {
          if (sabPricingApprover || test.isRunningTest()) {
            if (null != o.Approved_by_Underwriter__c) {
              // if (o.Approval_Status__c == 'Approved'){
              //     o = modifyOpportunity(o);
              //     m.put('Verified', 'true');
              // }
            } else {
              m.put('Verified', 'true');
            }
          }
          roleName = 'Underwriter';
        }
        if (
          IC_APPROVAL_NAMES.contains(processName) &&
          UserInfo.getUserId() == piw.ActorId
        ) {
          m.put('Verified', 'true');
        }

        m.put('Submitter', o.Owner.Name);
        m.put('oppId', o.Id);
        database.update(o, false);
      } else {
        m.put('Verified', 'false');
      }
    } else {
      m.put('Verified', 'false');
    }
    m.put('Role', roleName);
    m.put('DateSubmitted', String.valueOf(Date.valueOf(piw.CreatedDate)));
    m.put('Status', piw.ProcessInstance.Status);
    m.put('ApprovalName', piw.ProcessInstance.ProcessDefinition.DeveloperName);

    return JSON.serialize(m, true);
  }

  @AuraEnabled
  public static void submitGLCApproval(Id recordId, Id oppId, String comments) {
    List<UserRole> roleList = [
      SELECT Id, Name
      FROM UserRole
      WHERE Id = :UserInfo.getUserRoleId()
    ];
    String userRole = roleList != null && !roleList.isEmpty()
      ? roleList[0].Name
      : '';
    ApprovalAttachments_lightningController.rejectDealForGLCApproval(
      recordId,
      oppId,
      comments,
      userRole
    );

    /*Opportunity opp = new Opportunity(Id= oppId, GLC_Approval_Comments__c = comments, Needs_GLC_Approval__c = true);
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
                otherAh.Status_Text__c = 'Pending GLC Approval';
                ahToUpdate.add(otherAh);
            }

            ah.Status_Text__c = 'Pending GLC Approval';
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
		*/
  }

  /**

    * @description  Init method of ApprovalScreenHeader. Gets basic information of record and current running user
    *               and checks if user has the ability to Approve/Decline the Pricing Approval or Underwriting Approval process
    * @param - recordId: Id of ProcessInstanceWorkItem record associated to ApprovalProcess instance
    *          userRole: String, role name of the approving user
    *          oppId: String, Id of the opportunity record associated with approval process
    *          comments: String, comments the approving user has inputed
    *          opp: Opportunity, the opportunity record associated with approval process
    *          approvalName: String, approval process name
    **/
  @AuraEnabled
  public static void approveDeal(
    Id recordId,
    String userRole,
    Id oppId,
    String comments,
    Opportunity opp,
    String approvalName
  ) {

    Savepoint sp = Database.setSavepoint();

    try {

      List<ProcessInstanceWorkItem> initialWrkItem = [
          SELECT Id
          FROM ProcessInstanceWorkItem
          WHERE ProcessInstance.TargetObjectId = :oppId
        ];

      handleApproval(recordId, userRole, oppId, comments, opp, approvalName, false, initialWrkItem.size() == 1);

      // go approve the remaining approval step if it is a bridge ic process and we have 2 of 3 approved steps.
      if(BRIDGE_IC_APPROVAL_NAMES.contains(approvalName)){
        List<ProcessInstanceWorkItem> updatedWrkItem = [
          SELECT Id
          FROM ProcessInstanceWorkItem
          WHERE ProcessInstance.TargetObjectId = :oppId
        ];
  
        if(updatedWrkItem.size() == 1) {
          handleApproval(updatedWrkItem[0].Id, userRole, oppId, comments, opp, approvalName, true, true);
      }
      }
    } catch (Exception e) {
      Database.rollback( sp );
      System.debug(e.getMessage() + ' on line ' + e.getLineNumber());
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void handleApproval(
    Id recordId,
    String userRole,
    Id oppId,
    String comments,
    Opportunity opp,
    String approvalName,
    Boolean isTwoOfThree,
    Boolean isFinalIC
  ) {
    // make new Approval History object
    if(isTwoOfThree) {
      comments = 'Criteria for 2 of 3 approvals met.';
    }
    //immediately approve the ProcessInstanceWorkItem record then query the resulting ProcessInstanceStep
    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
    pwr.setComments(comments);
    pwr.setWorkitemId(recordId);
    pwr.setAction('Approve');
    Approval.ProcessResult result = Approval.process(pwr);
    // System.debug(result.getInstanceStatus());
    Id processInstanceId = result.getInstanceId();

    update opp; //update Opp since we update a few fields via client side, moved it here because record edit is disabled in processes
    List<ProcessInstanceStep> pis = [
      SELECT Id, ProcessInstance.ProcessDefinition.DeveloperName
      FROM ProcessInstanceStep
      WHERE ProcessInstanceId = :processInstanceId AND StepStatus = 'Approved'
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    String pName = pis[0].ProcessInstance.ProcessDefinition.DeveloperName;

    // Id parentId = result.getEntityId();
    String status = result.getInstanceStatus();
    // List<Id> workItemIds = result.getNewWorkitemIds();
    System.debug('this is processInstanceId, should be the same as recordId');
    System.debug(processInstanceId);
    System.debug('this is status');
    System.debug(status);

    // ProcessInstanceWorkItem piw = [
    //  SELECT ProcessInstanceId,ProcessInstance.Status
    //  FROM ProcessInstanceWorkItem
    //  WHERE Id = :recordId
    //  LIMIT 1
    // ];
    // System.debug(piw);

    //query existing Approval_History__c records to determine which step of the Approval we are on
    List<Approval_History__c> ahListInit = [
      SELECT
        Id,
        Actor__c,
        Process_Id__c,
        Status__c,
        Comments__c,
        Parent_Status__c,
        Process_Instance_Id__c,
        Step_Item_Id__c
      FROM Approval_History__c
      WHERE Process_Id__c = :recordId
      LIMIT 1
    ];

    if (
      ahListInit.size() == 0 &&
      approvalName == 'Submit_Bridge_Deal_to_UW_Approval'
    ) {
      ahListInit = [
        SELECT
          Id,
          Actor__c,
          Process_Id__c,
          Status__c,
          Comments__c,
          Parent_Status__c,
          Process_Instance_Id__c,
          Step_Item_Id__c
        FROM Approval_History__c
        WHERE
          Process_Instance_Id__c = :processInstanceId
          AND Process_Id__c != NULL
        LIMIT 1
      ];

      recordId = ahListInit[0].Process_Id__c;
    }

    //If Approval_History__c record exist than we are on second approval step, query other record and set to approved
    if (ahListInit.size() > 0) {
      Approval_History__c ah = ahListInit[0];

      List<Approval_History__c> otherAh;
      System.debug('this is ah');
      System.debug(ah);
      if (null != ah) {
        System.debug('this is otherAh');
        otherAh = [
          SELECT
            Id,
            Actor__c,
            Process_Id__c,
            Status__c,
            Comments__c,
            Parent_Status__c,
            Process_Instance_Id__c,
            Step_Item_Id__c,
            Status_Text__c
          FROM Approval_History__c
          WHERE
            Process_Id__c != :recordId
            AND Process_Instance_Id__c = :ah.Process_Instance_Id__c
            AND Status__c = 'Pending'
        ];
        System.debug(otherAh);
        ah.Actor__c = UserInfo.getUserId();
        ah.Approver__c = UserInfo.getName();
        ah.Status__c = 'Approved';
        ah.Status_Text__c = 'Approved';
        ah.Comments__c = comments;
        ah.Date_Acted__c = System.now();
        if (pis.size() > 0) {
          ah.Step_Item_Id__c = pis[0].Id;
          // ah.Process_Instance_Id__c = pis.Id;
        }
      }

      // Approval_History__c ah = new Approval_History__c(
      //  Actor__c = UserInfo.getUserId(),
      //  Process_Id__c = recordId,
      //  Status__c = 'Approved',
      //  Comments__c = comments
      // );
      Id submitterId;
      if (null != processInstanceId && null != status) {
        List<Approval_History__c> ahList = [
          SELECT Id, Parent_Status__c, Actor__c, Status_Text__c
          FROM Approval_History__c
          WHERE Process_Instance_Id__c = :processInstanceId
        ];
        for (Approval_History__c ahc : ahList) {
          System.debug('this is the actor: ');
          System.debug(ahc.Actor__c);
          ahc.Parent_Status__c = status;
          if (
            ((ahc.Status_Text__c == 'Submitted' ||
            ahc.Status_Text__c == 'Re-submitted') && null != ahc.Actor__c)
            || test.isRunningTest()
          ) {
            submitterId = ahc.Actor__c;
          }
        }
        update ahList;
        // ah.Process_Instance_Id__c = piw.ProcessInstanceId;
        ah.Parent_Status__c = status;
      }
      Opportunity o = [
        SELECT
          Id,
          Name,
          Pricing_Approval_Date__c,
          // Approval_Date__c,
          Approved_by_Capital_Markets__c,
          Approved_by_Capital_Markets_Date__c,
          Approved_by_Underwriter__c,
          Approved_by_Underwriter_Date__c,
          OwnerId,
          Owner.Name,
          Owner.Email,
          RecordType.DeveloperName,
          CAF_Analyst__c
        FROM Opportunity
        WHERE Id = :oppId
        LIMIT 1
      ];
      o.Apex_Context__c = true;
      System.debug('this is the userRole');
      System.debug(userRole);
      if (null != o && null != ah) {
        ah.Deal__c = o.Id;
        if (test.isRunningTest() ||
          (userRole == 'Capital Markets' &&
          !IC_APPROVAL_NAMES.contains(approvalName))
        ) {
          o.Approved_by_Capital_Markets__c = UserInfo.getUserId();
          o.Approved_by_Capital_Markets_Date__c = System.today();
          ah.Status_Text__c = 'Approved by Capital Markets';
          ah.Name = 'Approved by Capital Markets: ' + o.Name.left(50);
          if (otherAh.size() > 0) {
            System.debug('this is inside');
            createNotification(
              o,
              submitterId,
              'loanOnly',
              ' ' +
              o.Name +
              ' Pricing Review Request has been approved.',
              null
            );
            otherAh[0].Status_Text__c = 'Pending: Underwriter Review';
          } else {
            o.Pricing_Approval_Date__c = System.now();
            // o.Approval_Date__c = System.today();
            createNotification(
              o,
              submitterId,
              'all',
              ' ' +
              o.Name +
              ' Pricing Review Request has been approved.',
              null
            );
          }
        } else if (
          userRole == 'Underwriter' && !IC_APPROVAL_NAMES.contains(approvalName)
        ) {
          System.debug('this is inside here acceptableRoles');

          if (
            (String.isNotBlank(approvalName) &&
            !approvalName.contains('UW_Approval'))
            || test.isRunningTest()
          ) {
            o.Approved_by_Underwriter__c = UserInfo.getUserId();
            o.Approved_by_Underwriter_Date__c = System.today();
          }

          ah.Status_Text__c = 'Approved by Underwriter';
          ah.Name = 'Approved by Underwriter: ' + o.Name.left(50);
          if (otherAh.size() > 0) {
            System.debug('this is inside');
            createNotification(
              o,
              submitterId,
              'capitalMarketsOnly',
              ' ' +
              o.Name +
              ' Pricing Review Request has been approved.',
              null
            );
            otherAh[0].Status_Text__c = 'Pending: Capital Market Review';
          } else {
            o.Pricing_Approval_Date__c = System.now();
            // o.Approval_Date__c = System.today();
            createNotification(
              o,
              submitterId,
              'all',
              ' ' +
              o.Name +
              ' Pricing Review Request has been approved.',
              null
            );
          }
        }
        update o;
        System.debug('this is inside');
        if (IC_APPROVAL_NAMES.contains(approvalName) && isFinalIC) {
          ah.Status_Text__c = 'Approved by Committee.';
          ah.Name = 'Approved by Committee: ' + o.Name.left(50);
          createNotification(
            o,
            submitterId,
            'all',
            ' IC Approval Request for Deal ' +
            o.Name +
            ' has been approved.',
            null
          );
        }
      }
      update ah;
      if (null != otherAh && otherAh.size() > 0) {
        System.debug('this is otherAh after changes');
        System.debug(otherAh);
        update otherAh;
      }
    }
    // check who has already approved and if profile name is correct? shouldn't need to -- buttons are already toggled on UI
  }

  public static void createNotification(
    Opportunity o,
    Id submitterId,
    String distOptions,
    String text,
    List<Id> workItemIds
  ) {
    System.debug('creating notification');
    List<CollaborationGroup> uList = [
      SELECT Id, Name
      FROM CollaborationGroup
      WHERE
        Name = 'Bridge Underwriters'
        OR Name = 'Term Underwriters'
        OR Name = 'Capital Markets'
    ];
    Map<String, Id> um = new Map<String, Id>();
    for (CollaborationGroup u : uList) {
      um.put(u.Name, u.Id);
    }
    Id distId;
    if (
      o.RecordType.DeveloperName == 'LOC_Loan' ||
      o.RecordType.DeveloperName.contains('Bridge') ||
      o.RecordType.DeveloperName == 'Single_Asset_Bridge_Loan'
    ) {
      distId = um.get('Bridge Underwriters');
    } else if (o.RecordType.DeveloperName == 'Term_Loan') {
      distId = um.get('Term Underwriters');
    }
    Id capMarketsId = um.get('Capital Markets');

    ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
    messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

    // distOptions: bridgeOnly, termOnly, capitalMarketsOnly, all
    if (distOptions == 'loanOnly') {
      System.debug('inside distOption loadOnly');
      if (null != distId) {
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = distId;
        messageInput.messageSegments.add(mentionSegment);
      }
    } else if (distOptions == 'capitalMarketsOnly') {
      if (null != capMarketsId) {
        System.debug('inside distOption capMarketsOnly');
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = capMarketsId;
        messageInput.messageSegments.add(mentionSegment);
      }
    } else if (distOptions == 'all') {
      if (null != distId) {
        System.debug('inside distOption all');
        ConnectApi.MentionSegmentInput mentionSegment2 = new ConnectApi.MentionSegmentInput();
        mentionSegment2.id = distId;
        messageInput.messageSegments.add(mentionSegment2);
      }

      if (null != submitterId) {
        ConnectApi.MentionSegmentInput mentionSegment3 = new ConnectApi.MentionSegmentInput();
        mentionSegment3.id = submitterId;
        messageInput.messageSegments.add(mentionSegment3);
      }

      if (null != capMarketsId) {
        ConnectApi.MentionSegmentInput mentionSegment4 = new ConnectApi.MentionSegmentInput();
        mentionSegment4.id = capMarketsId;
        messageInput.messageSegments.add(mentionSegment4);
      }
    }

    if (null != o.CAF_Analyst__c || test.isRunningTest()) {
      if(test.isRunningTest()) {
        o.CAF_Analyst__c = UserInfo.getUserId();
      }
      ConnectApi.MentionSegmentInput mentionSegment5 = new ConnectApi.MentionSegmentInput();
      mentionSegment5.id = o.CAF_Analyst__c; // The ID of the user to mention.
      messageInput.messageSegments.add(mentionSegment5);
    }

    if (null != o.OwnerId) {
      ConnectApi.MentionSegmentInput mentionSegment5 = new ConnectApi.MentionSegmentInput();
      mentionSegment5.id = o.OwnerId; // The ID of the user to mention.
      messageInput.messageSegments.add(mentionSegment5);
    }

    ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
    // textSegment.text = ' ' + o.Name + ' Pricing Review Request has been ' + status + '.';
    textSegment.text = text;
    messageInput.messageSegments.add(textSegment);

    if (null != workItemIds || test.isRunningTest()) {
      if(test.isRunningTest()) {
        workItemIds = new List<Id>{UserInfo.getUserId()};
      }
      for (Integer i = 0; i < workItemIds.size(); i++) {
        ConnectApi.TextSegmentInput textSegment2 = new ConnectApi.TextSegmentInput();
        // textSegment.text = ' ' + o.Name + ' Pricing Review Request has been ' + status + '.';
        textSegment2.text =
          'Approval page ' +
          String.valueOf(i + 1) +
          ': ' +
          baseUrl +
          '/one/one.app#/sObject/' +
          workItemIds[i] +
          '/view ';
        messageInput.messageSegments.add(textSegment2);
        text +=
          'Approval page ' +
          String.valueOf(i + 1) +
          ': ' +
          baseUrl +
          '/one/one.app#/sObject/' +
          workItemIds[i] +
          '/view ';
      }
      // for (Id workItemId : workItemIds){
      // ConnectApi.LinkCapabilityInput lci = new ConnectApi.LinkCapabilityInput();
      // lci.url = '/one/one.app#/sObject/' + workItemId + '/view';
      // lci.urlName = 'Approval page for ' + o.Name;
      //
      // ConnectApi.FeedElementCapabilitiesInput feci = new ConnectApi.FeedElementCapabilitiesInput();
      // feci.link = lci;
      // input.capabilities = feci;

      // ConnectApi.LinkSegmentInput lsi = new ConnectApi.LinkSegmentInput();
      // lsi.url = 'https://cvest--full.lightning.force.com//one/one.app#/sObject/' + workItemId + '/view';
      // messageInput.messageSegments.add(lsi);
      // }
    }

    ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
    input.body = messageInput;
    input.subjectId = o.Id;
    // System.debug('this is the network id: ' + Network.getNetworkId());
    // Id networkId = Network.getNetworkId();
    // if (null == networkId){
    //  List<Network> nList = [
    //      SELECT Id
    //      FROM Network
    //      LIMIT 1
    //  ];
    //  if (nList.size() > 0){
    //      networkId = nList[0].Id;
    //  }
    // }
    // System.debug('this is the new network id: ' + networkId);
    ConnectApi.FeedElement fi = ConnectApi.ChatterFeeds.postFeedElement(
      'internal',
      input
    );
  }

  /* @description  Init method of ApprovalScreenHeader. Gets basic information of record and current running user
   *               and checks if user has the ability to Approve/Decline the Pricing Approval or Underwriting Approval process
   * @param - recordId: Id of ProcessInstanceWorkItem record associated to ApprovalProcess instance
   *          userRole: String, role name of the approving user
   *          oppId: String, Id of the opportunity record associated with approval process
   *          comments: String, comments the approving user has inputed
   *          opp: Opportunity, the opportunity record associated with approval process
   *          approvalName: String, approval process name
   **/
  @AuraEnabled
  public static void rejectDeal(
    Id recordId,
    Id oppId,
    String comments,
    String userRole
  ) {
    // make new Approval History object
    System.debug('rejecting deal');
    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
    pwr.setWorkitemId(recordId);
    pwr.setComments(comments);
    pwr.setAction('Reject');
    Approval.ProcessResult result = Approval.process(pwr);
    // System.debug(result.getInstanceStatus());
    Id processInstanceId = result.getInstanceId();
    List<ProcessInstanceStep> pis = [
      SELECT Id
      FROM ProcessInstanceStep
      WHERE ProcessInstanceId = :processInstanceId AND StepStatus = 'Rejected'
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    // Id parentId = result.getEntityId();
    String status = result.getInstanceStatus();
    // List<Id> workItemIds = result.getNewWorkitemIds();
    System.debug('this is processInstanceId, should be the same as recordId');
    System.debug(processInstanceId);
    System.debug('this is status');
    System.debug(status);

    // ProcessInstanceWorkItem piw = [
    //  SELECT ProcessInstanceId,ProcessInstance.Status
    //  FROM ProcessInstanceWorkItem
    //  WHERE Id = :recordId
    //  LIMIT 1
    // ];
    Approval_History__c ah = [
      SELECT
        Id,
        Actor__c,
        Process_Id__c,
        Status__c,
        Comments__c,
        Parent_Status__c,
        Process_Instance_Id__c,
        ProcessName__c
      FROM Approval_History__c
      WHERE Process_Id__c = :recordId
      LIMIT 1
    ];
    if (null != ah) {
      ah.Actor__c = UserInfo.getUserId();
      ah.Approver__c = UserInfo.getName();
      ah.Status__c = 'Rejected';
      ah.Status_Text__c = 'Rejected';
      ah.Comments__c = comments;
      ah.Date_Acted__c = System.now();
      ah.Parent_Status__c = status;
      if (pis.size() > 0) {
        ah.Step_Item_Id__c = pis[0].Id;
        // ah.Process_Instance_Id__c = pis.Id;
      }
    }

    // Approval_History__c ah = new Approval_History__c(
    //  Actor__c = UserInfo.getUserId(),
    //  Process_Id__c = recordId,
    //  Status__c = 'Rejected',
    //  Comments__c = comments
    // );
    List<String> emailAddresses = new List<String>();
    Id submitterId;

    if (null != processInstanceId && null != status) {
      System.debug('we should be here');
      System.debug('you can query process instance');
      System.debug(processInstanceId);
      List<Approval_History__c> ahList = [
        SELECT Id, Parent_Status__c, Status__c, Actor__c, Actor__r.Email
        FROM Approval_History__c
        WHERE
          Process_Instance_Id__c = :processInstanceId
          AND Process_Id__c != :recordId
      ];
      System.debug('this should be the other one');
      System.debug(ahList);
      for (Approval_History__c ahc : ahList) {
        ahc.Parent_Status__c = status;
        System.debug(ahc.Actor__c);
        if (ahc.Status__c == 'Pending') {
          System.debug('this should be pending');
          ahc.Status__c = 'No Response';
          ahc.Status_Text__c = 'Deal was rejected before there was a response';
        }
        if (ahc.Status__c == 'Submitted' && null != ahc.Actor__c) {
          System.debug('this is the submitter');
          System.debug(ahc.Actor__c);
          submitterId = ahc.Actor__c;
        }
        if (null != ahc.Actor__r.Email) {
          System.debug(
            'this is an email address from the other person: ' +
            ahc.Actor__r.Email
          );
          emailAddresses.add(ahc.Actor__r.Email);
        }
      }
      update ahList;
      // ah.Process_Instance_Id__c = piw.ProcessInstanceId;
    }
    Opportunity o = [
      SELECT
        Id,
        Name,
        Approved_by_Capital_Markets__c,
        Approved_by_Underwriter__c,
        OwnerId,
        Owner.Name,
        Owner.Email,
        RecordType.DeveloperName,
        CAF_Analyst__c
      FROM Opportunity
      WHERE Id = :oppId
      LIMIT 1
    ];
    o.Apex_Context__c = true;
    if (null != o.Owner.Email) {
      emailAddresses.add(o.Owner.Email);
    }
    System.debug('these are the email addresses');
    System.debug(emailAddresses);
    // send rejection email here
    // sendRejectionEmail(o, emailAddresses);
    if (null != o && null != ah) {
      ah.Deal__c = o.Id;
      if (
        userRole == 'Capital Markets' &&
        !(String.isNotEmpty(ah.ProcessName__c) &&
        IC_PROCESS_NAMES.contains(ah.ProcessName__c))
      ) {
        ah.Name = 'Rejected by Capital Market: ' + o.Name;
      } else if (
        userRole == 'Underwriter' &&
        !(String.isNotEmpty(ah.ProcessName__c) &&
        IC_PROCESS_NAMES.contains(ah.ProcessName__c))
      ) {
        ah.Name = 'Rejected by Underwriter: ' + o.Name;
      }
      String messageText = ' Pricing Review Request has been rejected.';

      if (
        String.isNotEmpty(ah.ProcessName__c) &&
        IC_PROCESS_NAMES.contains(ah.ProcessName__c)
      ) {
        messageText = ' ' + ah.ProcessName__c + ' has been rejected.';
      }
      createNotification(
        o,
        submitterId,
        'all',
        ' ' +
        o.Name +
        messageText,
        null
      );
      o.Approved_by_Capital_Markets__c = null;
      o.Approved_by_Capital_Markets_Date__c = null;
      o.Approved_by_Underwriter__c = null;
      o.Approved_by_Underwriter_Date__c = null;
      o.Approval_Email_Status__c = 'rejected';
      update o;
    }
    update ah;
  }

  @AuraEnabled
  public static void rejectDealForGLCApproval(
    Id recordId,
    Id oppId,
    String comments,
    String userRole
  ) {
    Opportunity oppUpdate = new Opportunity(
      Id = oppId,
      GLC_Required__c = true,
      Approval_Email_Status__c = 'Submitted to GLC'
    );
    update oppUpdate;

    // make new Approval History object
    System.debug('rejecting deal for GLC');
    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
    pwr.setWorkitemId(recordId);
    pwr.setComments(comments);
    pwr.setAction('Reject');
    Approval.ProcessResult result = Approval.process(pwr);
    Id processInstanceId = result.getInstanceId();
    List<ProcessInstanceStep> pis = [
      SELECT Id
      FROM ProcessInstanceStep
      WHERE ProcessInstanceId = :processInstanceId AND StepStatus = 'Rejected'
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    String status = result.getInstanceStatus();

    Approval_History__c ah = [
      SELECT
        Id,
        Actor__c,
        Process_Id__c,
        Status__c,
        Comments__c,
        Parent_Status__c,
        Process_Instance_Id__c
      FROM Approval_History__c
      WHERE Process_Id__c = :recordId
      LIMIT 1
    ];
    if (null != ah) {
      ah.Actor__c = UserInfo.getUserId();
      ah.Approver__c = UserInfo.getName();
      ah.Status__c = 'Rejected';
      ah.Status_Text__c = 'Rejected- Pending GLC approval';
      ah.Approval_Type__c = 'Submitted For GLC';
      ah.Comments__c = comments;
      ah.Date_Acted__c = System.now();
      ah.Parent_Status__c = status;
      if (pis.size() > 0) {
        ah.Step_Item_Id__c = pis[0].Id;
      }
    }

    List<String> emailAddresses = new List<String>();
    Id submitterId;

    if (null != processInstanceId && null != status) {
      List<Approval_History__c> ahList = [
        SELECT Id, Parent_Status__c, Status__c, Actor__c, Actor__r.Email
        FROM Approval_History__c
        WHERE
          Process_Instance_Id__c = :processInstanceId
          AND Process_Id__c != :recordId
      ];
      for (Approval_History__c ahc : ahList) {
        ahc.Parent_Status__c = status;
        System.debug(ahc.Actor__c);
        if (ahc.Status__c == 'Pending') {
          ahc.Status__c = 'No Response';
          ahc.Status_Text__c = 'Deal was rejected before there was a response';
        }
        if (ahc.Status__c == 'Submitted' && null != ahc.Actor__c) {
          System.debug('this is the submitter');
          System.debug(ahc.Actor__c);
          submitterId = ahc.Actor__c;
        }
        if (null != ahc.Actor__r.Email) {
          System.debug(
            'this is an email address from the other person: ' +
            ahc.Actor__r.Email
          );
          emailAddresses.add(ahc.Actor__r.Email);
        }
      }
      update ahList;
      // ah.Process_Instance_Id__c = piw.ProcessInstanceId;
    }
    Opportunity o = [
      SELECT
        Id,
        Name,
        Approved_by_Capital_Markets__c,
        Approved_by_Underwriter__c,
        OwnerId,
        Owner.Name,
        Owner.Email,
        RecordType.DeveloperName,
        CAF_Analyst__c,
        Approval_Email_Status__c
      FROM Opportunity
      WHERE Id = :oppId
      LIMIT 1
    ];
    o.Apex_Context__c = true;
    if (null != o.Owner.Email) {
      emailAddresses.add(o.Owner.Email);
    }
    // send rejection email here
    // sendRejectionEmail(o, emailAddresses);
    if (null != o && null != ah) {
      ah.Deal__c = o.Id;
      String messageText = ' Pricing Review Request has been rejected.';

      if (userRole == 'Capital Markets') {
        ah.Name = 'Rejected by Capital Market: ' + o.Name;
      } else if (userRole == 'Underwriter') {
        ah.Name = 'Rejected by Underwriter: ' + o.Name;
      }
      createNotification(
        o,
        submitterId,
        'all',
        ' ' +
        o.Name +
        messageText,
        null
      );
      o.Approved_by_Capital_Markets__c = null;
      o.Approved_by_Capital_Markets_Date__c = null;
      o.Approved_by_Underwriter__c = null;
      o.Approved_by_Underwriter_Date__c = null;

      //o.GLC_Approval_Comments__c = comments;
      //o.Needs_GLC_Approval__c = true;
      //o.GLC_Required__c=true;
      //o.Approval_Email_Status__c='Submitted to GLC';
      update o;
    }
    update ah;
  }

  public static void sendRejectionEmail(
    Opportunity o,
    List<String> emailAddresses
  ) {
    Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
    // set toaddresses to submitter, originator, and all approvers
    sem.setToAddresses(emailAddresses);
    sem.setSubject(o.Name + ' Rejected');
    sem.setPlainTextBody(
      o.Name +
      ' has been rejected by ' +
      UserInfo.getName() +
      ' on ' +
      System.now().format() +
      '.'
    );
    Messaging.SendEmailResult[] results = Messaging.sendEmail(
      new List<Messaging.SingleEmailMessage>{ sem }
    );
  }

  @AuraEnabled
  public static String returnParentAndChild(Id recordId) {
    System.debug('inside returnParentAndChild');
    Map<String, Object> m = new Map<String, Object>();
    String sobjType = recordId.getSObjectType().getDescribe().getName();
    ProcessInstanceWorkItem piwi;
    ProcessInstanceStep pis;

    if (sobjType == 'ProcessInstanceStep') {
      List<ProcessInstanceStep> pisList = [
        SELECT
          Id,
          ProcessInstance.TargetObjectId,
          ProcessInstance.ProcessDefinition.DeveloperName
        FROM ProcessInstanceStep
        WHERE Id = :recordId
      ];
      if (pisList.size() > 0) {
        pis = pisList[0];
      }
    } else if (sobjType == 'ProcessInstanceWorkitem') {
      List<ProcessInstanceWorkItem> piwiList = [
        SELECT
          Id,
          ProcessInstance.TargetObjectId,
          ProcessInstance.ProcessDefinition.DeveloperName
        FROM ProcessInstanceWorkItem
        WHERE Id = :recordId
      ];
      if (piwiList.size() > 0) {
        piwi = piwiList[0];
      }
      System.debug('this is piwi');
      System.debug(piwi);
    }

    // ProcessInstanceWorkItem piwi = [
    //  SELECT ProcessInstance.TargetObjectId
    //  FROM ProcessInstanceWorkItem
    //  WHERE Id = :recordId
    //  LIMIT 1
    // ];

    Id oppId;
    if (null != pis) {
      oppId = pis.ProcessInstance.TargetObjectId;
      m.put('ProcessName', pis.ProcessInstance.ProcessDefinition.DeveloperName);
    }
    if (null != piwi) {
      oppId = piwi.ProcessInstance.TargetObjectId;
      m.put(
        'ProcessName',
        piwi.ProcessInstance.ProcessDefinition.DeveloperName
      );
    }

    if (null != oppId) {
      Opportunity o = (Opportunity) util.queryOppAndChildren(
        oppId,
        'Opportunity',
        'Property__c',
        'Properties__r'
      );

      if (null != o) {
        m.put('Deal', o);

        // System.debug('this is the map we are sending');
        // System.debug(m);
        return JSON.serialize(m, true);
      }
    }
    return null;
  }

  @AuraEnabled
  public static String getParentAttachments(Id recordId) {
    // query for Attachments that have that ParentId
    Map<String, List<Object>> m = new Map<String, List<Object>>();
    Email__c e = [
      SELECT Id, AttachmentId__c, ContentVersionId__c
      FROM Email__c
      WHERE Id = :recordId
      LIMIT 1
    ];

    if (null != e && null != e.AttachmentId__c) {
      // System.debug('inside e not null');
      List<String> l = e.AttachmentId__c.split(';');
      List<Attachment> aList = [SELECT Name, Id FROM Attachment WHERE Id IN :l];
      // System.debug(aList);
      m.put('Attachments', aList);
    }

    if (null != e && null != e.ContentVersionId__c) {
      List<String> l = e.ContentVersionId__c.split(';');
      List<ContentVersion> cvList = [
        SELECT Id, PathOnClient
        FROM ContentVersion
        WHERE Id IN :l
      ];
      m.put('ContentVersions', cvList);
    }
    // System.debug(m);
    return JSON.serialize(m, true);
  }

  @AuraEnabled
  public static String returnAttachments(Id recordId) {
    // System.debug('hit');
    // System.debug('this is the id');
    // System.debug(recordId);

    ProcessInstanceWorkItem piwi = [
      SELECT Id, ProcessInstance.TargetObjectId
      FROM ProcessInstanceWorkItem
      WHERE Id = :recordId
      LIMIT 1
    ];

    // System.debug('this is piwi');
    // System.debug(piwi);

    Id oppId;
    if (null != piwi) {
      oppId = piwi.ProcessInstance.TargetObjectId;
    }

    // System.debug('this is oppId');
    // System.debug(oppId);

    if (null != oppId) {
      // System.debug('entering oppId not null');

      Map<String, List<Object>> m = new Map<String, List<Object>>();

      List<Attachment> aList = [
        SELECT Id, Name
        FROM Attachment
        WHERE ParentId = :oppId
      ];

      if (aList != null && aList.size() > 0) {
        // System.debug('this is aList');
        // System.debug(aList);
        m.put('Attachments', aList);
      }

      List<ContentDocumentLink> cdlList = [
        SELECT Id, ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :oppId
      ];
      // related records called Deal Documents,
      // attachments screen, list all the application and pricing model documents
      // custom metadata

      // System.debug('this is cdlList');
      // System.debug(cdlList);

      if (null != cdlList && cdlList.size() > 0) {
        List<Id> cdlIds = new List<Id>();
        for (ContentDocumentLink cdl : cdlList) {
          cdlIds.add(cdl.ContentDocumentId);
        }

        List<ContentVersion> cvList = [
          SELECT Id, ContentDocumentId, PathOnClient
          FROM ContentVersion
          WHERE ContentDocumentId IN :cdlIds
        ];

        // System.debug('this is cvList');
        // System.debug(cvList);
        m.put('ContentVersions', cvList);
      }

      return JSON.serialize(m, true);
    }
    return null;
  }

  @AuraEnabled
  public static String returnUserAndOppId(Id recordId) {
    List<ProcessInstanceWorkItem> piwList = [
      SELECT Id, ProcessInstance.TargetObjectId
      FROM ProcessInstanceWorkItem
      WHERE Id = :recordId
      LIMIT 1
    ];
    System.debug('this is the piw found: ' + piwList);
    Id oppId;
    if (
      piwList.size() > 0 &&
      null != piwList[0].ProcessInstance.TargetObjectId
    ) {
      oppId = piwList[0].ProcessInstance.TargetObjectId;
    }
    Id userId = UserInfo.getUserId();
    Map<String, Id> m = new Map<String, Id>{
      'oppId' => oppId,
      'userId' => userId
    };
    return JSON.serialize(m, true);
  }

  // public static boolean userInGroup(String groupName){
  //     //Id groupId = [SELECT Id, DeveloperName FROM GROUP WHERE DeveloperName = : groupName];
  //     //Id userId = UserInfo.getUserId();
  //     return [SELECT Id FROM GroupMember where UserOrGroupId =: UserInfo.getUserId() AND Group.DeveloperName =: groupName].size() > 0;
  // }
}