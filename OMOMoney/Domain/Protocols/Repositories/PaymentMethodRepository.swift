//
//  PaymentMethodRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Repository protocol for PaymentMethod domain operations
/// Abstracts the data source implementation from business logic
protocol PaymentMethodRepository {
    /// Fetch all payment methods
    /// - Returns: Array of PaymentMethodDomain objects
    /// - Throws: Repository errors
    func fetchPaymentMethods() async throws -> [PaymentMethodDomain]
    
    /// Fetch a specific payment method by ID
    /// - Parameter id: PaymentMethod UUID
    /// - Returns: PaymentMethodDomain object if found
    /// - Throws: Repository errors
    func fetchPaymentMethod(id: UUID) async throws -> PaymentMethodDomain?
    
    /// Fetch payment methods for a specific group
    /// - Parameter groupId: Group UUID
    /// - Returns: Array of PaymentMethodDomain objects
    /// - Throws: Repository errors
    func fetchPaymentMethods(forGroupId groupId: UUID) async throws -> [PaymentMethodDomain]
    
    /// Fetch only active payment methods
    /// - Returns: Array of active PaymentMethodDomain objects
    /// - Throws: Repository errors
    func fetchActivePaymentMethods() async throws -> [PaymentMethodDomain]
    
    /// Create a new payment method
    /// - Parameters:
    ///   - name: Payment method name
    ///   - type: Type of payment (card, cash, etc.)
    ///   - isActive: Whether the payment method is active
    ///   - groupId: Associated group ID
    /// - Returns: Created PaymentMethodDomain object
    /// - Throws: Repository errors or validation errors
    func createPaymentMethod(
        name: String,
        type: String,
        icon: String,
        color: String,
        isActive: Bool,
        isDefault: Bool,
        groupId: UUID?
    ) async throws -> PaymentMethodDomain
    
    /// Update an existing payment method
    /// - Parameter paymentMethod: PaymentMethodDomain object with updated values
    /// - Throws: Repository errors
    func updatePaymentMethod(_ paymentMethod: PaymentMethodDomain) async throws
    
    /// Delete a payment method by ID
    /// - Parameter id: PaymentMethod UUID to delete
    /// - Throws: Repository errors
    func deletePaymentMethod(id: UUID) async throws
}
