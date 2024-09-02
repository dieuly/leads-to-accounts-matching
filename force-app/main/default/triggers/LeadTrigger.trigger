trigger LeadTrigger on Lead (before insert/*, before update*/) {
    if (Trigger.isBefore && Trigger.isInsert) {
        LeadTriggerHandler.onBeforeInsert(Trigger.new);
    }/* else if(Trigger.isBefore && Trigger.isUpdate){
        LeadTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }*/
}