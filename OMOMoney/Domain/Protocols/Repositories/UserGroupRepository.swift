import Foundation

protocol UserGroupRepository {
    func fetchUserGroups() async throws -> [SDUserGroup]
    func fetchUserGroup(id: UUID) async throws -> SDUserGroup?
    func fetchUserGroups(forUserId userId: UUID) async throws -> [SDUserGroup]
    func fetchUserGroups(forGroupId groupId: UUID) async throws -> [SDUserGroup]
    func createUserGroup(userId: UUID, groupId: UUID, role: String) async throws -> SDUserGroup
    func updateUserGroup(_ userGroup: SDUserGroup) async throws
    func deleteUserGroup(id: UUID) async throws
    func removeUser(_ userId: UUID, fromGroup groupId: UUID) async throws
}
