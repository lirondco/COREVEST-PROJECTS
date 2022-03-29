trigger SpecialAssetTrigger on Special_Asset__c (after insert, after update) {
  if(Trigger.isAfter && Trigger.isBefore) {
    SpecialAssetHelper.afterInsert(Trigger.newMap);
  }
  if(Trigger.isAfter && Trigger.isUpdate) {
    SpecialAssetHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
  }
}