//
//  DataService.swift
//  Breakpoint
//
//  Created by Osama on 08/12/2017.
//  Copyright © 2017 Osama. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

let DB_BASE = Database.database().reference()

class DataService {
    static var instance = DataService()
    
    private let _REF_BASE = DB_BASE
    private let _REF_USERS = DB_BASE.child("users")
    private let _REF_GROUPS = DB_BASE.child("groups")
    private let _REF_FEEDS = DB_BASE.child("feeds")
    
    var REF_BASE: DatabaseReference {
        return _REF_BASE
    }
    
    var REF_USERS: DatabaseReference {
        return _REF_USERS
    }
    
    var REF_GROUPS: DatabaseReference {
        return _REF_GROUPS
    }
    
    var REF_FEEDS: DatabaseReference {
        return _REF_FEEDS
    }
    
    func createNewUser(uid: String, userData: Dictionary<String, Any>){
       REF_USERS.child(uid).updateChildValues(userData)
    }
    
    func createPost(withMessage message: String, forUID uid: String, withGroupKey groupKey: String?, completion: @escaping PostCompletionHandler){
        
        if groupKey != nil {
            let feedData = [MESSAGE_KEY: message, UID_KEY: uid]
            
            REF_GROUPS.child(groupKey!).child(FIR_MESSAGE_IDENTIFIER).childByAutoId().updateChildValues(feedData)
            
            completion(true)
        }else{
            let feedData = [MESSAGE_KEY: message, UID_KEY: uid]
            
            REF_FEEDS.childByAutoId().updateChildValues(feedData)
            
            completion(true)
        }
    }
    
    func getAllFeedMessages(completion: @escaping MessageCompletionHandler){
        
        REF_FEEDS.observeSingleEvent(of: .value, with: { (feedMessageSnapshot) in
            
            guard let feedMessageSnapshot = feedMessageSnapshot.children.allObjects as? [DataSnapshot] else {
                return
            }
            
            var messageArray = [Message]()
            
            for message in feedMessageSnapshot {
                let content = message.childSnapshot(forPath: MESSAGE_KEY).value as! String
                
                let senderId = message.childSnapshot(forPath: UID_KEY).value as! String
                
                let message = Message(msgContent: content, senderId: senderId)
                
                messageArray.append(message)
            }
            
            completion(messageArray)
        })
    }
    
    func getAllFeedMessagesFor(desiredGroup group: Group, completion: @escaping (_ messagesArray: [Message]) -> ()){
        
        var messageArray = [Message]()
        
        REF_GROUPS.child(group.id).child(FIR_MESSAGE_IDENTIFIER).observeSingleEvent(of: .value, with: { (groupMessagesSnapshot) in
            
            //print("1")
            
            guard let groupMessagesSnapshot = groupMessagesSnapshot.children.allObjects as? [DataSnapshot] else {
                return
            }
            
            //print("2")
            
            //var i=0
            
            for groupMessage in groupMessagesSnapshot {
                let messageContent = groupMessage.childSnapshot(forPath: MESSAGE_KEY).value as! String
                let userUID = groupMessage.childSnapshot(forPath: UID_KEY).value as! String
                
                let groupMessage = Message(msgContent: messageContent, senderId: userUID)
                
                messageArray.append(groupMessage)
                
                //print(messageArray[i].msgContent)
                //i += 1
            }
        
            completion(messageArray)
        })
    }
    
    func getEmail(forUID uid: String, completion: @escaping (_ email: String) -> ()){
        REF_USERS.observeSingleEvent(of: .value, with: { (userSnapshot) in
            
            guard let userSnapshot = userSnapshot.children.allObjects as? [DataSnapshot] else {
                return
            }
            
            for user in userSnapshot {
                if user.key == uid {
                    let email = user.childSnapshot(forPath: EMAIL_KEY).value as! String
                    
                    completion(email)
                    return
                }
            }
        })
    }
    
    func getEmails(forSearchQuery query: String, completion: @escaping (_ users: [String]) -> ()){
        
        var emailsArray = [String]()
        
        REF_USERS.observeSingleEvent(of: .value, with: { (usersSnapshot) in
            
            guard let userSnapshot = usersSnapshot.children.allObjects as? [DataSnapshot] else {
                return
            }
            
            for user in userSnapshot {
                let email = user.childSnapshot(forPath: EMAIL_KEY).value as! String
                
                if email.contains(query) && email != Auth.auth().currentUser!.email {
                    emailsArray.append(email)
                }
            }
            
            completion(emailsArray)
        })
    }
    
    func getUserIds(forEmails emailsArray: [String], completion: @escaping (_ userIds: [String]) -> ()){
        
        var userIdsArray = [String]()
        
        REF_USERS.observe(.value, with: { (usersSnapshot) in
            guard let usersSnapshot = usersSnapshot.children.allObjects as? [DataSnapshot] else {
                return
            }
        
            for user in usersSnapshot {
                let email = user.childSnapshot(forPath: EMAIL_KEY).value as! String
                
                if emailsArray.contains(email) {
                    userIdsArray.append(user.key)
                }
            }
            
            completion(userIdsArray)
        })
    }
    
    func createGroup(withTitle title: String, andDescription desc: String, withUserIds usersIds: [String], completion: @escaping (_ success: Bool) -> ()){
        
        REF_GROUPS.childByAutoId().updateChildValues([TITLE_KEY: title, DESCRIPTION_KEY: desc, GROUP_MEMBERS_KEY: usersIds])
        
        completion(true)
    }
    
    func getGroups(completion: @escaping ([Group]) -> ()){
        var groupsArray = [Group]()
        
        REF_GROUPS.observeSingleEvent(of: .value, with: { (groupsSnapshot) in
        
            guard let groupsSnapshot = groupsSnapshot.children.allObjects as? [DataSnapshot] else {
                return
            }
            
            for group in groupsSnapshot {
                let groupMembersArray = group.childSnapshot(forPath: GROUP_MEMBERS_KEY).value as! [String]
                
                if groupMembersArray.contains(Auth.auth().currentUser!.uid) {
                    
                    //print("Group Members Array: \(groupMembersArray)")
                    
                    //print("Current UID: \(Auth.auth().currentUser!.uid)")
                    
                    let id = group.key
                    let groupTitle = group.childSnapshot(forPath: TITLE_KEY).value as! String
                    let groupDescription = group.childSnapshot(forPath: DESCRIPTION_KEY).value as! String
                    
                    let groupMembersCount = groupMembersArray.count
                    
                    let group = Group(_id: id, _title: groupTitle, _description: groupDescription, _memberCount: groupMembersCount, _membersArray: groupMembersArray)
                    
                    groupsArray.append(group)
                    
                    //print("groupMembersCount: \(groupMembersCount)")
                }
                
                
            }
            
            completion(groupsArray)
        })
    }
}
