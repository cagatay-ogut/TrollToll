//
//  UserRepo.swift
//  TrollToll
//
//  Created by Cagatay on 1.01.2026.
//

protocol UserRepo {
    var user: User? { get set }

    func getUser(with id: String) async throws
    func saveUser(with id: String, and name: String) async throws
}
