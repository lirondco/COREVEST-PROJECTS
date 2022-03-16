public without sharing class DashboardPricing_LightningController {
  public static Id uId = UserInfo.getUserId();

  @AuraEnabled
  public static String returnApprovals() {
    Datetime span = System.today() - 240;

    User u = [SELECT Id, UserRole.Name FROM User WHERE Id = :uId LIMIT 1];
    Set<String> recordTypes = new Set<String>();
    if (u.UserRole.Name.contains('Bridge')) {
      recordTypes.add('Bridge');
    } else if (u.UserRole.Name.contains('Term')) {
      recordTypes.add('Term');
    } else {
      recordTypes.add('Term');
      recordTypes.add('Bridge');
    }

    List<Approval_History__c> ahList = [
      SELECT
        Actor__c,
        Actor__r.Name,
        Name,
        Comments__c,
        Status_Text__c,
        ProcessName__c,
        Deal__c,
        Deal__r.Record_Type_Name__c,
        Process_Id__c,
        Status__c,
        LastModifiedDate,
        Process_Instance_Id__c,
        Parent_Status__c,
        Approver__c,
        Date_Acted__c,
        Time_in_Approval__c,
        CreatedDate
      FROM Approval_History__c
      WHERE
        LastModifiedDate >= :span
        AND Process_Id__c != NULL
        AND Parent_Status__c = 'Pending'
        AND Deal__r.RecordType__c IN :recordTypes
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
      AND ProcessDefinition.Name LIKE '%pricing review%'
    ]) {
      pricingReviewIds.add(pi.Id);
    }

    Map<String, List<Approval_History__c>> ahMap = new Map<String, List<Approval_History__c>>();
    for (Approval_History__c ah : ahList) {
      if (pricingReviewIds.contains(ah.Process_Instance_Id__c)) {
        if (!ahMap.containsKey(ah.Process_Instance_Id__c)) {
          ahMap.put(ah.Process_Instance_Id__c, new List<Approval_History__c>());
        }
        ahMap.get(ah.Process_Instance_Id__c).add(ah);
      }
    }

    //System.debug(ahMap);

    List<ahWrapper> l = new List<ahWrapper>();

    for (String processId : ahMap.keySet()) {
      System.debug(ahMap.get(processId));
      ahWrapper aw = new ahWrapper();
      DateTime mostRecent;
      DateTime createdDate;
      String timeInSubmission;
      if (ahMap.get(processId).size() > 0) {
        for (Approval_History__c ahc : ahMap.get(processId)) {
          if (
            (null != mostRecent && ahc.LastModifiedDate > mostRecent) ||
            null == mostRecent
          ) {
            mostRecent = ahc.LastModifiedDate;
          }

          if (ahc.Status__c == 'Pending') {
            createdDate = ahc.CreatedDate;
            timeInSubmission = ahc.Time_In_Approval__c;
          }
        }
        aw.oppName = ahMap.get(processId)[0].Name;
        aw.processStatus = ahMap.get(processId)[0].Parent_Status__c;
        aw.processInstance = ahMap.get(processId)[0].Process_Instance_Id__c;
        aw.ahSet = ahMap.get(processId);
        aw.lmd = mostRecent;
        aw.createdDate = createdDate;
        if (createdDate != null) {
          aw.createdDateFormatted = createdDate.format();
        }
        aw.timeInSubmission = timeInSubmission;
        l.add(aw);
      }
    }
    System.debug(l);
    returnWrapper rw = new returnWrapper(uId, l);
    return JSON.serialize(rw, true);

    // List<ProcessInstance> pList = [
    // 	SELECT Status, TargetObject.Name, ProcessDefinition.Name,
    // 	(SELECT Id, OriginalActorId, OriginalActor.Name, StepStatus
    // 	FROM Steps),
    // 	(SELECT Id, OriginalActor.Name, Actor.Name, ProcessInstanceId
    // 	FROM Workitems)
    // 	FROM ProcessInstance
    // 	WHERE Status != 'Approved'
    // 	ORDER BY LastModifiedDate DESC
    // ];
    // itemWrapper iw = new itemWrapper(pList, uId);
    // return JSON.serialize(iw, true);
  }

  // public class itemWrapper {
  // 	List<ProcessInstance> pList;
  // 	Id userId;
  // 	itemWrapper(List<ProcessInstance> pList, Id userId){
  // 		this.pList = pList;
  // 		this.userId = userId;
  // 	}
  // }

  public class ahWrapper {
    public String oppName;
    public List<Approval_History__c> ahSet;
    public DateTime lmd;
    public String processStatus;
    public String processInstance;
    public DateTime createdDate;
    public String timeInSubmission;
    public string createdDateFormatted;
  }

  public class returnWrapper {
    public Id userId;
    public List<ahWrapper> ahWrappers;
    public returnWrapper(Id userId, List<ahWrapper> ahWrappers) {
      this.userId = userId;
      this.ahWrappers = ahWrappers;
    }
  }
}