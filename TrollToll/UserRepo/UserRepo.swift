//
//  UserRepo.swift
//  TrollToll
//
//  Created by Cagatay on 1.01.2026.
//

protocol UserRepo {
    func getUser(with id: String) async throws -> User
    func saveUser(with id: String, and name: String) async throws -> User
}
