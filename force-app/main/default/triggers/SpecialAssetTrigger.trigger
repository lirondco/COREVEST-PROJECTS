trigger SpecialAssetTrigger on Special_Asset__c (after insert, before update, after update) {

  if(Trigger.isAfter && Trigger.isInsert) {
    SpecialAssetHelper.afterInsert(Trigger.newMap);
  }
  if(Trigger.isBefore && Trigger.isUpdate) {
    SpecialAssetHelper.beforeUpdate(Trigger.oldMap, Trigger.newMap);
  }
  if(Trigger.isAfter && Trigger.isUpdate) {
    SpecialAssetHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
  }
}