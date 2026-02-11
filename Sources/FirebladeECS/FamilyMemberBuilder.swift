//
//  FamilyMemberBuilder.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 07.08.20.
//

#if swift(<5.4)
@_functionBuilder
public enum FamilyMemberBuilder<R> where R: FamilyRequirementsManaging {}
#else
@resultBuilder
public enum FamilyMemberBuilder<R>: Sendable where R: FamilyRequirementsManaging {}
#endif
