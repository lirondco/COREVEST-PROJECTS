public without sharing class MessageCenterController {
  @AuraEnabled
  public static List<PortalAPIComments.Comment> getAllComments(Id recordId) {
    try {
      List<PortalAPIComments.Comment> comments = new List<PortalAPIComments.Comment>();

      for (Comment__c comment : [
        SELECT
          Id,
          Deal__c,
          Lead__c,
          Lead__r.Name,
          Contact__r.Name,
          Contact__c,
          Application__c,
          Application__r.Name,
          Property__r.Name,
          Deal__r.Name,
          Deal_Document__r.Name,
          Body__c,
          Alchemy_Portal_Id__c,
          Submitted_From_Portal__c,
          Deal_Document__c,
          Property__c,
          CreatedDate,
          Owner.Name,
          Owner.Id,
          Subject__c,
          Comment__c,
          Owner_Image__c
        FROM Comment__c
        WHERE
          Comment__c = NULL
          AND (Deal__c = :recordId
          OR Property__r.Deal__c = :recordId
          OR Property__c = :recordId
          OR Deal_Document__c = :recordId
          OR Application__c = :recordId)
        ORDER BY CreatedDate DESC
      ]) {
        comments.add(new PortalAPIComments.Comment(comment));
      }

      return comments;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static List<PortalAPIComments.Comment> getCommentsById(Id commentId) {
    try {
      return PortalAPIComments.getComment(commentId);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}