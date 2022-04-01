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
          (
            SELECT AccountId, UserId
            FROM AccountTeamMembers
            WHERE
              UserId IN (
                SELECT Loss_Mitigation_Associate__c
                FROM Opportunity
                WHERE Id IN :dealMap.keySet()
              )
          )
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
        for (AccountTeamMember atm : acctRecord.AccountTeamMembers) {
          if (atm.TeamMemberRole == LOSS_MITIGATION_ROLE) {
            shouldUpdate = false;
            break;
          } else {
            shouldUpdate = true;
            newAtm.Id = atm.Id;
            newAtm.TeamMemberRole = LOSS_MITIGATION_ROLE;
          }
        }

        if (shouldUpdate) {
          updatedAccTeamMembers.add(newAtm);
        }
      }
    }

    if (updatedAccTeamMembers.size() > 0) {
      upsert updatedAccTeamMembers;
    }
  }
}
