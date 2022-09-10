//
//  FirebaseReference.swift
//  TicTacToe
//
//  Created by Ethan Bootehsaz on 7/27/22.
//

import Firebase

enum FCollectionReference: String {
    case Game
}

func FirebaseReference(_ collectionReference: FCollectionReference) -> CollectionReference {
    return Firestore.firestore().collection(collectionReference.rawValue)
}
