public without sharing class OpportunityMethods {
  private static final String LOSS_MITIGATION_ROLE = 'Loss Mitigation Associate';

  public static void updatePaidOffProperties(Map<Id, Opportunity> dealMap) {
    List<Property__c> propertiesForUpdate = [
      SELECT Id, Status__c, Deal__c, Inactive_Date__c
      FROM Property__c
      WHERE Deal__c IN :dealMap.keySet() AND Status__c = 'Active'
      FOR UPDATE
    ];

    if (propertiesForUpdate.size() > 0) {
      for (Property__c p : propertiesForUpdate) {
        p.Status__c = 'Paid Off';
        p.Inactive_Date__c = dealMap.get(p.Deal__c).Payoff_Date__c;
      }

      update propertiesForUpdate;
    }
  }

  public static void reassignLossMitUser(Map<Id, Opportunity> dealMap) {
    Map<Id, Account> acctMap = new Map<Id, Account>(
      [
        SELECT
          Id,
          (SELECT AccountId, UserId, TeamMemberRole FROM AccountTeamMembers)
        FROM Account
        WHERE
          Id IN (
            SELECT AccountId
            FROM Opportunity
            WHERE Id IN :dealMap.keySet()
          )
      ]
    );

    List<AccountTeamMember> updatedAccTeamMembers = new List<AccountTeamMember>();
    List<AccountTeamMember> forDeletion = new List<AccountTeamMember>();
    for (Opportunity o : dealMap.values()) {
      Account acctRecord = acctMap.get(o.AccountId);
      if (
        acctRecord.AccountTeamMembers == null ||
        acctRecord.AccountTeamMembers.size() == 0
      ) {
        updatedAccTeamMembers.add(
          new AccountTeamMember(
            TeamMemberRole = LOSS_MITIGATION_ROLE,
            AccountId = o.AccountId,
            UserId = o.Loss_Mitigation_Associate__c
          )
        );
      } else {
        AccountTeamMember newAtm = new AccountTeamMember();
        Boolean shouldUpdate = false;
        Boolean userFound = false;
        for (AccountTeamMember atm : acctRecord.AccountTeamMembers) {
          if (atm.userId == o.Loss_Mitigation_Associate__c) {
            userFound = true;
          }
          if (
            atm.UserId == o.Loss_Mitigation_Associate__c &&
            atm.TeamMemberRole != LOSS_MITIGATION_ROLE
          ) {
            shouldUpdate = true;
            newAtm.Id = atm.Id;
            newAtm.TeamMemberRole = LOSS_MITIGATION_ROLE;
          } else if (
            atm.TeamMemberRole == LOSS_MITIGATION_ROLE &&
            atm.UserId != o.Loss_Mitigation_Associate__c
          ) {
            shouldUpdate = true;
            newAtm.UserId = o.Loss_Mitigation_Associate__c;
            newAtm.AccountId = o.AccountId;
            newAtm.TeamMemberRole = LOSS_MITIGATION_ROLE;
            forDeletion.add(atm);
          }
        }

        if (!userFound) {
          shouldUpdate = true;
          newAtm.UserId = o.Loss_Mitigation_Associate__c;
          newAtm.AccountId = o.AccountId;
          newAtm.TeamMemberRole = LOSS_MITIGATION_ROLE;
        }

        if (shouldUpdate) {
          updatedAccTeamMembers.add(newAtm);
        }
      }
    }

    if (updatedAccTeamMembers.size() > 0) {
      upsert updatedAccTeamMembers;
    }

    if (forDeletion.size() > 0) {
      String objName = 'AccountTeamMember';
      Boolean isDeletableAccountTeamMember = Schema.getGlobalDescribe()
        .get(objName)
        .getDescribe()
        .isDeletable();
    
        if (isDeletableAccountTeamMember) {
            delete forDeletion;
        }
    }
  }
}
