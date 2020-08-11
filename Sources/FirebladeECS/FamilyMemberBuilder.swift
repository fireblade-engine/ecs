//
//  FamilyMemberBuilder.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 07.08.20.
//

@_functionBuilder
public enum FamilyMemberBuilderPreview<R> where R: FamilyRequirementsManaging { }
public typealias FamilyMemberBuilder<R> = FamilyMemberBuilderPreview<R> where R: FamilyRequirementsManaging
