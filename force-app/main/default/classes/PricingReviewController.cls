public class PricingReviewController {
  public string recId { get; set; }
  public string recipId { get; set; }

  public ProcessInstanceStep ApprovalProcess {
    get {
      if (recId == null) {
        return null;
      }

      String soqlQuery = 'SELECT Comments, Id, ActorId FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId = :recId';
      if (recipId != null) {
        soqlQuery += ' AND ActorId = :recipId';
      }
      soqlQuery += ' ORDER BY SystemModstamp DESC LIMIT 1';
      List<ProcessInstanceStep> steps = Database.query(soqlQuery);
      if (steps.size() > 0) {
        return steps[0];
      } else {
        return [
          SELECT Comments, Id, ActorId
          FROM ProcessInstanceStep
          WHERE ProcessInstance.TargetObjectId = :recId
          ORDER BY SystemModstamp DESC
          LIMIT 1
        ];
      }
    }
    private set;
  }

  public ProcessInstanceWorkItem WorkItem {
    get {
      if (recId == null && recipId == null) {
        return null;
      }

      List<ProcessInstanceWorkItem> workItems = [
        SELECT Id, OriginalActorId, OriginalActor.Name, ActorId
        FROM ProcessInstanceWorkitem
        WHERE ProcessInstance.TargetObjectId = :recId
        AND ActorId = :recipId
        ORDER BY SystemModstamp DESC
        LIMIT 1
      ];

      if(workItems.size() > 0) {
        return workItems[0];
      } else {
        List<ProcessInstanceWorkItem> noRecipWorkItems = [
        SELECT Id, OriginalActorId, OriginalActor.Name, ActorId
        FROM ProcessInstanceWorkitem
        WHERE ProcessInstance.TargetObjectId = :recId
        ORDER BY SystemModstamp DESC
        LIMIT 1
      ];
        return noRecipWorkItems.size() > 0 ? noRecipWorkItems[0] : null;
      }
    }
  }

  public Boolean isApprover {
    get {
      return recipId != null &&
      WorkItem != null &&
        recipId == WorkItem.ActorId;
    }
    private set;
  }

  public String approvalComments {
    get {
      return ApprovalProcess != null ? ApprovalProcess.Comments : null;
    }
    private set;
  }

  public String approvalUrl {
    get {
      return WorkItem != null
        ? URL.getOrgDomainUrl().toExternalForm() + '/' + WorkItem.Id
        : null;
    }
    private set;
  }

  public String dealUrl {
    get {
      return recId == null
        ? null
        : URL.getOrgDomainUrl().toExternalForm() + '/' + recId;
    }
    private set;
  }

  public Integer repriceCount {
    get {
      return [
        SELECT COUNT()
        FROM Approval_History__c
        WHERE
          Parent_Status__c = 'Approved'
          AND Status__c LIKE '%Submitted'
          AND Deal__c = :recId
          AND Approval_Type__c LIKE 'Pricing%'
      ];
    }
    private set;
  }
}
