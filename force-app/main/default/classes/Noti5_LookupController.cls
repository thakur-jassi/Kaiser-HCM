public with sharing class Noti5_LookupController {

    private final static Integer MAX_RESULTS = 10;

    @AuraEnabled(Cacheable=true)
    public static List<Noti5_LookupSearchResult> search(String searchTerm, List<String> selectedIds, String type) {
        // Prepare query paramters
        String searchString = '%'+searchTerm+'%';
        String groupIcon = 'standard:groups';

        // Prepare results
        List<Noti5_LookupSearchResult> results = new List<Noti5_LookupSearchResult>();

        //Search Groups
        if(type == 'Role'){

            for(UserRole role : [Select Id, Name from UserRole where Name like :searchString ORDER BY Name LIMIT :MAX_RESULTS]){
                results.add(new Noti5_LookupSearchResult(role.Id, null, groupIcon, role.Name, 'Role • '+ role.Name));
            }
        }
        else if(type == 'Profile'){
            for(Profile prof : [Select Id, Name from Profile where Name like :searchString ORDER BY Name LIMIT :MAX_RESULTS]){
                results.add(new Noti5_LookupSearchResult(prof.Id, null, groupIcon, prof.Name, 'Profile • '+ prof.Name));
            }
        }
        else if(type == 'Public Group'){
            for(Group grp : [Select Id, Name from Group where type!='Queue' AND Name like :searchString ORDER BY Name LIMIT :MAX_RESULTS]){
                results.add(new Noti5_LookupSearchResult(grp.Id, null, groupIcon, grp.Name, 'Public Group • '+ grp.Name));
            }
        }
        else if(type == 'Queue'){
            for(Group grp : [Select Id, Name from Group where type='Queue' AND Name like :searchString ORDER BY Name LIMIT :MAX_RESULTS]){
                results.add(new Noti5_LookupSearchResult(grp.Id, null, groupIcon, grp.Name, 'Queue • '+ grp.Name));
            }
        }
        else if(type == 'Permission Set'){
            for(PermissionSet PermSet : [Select Id, Label, IsOwnedByProfile  from PermissionSet where Label like :searchString AND IsOwnedByProfile = FALSE ORDER BY Label LIMIT :MAX_RESULTS]){
                results.add(new Noti5_LookupSearchResult(PermSet.Id, null, groupIcon, PermSet.Label, 'Permission Set • '+ PermSet.Label));
            }
        }
        

        return results;
    }
}