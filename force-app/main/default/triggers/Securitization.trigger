trigger Securitization on Securitization__c (
    before insert, 
    before update, 
    before delete, 
    after insert, 
    after update, 
    after delete, 
    after undelete) {

        if ( Trigger.isBefore && Trigger.isInsert ) {
            SecuritizationHelper.beforeInsert(Trigger.New);
        }
        if ( Trigger.isAfter && Trigger.isInsert ) {
            SecuritizationHelper.afterInsert(Trigger.New);
        }
        if ( Trigger.isBefore && Trigger.isUpdate ) {
            SecuritizationHelper.beforeUpdate(Trigger.New, Trigger.oldMap);
        }
        if ( Trigger.isAfter && Trigger.isUpdate ) {
            SecuritizationHelper.afterUpdate(Trigger.oldMap, Trigger.New);
        }
        if ( Trigger.isBefore && Trigger.isDelete ) {
        //  SecuritizationHelper.beforeDelete(Trigger.New);
        }
        if ( Trigger.isAfter && Trigger.isDelete ) {
        //  SecuritizationHelper.afterDelete(Trigger.New, Trigger.Old);
        }
        if ( Trigger.isAfter && Trigger.isUndelete ) {
        //  SecuritizationHelper.afterUndelete(Trigger.Old);
        }
}