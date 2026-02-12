//
//  FamilyMemberBuilder.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 07.08.20.
//

/// A result builder for constructing family member component collections.
///
/// This builder is used to provide a DSL-like syntax for creating family members
/// with the required components in a type-safe manner.
@resultBuilder
public enum FamilyMemberBuilder<R: FamilyRequirementsManaging>: Sendable {}
