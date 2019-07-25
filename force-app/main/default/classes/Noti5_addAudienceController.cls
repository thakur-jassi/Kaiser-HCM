public with sharing class Noti5_addAudienceController {

    @AuraEnabled
    public static String createAudienceRecords(String NotificationId, String listWrap){
        List<Audience__c> listAudience = new List<Audience__c>();
        system.debug('notificationId: '+NotificationId);
        system.debug('listwrap '+listWrap);
        List<audienceWrapper> AudWrapper = (List<audienceWrapper>) JSON.deserialize(listWrap, List<audienceWrapper>.class);
        system.debug('wrap '+AudWrapper);
        if(NotificationId != null && NotificationId != ''){
            for(audienceWrapper AudeienceWrap : AudWrapper){
                Audience__c AudienceRecord = new Audience__c();
                AudienceRecord.Notification__c = NotificationId;
                AudienceRecord.Type__c = AudeienceWrap.Type;
                AudienceRecord.Group_Id__c = AudeienceWrap.GroupId;
                AudienceRecord.Group_Name__c = AudeienceWrap.title;
                listAudience.add(AudienceRecord);
            }
        }
        
        if(!listAudience.isEmpty()){
            insert listAudience;
            return listAudience[0].id;
        }
        return null;   
    }

    public class audienceWrapper{
        String Type;
        String GroupId;
        String title;
    }
}