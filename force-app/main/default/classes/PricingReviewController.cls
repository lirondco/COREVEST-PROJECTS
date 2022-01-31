public class PricingReviewController {
  public string recId { get; set; }

  public ProcessInstanceStep ApprovalProcess {
    get {
      return recId == null
        ? null
        : [
            SELECT Comments, Id
            FROM ProcessInstanceStep
            WHERE ProcessInstance.TargetObjectId = :recId
            ORDER BY SystemModStamp DESC
            LIMIT 1
          ];
    }
    private set;
  }

  public String approvalComments {
      get {
            return ApprovalProcess != null ? ApprovalProcess.Comments : null;
      } private set;
  }

  public String approvalUrl {
      get {
            return ApprovalProcess != null ? URL.getOrgDomainUrl().toExternalForm() + '/' + ApprovalProcess.Id : null;
      } private set;
  }

}
