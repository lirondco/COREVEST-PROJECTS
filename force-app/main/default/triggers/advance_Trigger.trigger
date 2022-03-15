trigger advance_Trigger on Advance__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  Settings__mdt settings = Settings__mdt.getInstance('Universal_Settings');
  if (!settings.Disable_Advance_Trigger__c) {
    if (Trigger.isBefore && Trigger.isInsert) {
	Advance_Helper.beforeInsert(Trigger.New);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
      Advance_Helper.afterInsert(Trigger.New);
      PostClosingHelper.createSections(Trigger.NewMap, 'Advance__c');
      if (!settings.Disable_Post_Close_Trigger__c) {
        PostClosingHelper.createPostClosingItems(
          Trigger.newMap,
          new Map<Id, sObject>(),
          'Advance__c',
          'afterInsert'
        );
      }
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
      Advance_Helper.beforeUpdate(Trigger.New, Trigger.Old);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
      Advance_Helper.afterUpdate(Trigger.New, Trigger.Old);
      if (!settings.Disable_Post_Close_Trigger__c) {
        PostClosingHelper.createPostClosingItems(
          Trigger.newMap,
          Trigger.oldMap,
          'Advance__c',
          'afterUpdate'
        );
      }
      // PropertyTriggerExtensions.checkAdvancesPropertyCount(Trigger.oldMap, Trigger.newMap);
    }
    if (Trigger.isBefore && Trigger.isDelete) {
      Advance_Helper.beforeDelete(Trigger.Old);
    }
    if (Trigger.isAfter && Trigger.isDelete) {
      // Advance_Helper.afterDelete(Trigger.New, Trigger.Old);
    }
    if (Trigger.isAfter && Trigger.isUndelete) {
      //  Advance_Helper.afterUndelete(Trigger.Old);
    }
  }
}