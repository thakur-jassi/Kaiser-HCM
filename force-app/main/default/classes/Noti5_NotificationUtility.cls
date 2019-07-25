public class Noti5_NotificationUtility {
    
    @auraEnabled
    public static Boolean checkEligibility(String NotificationId){
        Set<Id> GroupIdSet = new Set<Id>();
        Set<Id> PermissionSetIdSet = new Set<Id>();
        for(Notification__c objNotify : [Select Id, (Select Id, Type__c, Group_Id__c from Notification_Recipients__r) from Notification__c where Id = :NotificationId]){
            for(Audience__c objAudience : objNotify.Notification_Recipients__r){
                if(objAudience.Type__c == 'Profile' && UserInfo.getProfileId() == objAudience.Group_Id__c)
                    return true;
                else if(objAudience.Type__c == 'Role' && UserInfo.getUserRoleId() == objAudience.Group_Id__c)
                    return true;
                else if(objAudience.Type__c == 'Public Group' || objAudience.Type__c == 'Queue')
                    GroupIdSet.add(objAudience.Group_Id__c);
                else if(objAudience.Type__c == 'Permission Set')
                    PermissionSetIdSet.add(objAudience.Group_Id__c);
                
            }
        }
        if(!GroupIdSet.isEmpty()){
            for(GroupMember grpMember : [select UserOrGroupId from GroupMember where GroupId IN :GroupIdSet]){
                if(grpMember.UserOrGroupId == UserInfo.getUserId())
                    return true;
            }
        }
        if(!PermissionSetIdSet.isEmpty()){
            for(PermissionSetAssignment Assignment : [SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId()]){
                if(PermissionSetIdSet.contains(Assignment.PermissionSetId))
                    return true;
            }
        }
        
        return false;
    }
    
    @auraEnabled
    public static void insertResponse(String NotificationId){
        
        List<Audience_Response__c> responseList = [Select Id from Audience_Response__c where User__c = :UserInfo.getUserId() AND Notification__c = :NotificationId];
        
        if(responseList.isEmpty()){
            Audience_Response__c audienceResponse = new Audience_Response__c();
            audienceResponse.Notification__c = NotificationId;
            audienceResponse.User__c = UserInfo.getUserId();
            audienceResponse.Response_Time__c = System.now();        
            Insert audienceResponse;
        }
    }
    
    @auraEnabled
    public static List<Audience_Response__c> getAckMessages(){
        List<Audience_Response__c> lResponses = [Select id,notification__r.Message__c,Response_Time__c,notification__r.name,notification__r.CreatedDate ,user__r.SmallPhotoUrl,user__r.name from Audience_Response__c where User__c = : UserInfo.getUserId() order by notification__r.name desc];
        return lResponses;
        
    }
    
    @auraEnabled
    public static List<Notification__c> getNewMessages(){
        
        Set<String> SetOfIds = new Set<String>();
        SetOfIds.add(UserInfo.getProfileId());
        if(UserInfo.getUserRoleId() != '' && UserInfo.getUserRoleId() != null){
            SetOfIds.add(UserInfo.getUserRoleId());
        }
        for(PermissionSetAssignment Assignment : [SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId()]){
            SetOfIds.add(Assignment.PermissionSetId);
        }
        for(GroupMember grpMember : [select UserOrGroupId, GroupId from GroupMember where UserOrGroupId = :UserInfo.getUserId()]){
            SetOfIds.add(grpMember.GroupId);
        }
        
        List<Notification__c> lNewMessages = new List<Notification__c>();
        for(Notification__c notify : [Select Id,(Select id from Notification_Recipients__r where Group_Id__c IN :SetOfIds),(Select id from Audience_Responses__r where User__c = :UserInfo.getUserId()),Message__c,Priority__c,Name,Createdby.SmallPhotoUrl ,Createdby.Name from Notification__c where Status__c = 'Notification Sent' ORDER BY CreatedDate DESC]){
            if(notify.Notification_Recipients__r.size() > 0 && notify.Audience_Responses__r.size() == 0){
                lNewMessages.add(notify);
            }
        }
        return lNewMessages;
    }
            
    Public class wWallOfShameUserList implements Comparable{
        @AuraEnabled
        Public Integer sCount;
        @AuraEnabled
        Public string sElapsedTime;
        @AuraEnabled
        Public decimal sElapsedTimeMilli;
        @AuraEnabled
        Public String userId;
        @AuraEnabled
        Public String name;
        @AuraEnabled
        Public String smallPhotoUrl;
        @AuraEnabled
        Public String lastlogin;

        public Integer compareTo(Object objToCompare) {
            return Integer.valueOf(((wWallOfShameUserList)objToCompare).sElapsedTimeMilli - sElapsedTimeMilli);
        }

    }
    
    @AuraEnabled
    public static List<wWallOfShameUserList> getWallOfShameUsers(){
        
        Map<String,Set<String>> mNotificationwAudience = new Map<String,Set<String>>();
        Map<String,Set<String>> mGroupIDsToUsers = new Map<String,Set<String>>();
        Set<String> sGroupTypes = new Set<String>();

        List<Audience__c> lAudience = new List<Audience__c>();
        Map<String,Notification__c> mNotificationCreatedTime = new Map<String,Notification__c>();
        
        Map<string,Set<String>> mNotificationToAudience = new Map<string,Set<String>>();
        Map<Id,set<string>> mAudienceResponseIds = new Map<Id,set<string>>();
        Set<string> sNotificationIds = mNotificationwAudience.keyset();
        
        
        NoTi5__mdt customMetadataValue = [Select DeveloperName, of_Hrs_for_Wall_of_Shame__c, Wall_of_Shame_Users__c from NoTi5__mdt where DeveloperName = 'NoTi5'];
        decimal hrs = customMetadataValue.of_Hrs_for_Wall_of_Shame__c * 0.0416667;
        Set<string> sGroupIds = new Set<string>();

        String queryString = 'Select id,Notification__c,Notification__r.Elapsed_Time__c,Notification__r.Elapsed_Time_milli__c,Notification__r.Id,Group_Id__c,type__c'+ 
                                                    +' from Audience__c where Notification__r.Status__c =  \'Notification Sent\'';
        if(!Test.isRunningTest()){
            queryString = queryString +' and Notification__r.Elapsed_Time_milli__c >: hrs';
        }
        
        queryString = queryString +' order by Notification__r.createddate ASC limit 10';
                
        for(Audience__c oAud : Database.query(queryString)){
            sGroupIds.add(oAud.Group_Id__c);

            if(oAud.Group_Id__c.startsWith('00e')){
                sGroupTypes.add('Profile');
            }
            else if(oAud.Group_Id__c.startsWith('00E')){
                sGroupTypes.add('Role');
            }
            else if(oAud.Group_Id__c.startsWith('00G')){
                sGroupTypes.add('Group');
            }
            else if(oAud.Group_Id__c.startsWith('0PS')){
                sGroupTypes.add('Permissionset');
            }

            if(mNotificationwAudience.containsKey(oAud.Notification__r.Id)){
                mNotificationwAudience.get(oAud.Notification__r.Id).add(oAud.Group_Id__c);
            }
            else{
                mNotificationwAudience.put(oAud.Notification__r.Id,new Set<String>{oAud.Group_Id__c});
                mNotificationCreatedTime.put(oAud.Notification__r.Id,oAud.Notification__r);
            }

            lAudience.add(oAud);
            
        }
        
        //querying all audience who responded
        for(Audience_Response__c oAudresp : [Select Id,Notification__r.Id,User__c from Audience_Response__c where Notification__c in : mNotificationwAudience.keyset()]){
            if(mAudienceResponseIds.containskey(oAudresp.Notification__r.Id)){
                mAudienceResponseIds.get(oAudresp.Notification__r.Id).add(oAudresp.User__c);
            }
            else{
                mAudienceResponseIds.put(oAudresp.Notification__r.Id,new set<string>{oAudresp.User__c});
            }
            
        }
       
        for(User oUser : [select id,profileid,userroleid from user where (profileId IN : sGroupIds or userroleid IN : sGroupIds) and Exclude_from_Notifications__c = false]){
            if(oUser.ProfileId!=null && ((string)oUser.ProfileId).startswith('00e')){
                if(mGroupIDsToUsers.containsKey(oUser.profileid)){
                    mGroupIDsToUsers.get(oUser.profileid).add(oUser.Id);
                }
                else{
                    mGroupIDsToUsers.put(oUser.profileid,new set<string>{oUser.Id});
                }   
            }
            
            if(oUser.userroleid!=null && ((string)oUser.userroleid).startswith('00E')){
                if(mGroupIDsToUsers.containsKey(oUser.userroleid)){
                    mGroupIDsToUsers.get(oUser.userroleid).add(oUser.Id);
                }
                else{
                    mGroupIDsToUsers.put(oUser.userroleid,new set<string>{oUser.Id});
                }   
            }
        }
       
        for(GroupMember oGroup: [SELECT GroupId, UserOrGroupId  FROM GroupMember where GroupId In : sGroupIds]){
            if(oGroup.UserOrGroupId!=null && ((string)oGroup.UserOrGroupId).startsWith('005')){
                if(mGroupIDsToUsers.containsKey(oGroup.GroupId)){
                    mGroupIDsToUsers.get(oGroup.GroupId).add(oGroup.UserOrGroupId);
                }
                else{
                    mGroupIDsToUsers.put(oGroup.GroupId,new set<string>{oGroup.UserOrGroupId});
                }   
            }
        }
        
        for(PermissionSetAssignment oPerm: [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment 
                                            where PermissionSetId In : sGroupIds and  
                                            (NOT PermissionSet.Name Like  'X%')]){
                                                if(mGroupIDsToUsers.containsKey(oPerm.PermissionSetId)){
                                                    mGroupIDsToUsers.get(oPerm.PermissionSetId).add(oPerm.AssigneeId);
                                                }
                                                else{
                                                    mGroupIDsToUsers.put(oPerm.PermissionSetId,new set<string>{oPerm.AssigneeId});
                                                }           
                                            }
        
        Map<ID,Set<String>> mNotificationToUsers = new Map<ID,Set<String>>();

        for(string oUser :  mNotificationwAudience.keyset()){
            Set<String> sUsers = new Set<String>();
            for(string oGroupIds : mNotificationwAudience.get(oUser)){
                sUsers.addall(mGroupIDsToUsers.get(oGroupIds));
            }
            mNotificationToUsers.put(oUser,sUsers);
        }

        Set<string> sUserIds = new Set<string>();
        for(String oUser : mNotificationToUsers.keyset()){
            if(mAudienceResponseIds.containskey(oUser)){
                mNotificationToUsers.get(oUser).removeAll(mAudienceResponseIds.get(oUser));
                sUserIds.addall(mNotificationToUsers.get(oUser));
            }
        }


        Map<string,wWallOfShameUserList> mUserCountNotResponded = new Map<string,wWallOfShameUserList>();
        Map<Id,User> mUserDetails = new Map<id,User>([Select ID,Name,LastLoginDate,smallPhotoUrl from User where ID IN : sUserIds and Exclude_from_Notifications__c = false limit 50000]);
        for(String oTotalUsers : mNotificationToUsers.keyset()){
            for(string oUserdet : mNotificationToUsers.get(oTotalUsers)){
                if(mUserDetails.containskey(oUserdet)){
                    wWallOfShameUserList oUser = new wWallOfShameUserList();
                    oUser.userId = mUserDetails.get(oUserdet).Id;
                    oUser.Name = mUserDetails.get(oUserdet).Name;
                    oUser.smallPhotoUrl = mUserDetails.get(oUserdet).smallPhotoUrl;
                    if(mUserCountNotResponded.containsKey(oUser.userId)){
                        oUser.sCount = mUserCountNotResponded.get(oUser.userId).sCount + 1;
                        oUser.sElapsedTimeMilli = mUserCountNotResponded.get(oUser.userId).sElapsedTimeMilli+mNotificationCreatedTime.get(oTotalUsers).Elapsed_Time_milli__c;
                        if(mUserCountNotResponded.get(oUser.userId).sElapsedTimeMilli < mNotificationCreatedTime.get(oTotalUsers).Elapsed_Time_milli__c){
                            oUser.sElapsedTime = mNotificationCreatedTime.get(oTotalUsers).Elapsed_Time__c;
                        }
                        else {
                            oUser.sElapsedTime = mUserCountNotResponded.get(oUser.userId).sElapsedTime;
                        }
                    }
                    else{
                        oUser.sCount = 1;
                        oUser.sElapsedTimeMilli = mNotificationCreatedTime.get(oTotalUsers).Elapsed_Time_milli__c;
                        oUser.sElapsedTime = mNotificationCreatedTime.get(oTotalUsers).Elapsed_Time__c;
                    }
                    if(mUserDetails.get(oUser.userId).LastLoginDate!=null){
                        oUser.lastlogin = mUserDetails.get(oUser.userId).LastLoginDate.format();
                    }

                    mUserCountNotResponded.put(oUser.userId,oUser);
                }
            }
        }

        for(User usr : [Select Id, isActive from User where Id in :mUserCountNotResponded.keySet()]){
            if(usr.isActive == false)
                mUserCountNotResponded.remove(usr.Id);
        }

        List<wWallOfShameUserList> lUsers = mUserCountNotResponded.values();
        lUsers.sort();

        List<wWallOfShameUserList> lFilteredTopUsers = new List<wWallOfShameUserList>(); 

        Integer i=0;
        for(wWallOfShameUserList oTopFilter : lUsers){
            lFilteredTopUsers.add(oTopFilter);
            i++;
            if(i>=customMetadataValue.Wall_of_Shame_Users__c){
                break;
            }
        }
        system.debug('^^^^^^^'+lFilteredTopUsers);

        return lFilteredTopUsers;
    }
    
    public class chartMetrics {
        @AuraEnabled
        public Integer acknowledged;
        @AuraEnabled
        public Integer notacknowledged;
        @AuraEnabled
        public Integer totalaudience;
        
    }

    @AuraEnabled(cacheable=true)
    public static chartMetrics getchartMetrics(String notificationId){
        set<Id> sGroupIds =  new set<Id>();
        set<string> sGroupNames =  new set<string>();
        Set<Id> sTotalUserIds = new Set<Id>();
        Set<Id> sRespondedUserIds = new Set<Id>();
        chartMetrics oMetrics = new chartMetrics();

        
        for(Audience__c oAud : [Select id,Group_Id__c,type__c from Audience__c where Notification__c = : notificationId]){
            sGroupIds.add(oAud.Group_Id__c);
            sGroupNames.add(oAud.type__c);
        }

        for(Audience_Response__c oAud : [Select id,user__c from Audience_Response__c where Notification__c  = : notificationId]){
            sRespondedUserIds.add(oAud.user__c);
        }

        if(sGroupNames.contains('Profile') || sGroupNames.contains('Role')){
            for(User oUser :[select id from user where profileid in : sGroupIds or userroleid in : sGroupIds]){
                sTotalUserIds.add(oUser.Id);
            }
        }

        if(sGroupNames.contains('Permission Set') ){
            for(PermissionSetAssignment oUser :[SELECT AssigneeId FROM PermissionSetAssignment where PermissionSetId in : sGroupIds]){
                sTotalUserIds.add(oUser.AssigneeId);
            }
        }

        if(sGroupNames.contains('Public Group') ||  sGroupNames.contains('Queue')){
            for(GroupMember oUser :[SELECT UserOrGroupId FROM GroupMember where GroupId in : sGroupIds]){
                sTotalUserIds.add(oUser.UserOrGroupId);
            }
        }

        for(User usr : [Select Id, isActive from User where Id in :sTotalUserIds]){
            if(usr.isActive == false)
                sTotalUserIds.remove(usr.Id);
        }

        oMetrics.acknowledged = sRespondedUserIds.size();
        oMetrics.totalaudience = sTotalUserIds.size();
        oMetrics.notacknowledged = oMetrics.totalaudience - oMetrics.acknowledged;

        system.debug('###'+oMetrics);
        return oMetrics;
    }

    
    @AuraEnabled(cacheable=true)
    public static wCount getCount(String notificationId, String searchKey,String acknowledgedfilter,String notacknowledgefilter, integer iPage){
        system.debug('#####'+iPage);
        set<Id> sGroupIds =  new set<Id>();
        set<string> sGroupNames =  new set<string>();
        Set<Id> sTotalUserIds = new Set<Id>();
        Map<Id,Audience_Response__c> mRespondedUserIds = new Map<Id,Audience_Response__c>();
        Set<Id> sRespondedUserIds = new Set<Id>();
        Integer offset = ((Integer)iPage - 1) * 10;

        List<wUserDetails> lUserDetails = new List<wUserDetails>();

        for(Audience__c oAud : [Select id,Group_Id__c,type__c from Audience__c where Notification__c = : notificationId]){
            sGroupIds.add(oAud.Group_Id__c);
            sGroupNames.add(oAud.type__c);
        }

        for(Audience_Response__c oAud : [Select id,user__c,Response_Time__c from Audience_Response__c where Notification__c  = : notificationId]){
            mRespondedUserIds.put(oAud.user__c,oAud);
            sRespondedUserIds.add(oAud.user__c);
        }

        if(sGroupNames.contains('Profile') || sGroupNames.contains('Role')){
            string sQuery = 'select id from user where (profileid in : sGroupIds or userroleid in : sGroupIds)';
            if(searchKey!=null && searchKey!=''){
                sQuery += ' and name like \'%' + String.escapeSingleQuotes(searchKey) + '%\'';
            }
            if(notacknowledgefilter!='' ){
                sQuery += ' and Id NOT IN : sRespondedUserIds';
            }
            else if(acknowledgedfilter!=''){
                sQuery += ' and Id IN : sRespondedUserIds';
            }

            for(User oUser : database.query(sQuery)){
                sTotalUserIds.add(oUser.Id);
            }
        }

        if(sGroupNames.contains('Permission Set') ){
            string sQuery = 'SELECT AssigneeId FROM PermissionSetAssignment where PermissionSetId in : sGroupIds and (NOT PermissionSet.Name Like  \'X%\')';
            if(searchKey!=null && searchKey!=''){
                sQuery += ' and Assignee.name like \'%' + String.escapeSingleQuotes(searchKey) + '%\'';
            }
            if(notacknowledgefilter!='' ){
                sQuery += ' and AssigneeId NOT IN : sRespondedUserIds';
            }
            else if(acknowledgedfilter!='' ){
                sQuery += ' and AssigneeId IN : sRespondedUserIds';
            }
            for(PermissionSetAssignment oUser : database.query(sQuery)){
                sTotalUserIds.add(oUser.AssigneeId);
            }
        }

        //querying all group members since it cannot be sorted due to polymorphic field UserOrGroupId
        if(sGroupNames.contains('Public Group') ||  sGroupNames.contains('Queue')){
            string sQuery = 'SELECT UserOrGroupId FROM GroupMember where GroupId in : sGroupIds';
            
            if(notacknowledgefilter!=''){
                sQuery += ' and UserOrGroupId NOT IN : sRespondedUserIds';
            }
            else if(acknowledgedfilter!='' ){
                sQuery += ' and UserOrGroupId IN : sRespondedUserIds';
            }
            for(GroupMember oUser :(Database.query(sQuery))){
                sTotalUserIds.add(oUser.UserOrGroupId);
            }
        }
        
        for(User usr : [Select Id, isActive from User where Id in :sTotalUserIds]){
            if(usr.isActive == false)
                sTotalUserIds.remove(usr.Id);
        }
        
        Map<Id,wUserDetails> mUserdetails = new Map<Id,wUserDetails>();

        string sQuery = 'Select id,name,smallPhotoUrl,email,LastLoginDate, Profile.Name, UserRole.Name,FullPhotoUrl from User where Id in : sTotalUserIds';
        string sUserCount ='Select count() from user where Id in : sTotalUserIds';
        if(searchKey!=null && searchKey!=''){
            sQuery += ' and name like \'%' + String.escapeSingleQuotes(searchKey) + '%\'';
            sUserCount += ' and name like \'%' + String.escapeSingleQuotes(searchKey) + '%\'';
        }
            sQuery +=  ' order by name asc limit 10 OFFSET : offset';

        if(notacknowledgefilter!='' ){
            sUserCount += ' and Id NOT IN : sRespondedUserIds';
        }
        else if(acknowledgedfilter!=''){
            sUserCount += ' and Id IN : sRespondedUserIds';
        }

        for(user oUser : database.query(sQuery)){
            wUserDetails wDetail = new wUserDetails();
            wDetail.userId = oUser.Id;
            wDetail.smallPhotoUrl = oUser.smallPhotoUrl;
            wDetail.FullPhotoUrl = oUser.FullPhotoUrl;
            if(oUser.LastLoginDate!=null){
                wDetail.lastlogindate = oUser.LastLoginDate.format();
            }    
            wDetail.profile = oUser.Profile.Name;
            wDetail.role = oUser.UserRole.Name;
            wDetail.email = oUser.email;
            wDetail.Name = oUser.Name;
            wDetail.publicgroups = new List<String>();
            wDetail.queues = new List<String>();
            wDetail.permissionsets = new List<String>();
            mUserdetails.put(oUser.Id,wDetail);
            lUserDetails.add(wDetail);
        }

        for(GroupMember oGroup: [SELECT GroupId,Group.Name,group.type, UserOrGroupId  FROM GroupMember where UserOrGroupId In : mUserdetails.keySet() Order by Group.Name asc]){    
            if(oGroup.Group.Type=='Regular'){
                
                mUserdetails.get(oGroup.UserOrGroupId).publicgroups.add(oGroup.Group.Name);
                
            }              
            else if (oGroup.Group.Type=='Queue'){
                    mUserdetails.get(oGroup.UserOrGroupId).queues.add(oGroup.Group.Name);
            }
        }

        for(PermissionSetAssignment oPerm: [SELECT AssigneeId, PermissionSetId,PermissionSet.label FROM PermissionSetAssignment 
                                                where AssigneeId In : mUserdetails.keySet() and (NOT PermissionSet.Name Like  'X%') Order by PermissionSet.label asc]){
                mUserdetails.get(oPerm.AssigneeId).permissionsets.add(oPerm.PermissionSet.label);
                      
        }

        for(wUserDetails oUser : lUserDetails){
            if(mUserdetails.containskey(oUser.userId)){
                oUser.permissionsets = mUserdetails.get(oUser.userId).permissionsets;
                oUser.publicgroups = mUserdetails.get(oUser.userId).publicgroups;
            }
           
            if(mRespondedUserIds.containskey(oUser.userId) && mRespondedUserIds.get(oUser.userId).Response_Time__c!=null){
                oUser.datetimeacknowledged = mRespondedUserIds.get(oUser.userId).Response_Time__c.format();
            }    
            
        }

        system.debug('%%%%%%'+database.countQuery(sUserCount));

        wCount oReturnDetails = new wCount();
        oReturnDetails.page = ipage;
        oReturnDetails.totalAudience = database.countQuery(sUserCount);
        oReturnDetails.totalpages = (Math.ceil(oReturnDetails.totalAudience/10)).intValue();
        oReturnDetails.lusers = lUserDetails;
        // system.debug('######'+oReturnDetails.lusers.size());

        return oReturnDetails;
    }
    
    
    Public class wCount{
        
        @AuraEnabled
        public Integer page;

        @AuraEnabled
        Public Integer totalAudience;

        @AuraEnabled
        Public Integer totalpages;

        @AuraEnabled
        Public List<wUserDetails> lusers;
    }
    
    Public class wUserDetails{
        @AuraEnabled
        Public Id userId;
        @AuraEnabled
        Public string smallPhotoUrl;
        @AuraEnabled
        Public string email;
        @AuraEnabled
        Public string lastlogindate;
        @AuraEnabled
        Public string profile;
        @AuraEnabled
        Public string role;
        @AuraEnabled
        Public string FullPhotoUrl;
        @AuraEnabled
        Public String datetimeacknowledged;
        @AuraEnabled
        Public string Name;
        @AuraEnabled
        Public List<String> permissionsets;
        @AuraEnabled
        Public List<String> publicgroups;
        @AuraEnabled
        Public List<String> queues;
        
    }
        
    
    @AuraEnabled
    Public static Map<Id,Audience_Response__c> getAudienceResponse(String notificationId){
        Map<Id,Audience_Response__c> mAudResponse = new Map<Id,Audience_Response__c>();
        for(Audience_Response__c oResponse : [Select Id,Notification__c,Response_Time__c,User__c from Audience_Response__c where Notification__c = :notificationId]){
            mAudResponse.put(oResponse.User__c,oResponse);
        }
        
        return mAudResponse;
    }
    
}