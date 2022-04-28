public without sharing class IcReviewsLwcController {
  public static List<String> IC_PROCESS_NAMES = new List<String>{
    'Bridge IC Process',
    'Term Sub-IC',
    'Term IC Process'
  };

  @AuraEnabled(cacheable=true)
  public static List<Map<String, Object>> getApprovalHistories() {
    List<Map<String, Object>> returnVal = new List<Map<String, Object>>();
    List<Approval_History__c> approvalHistories = [
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
        Deal__r.Amount,
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
        ProcessName__c,
        Deal_Stage_At_Time_of_Submission__c
      FROM Approval_History__c
      WHERE
        Parent_Status__c = 'Pending'
        AND Status__c = 'Pending'
        AND (ProcessName__c IN :IC_PROCESS_NAMES
        OR Approval_Type__c LIKE '%IC Memo%')
        AND Process_Id__c != NULL
      ORDER BY LastModifiedDate DESC
    ];

    Set<Id> wrkItemIds = new Set<Id>();
    for (Approval_History__c ah : approvalHistories) {
      Map<String, Object> ahMap = new Map<String, Object>{
        'id' => ah.Id,
        'opportunityName' => ah.Deal__r.Name,
        'opportunityUrl' => '/' + ah.Deal__c,
        'originator' => ah.Deal__r.Owner_Name__c,
        'loanAmount' => ah.Deal__r.Amount,
        'loanType' => ah.Deal__r.Type,
        'productType' => ah.Deal__r.LOC_Loan_Type__c,
        'stageTimeOfSub' => ah.Deal_Stage_At_Time_of_Submission__c,
        'dateSubmitted' => ah.Date_Acted__c,
        'timeSinceSub' => ah.Time_in_Approval__c,
        'subStatus' => ah.Status__c,
        'approvalType' => ah.ProcessName__c,
        'approvalUrl' => '/' + ah.Process_Id__c,
        'approvalName' => ah.Name,
        'processId' => ah.Process_Id__c
      };
      wrkItemIds.add((Id) ah.Process_Id__c);
      returnVal.add(ahMap);
    }

    Map<Id, ProcessInstanceWorkItem> processInstanceMap = new Map<Id, ProcessInstanceWorkItem>([
      SELECT Id, ActorId, Actor.Name, ProcessInstanceId
      FROM ProcessInstanceWorkItem
      WHERE Id IN :wrkItemIds
    ]);

    System.debug(JSON.serializePretty(returnVal));
    for(Map<String, Object> val: returnVal) {
      if(processInstanceMap.size() > 0 && processInstanceMap.containsKey((Id) val.get('processId'))) {
        val.put('approverName', processInstanceMap.get((Id) val.get('processId')).Actor.Name);
      }
    }

    return returnVal;
  }
}