public with sharing class Playout_DataQuery {
    
    public static List<Playout__c> getPlayoutByObjectName(String objectName){
        //CRUD/FLS check
        Util.AccessController.assertAuthorizedToView(
                Schema.Playout__c.getSobjectType(),
                new List<Schema.SobjectField>{
                        Schema.Playout__c.fields.Name, Schema.Playout__c.fields.Field__c,
                        Schema.Playout__c.fields.Order__c,Schema.Playout__c.fields.Object__c
                }
        );
        
        return [select Name, Field__c, Order__c, Object__c from Playout__c where Object__c=:objectName and User__c=:UserInfo.getUserId() Order by Order__c desc];
    }
    
    public static List<Playout__c> getPlayoutByField(String objectName, String field){
        //CRUD/FLS check - SELECT
        Util.AccessController.assertAuthorizedToView(
                Schema.Playout__c.getSobjectType(),
                new List<Schema.SobjectField>{
                        Schema.Playout__c.fields.Name, Schema.Playout__c.fields.Field__c,
                        Schema.Playout__c.fields.Order__c,Schema.Playout__c.fields.Object__c
                }
        );

        
        return [select id, Field__c, Order__c, Object__c from Playout__c where Object__c=:objectName and User__c=:UserInfo.getUserId() and Field__c=:field limit 1];

    }

}