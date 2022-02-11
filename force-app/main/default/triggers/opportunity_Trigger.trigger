trigger opportunity_Trigger on Opportunity(
  before update,
  after update,
  after insert,
  before insert
) {
  Settings__mdt settings = Settings__mdt.getInstance('Universal_Settings'); //lightning_Controller.queryUniversalSettings();
  //if(!opportunity_Helper.isRecursive){
  if (Test.isRunningTest() || !settings.Disable_Opportunity_Trigger__c) {
    if (Trigger.isBefore && Trigger.isInsert) {
      opportunity_Helper.beforeInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
      opportunity_Helper.afterInsert(Trigger.newMap);
      if (!settings.Disable_Post_Close_Trigger__c) {
        PostClosingHelper.createPostClose(Trigger.newMap);
        PostClosingHelper.createPostClosingItems(
          Trigger.newMap,
          new Map<Id, sObject>(),
          'Opportunity',
          'afterInsert'
        );
      }
      ChecklistHelper.createChecklist(Trigger.newMap.keySet());
    }

    if (
      Trigger.isBefore &&
      Trigger.isUpdate &&
      !opportunity_Helper.hasBeforeUpdateRun
    ) {
      if (!Test.isRunningTest()) {
        opportunity_Helper.hasBeforeUpdateRun = true;
      }
      opportunity_Helper.beforeUpdate(Trigger.newMap, Trigger.oldMap);
    }

    if (
      Trigger.isAfter &&
      Trigger.isUpdate &&
      !opportunity_Helper.hasAfterUpdateRun
    ) {
      opportunity_Helper.hasAfterUpdateRun = true;
      opportunity_Helper.afterUpdate(Trigger.newMap, Trigger.oldMap);
      ResoluteVendorAssignment.checkForRtl(Trigger.oldMap, Trigger.newMap);
      if (!settings.Disable_Post_Close_Trigger__c) {
        PostClosingHelper.createPostClosingItems(
          Trigger.newMap,
          Trigger.oldMap,
          'Opportunity',
          'afterUpdate'
        );
      }
    }
  }
}