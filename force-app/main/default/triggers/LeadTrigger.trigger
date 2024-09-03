trigger LeadTrigger on Lead (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        LeadTriggerHandler.onBeforeInsert(Trigger.new);
    }
}
