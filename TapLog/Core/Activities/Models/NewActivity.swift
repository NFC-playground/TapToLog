//
//  NewActivity.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/10/26.
//


// ONLY USED FOR INSERTING a NEW ACTIVITY
// db fills in created_at and id so we leave them out here
// only encodeable because pp only SENDS it and never decodes it
// no id so no Identifiable
import Foundation

struct NewActivity: Encodable{
    let name: String
    let activityDescription: String?
    let userId: UUID
    
    // COdingKey used for mapping to JSON key to match DB
    enum CodingKeys: String, CodingKey {
        case name
        case activityDescription = "activity_description"
        case userId = "user_id"
        
    }
}
