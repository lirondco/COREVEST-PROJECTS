global class PricingReviewController {
  global string recId { get; set; }

  global ProcessInstanceStep ApprovalProcess {
    get {
      if (recId == null) {
        return null;
      }

      String soqlQuery = 'SELECT Comments, Id, ActorId FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId = :recId';
      soqlQuery += ' ORDER BY SystemModstamp DESC LIMIT 1';
      List<ProcessInstanceStep> steps = Database.query(soqlQuery);
      return steps.size() > 0 ? steps[0] : null;
    }
    private set;
  }

  global ProcessInstanceWorkItem WorkItem {
    get {
      if (recId == null) {
        return null;
      } else {
        List<ProcessInstanceWorkItem> workItems = [
          SELECT Id, OriginalActorId, OriginalActor.Name, ActorId, Actor.Name
          FROM ProcessInstanceWorkitem
          WHERE ProcessInstance.TargetObjectId = :recId
          ORDER BY SystemModstamp DESC
          LIMIT 1
        ];
        return workItems.size() > 0 ? workItems[0] : null;
      }
    } private set;
  }

  global String approvalComments {
    get {
      return ApprovalProcess != null ? ApprovalProcess.Comments : null;
    }
    private set;
  }

  global String approvalUrl {
    get {
      return WorkItem != null
        ? URL.getOrgDomainUrl().toExternalForm() + '/' + WorkItem.Id
        : null;
    }
    private set;
  }

  global String dealUrl {
    get {
      return recId == null
        ? null
        : URL.getOrgDomainUrl().toExternalForm() + '/' + recId;
    }
    private set;
  }

  global Integer repriceCount {
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