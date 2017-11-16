+------------------------------------------+--------+-------------+------------------------+-------------+---------------+
| identifier                               | opt-in | correctable | enabled in your config | kind        | configuration |
+------------------------------------------+--------+-------------+------------------------+-------------+---------------+
| array_init                               | yes    | no          | yes                    | lint        | warning       |
| attributes                               | yes    | no          | yes                    | style       | warning, a... |
| block_based_kvo                          | no     | no          | yes                    | idiomatic   | warning       |
| class_delegate_protocol                  | no     | no          | yes                    | lint        | warning       |
| closing_brace                            | no     | yes         | yes                    | style       | warning       |
| closure_end_indentation                  | yes    | no          | yes                    | style       | warning       |
| closure_parameter_position               | no     | no          | yes                    | style       | warning       |
| closure_spacing                          | yes    | yes         | yes                    | style       | warning       |
| colon                                    | no     | yes         | yes                    | style       | warning, f... |
| comma                                    | no     | yes         | yes                    | style       | warning       |
| compiler_protocol_init                   | no     | no          | yes                    | lint        | warning       |
| conditional_returns_on_newline           | yes    | no          | no                     | style       | warning       |
| contains_over_first_not_nil              | yes    | no          | no                     | performance | warning       |
| control_statement                        | no     | no          | yes                    | style       | warning       |
| custom_rules                             | no     | no          | yes                    | style       | user-defin... |
| cyclomatic_complexity                    | no     | no          | yes                    | metrics     | warning: 1... |
| discarded_notification_center_observer   | no     | no          | yes                    | lint        | warning       |
| discouraged_direct_init                  | no     | no          | yes                    | lint        | warning, t... |
| dynamic_inline                           | no     | no          | yes                    | lint        | error         |
| empty_count                              | yes    | no          | yes                    | performance | error         |
| empty_enum_arguments                     | no     | yes         | yes                    | style       | warning       |
| empty_parameters                         | no     | yes         | yes                    | style       | warning       |
| empty_parentheses_with_trailing_closure  | no     | yes         | yes                    | style       | warning       |
| explicit_enum_raw_value                  | yes    | no          | no                     | idiomatic   | warning       |
| explicit_init                            | yes    | yes         | yes                    | idiomatic   | warning       |
| explicit_top_level_acl                   | yes    | no          | no                     | idiomatic   | warning       |
| explicit_type_interface                  | yes    | no          | no                     | idiomatic   | warning       |
| extension_access_modifier                | yes    | no          | yes                    | idiomatic   | warning       |
| fallthrough                              | no     | no          | yes                    | idiomatic   | warning       |
| fatal_error_message                      | yes    | no          | yes                    | idiomatic   | warning       |
| file_header                              | yes    | no          | no                     | style       | warning, r... |
| file_length                              | no     | no          | yes                    | metrics     | warning: 4... |
| first_where                              | yes    | no          | yes                    | performance | warning       |
| for_where                                | no     | no          | yes                    | idiomatic   | warning       |
| force_cast                               | no     | no          | yes                    | idiomatic   | error         |
| force_try                                | no     | no          | yes                    | idiomatic   | error         |
| force_unwrapping                         | yes    | no          | no                     | idiomatic   | warning       |
| function_body_length                     | no     | no          | yes                    | metrics     | warning: 4... |
| function_parameter_count                 | no     | no          | yes                    | metrics     | warning: 5... |
| generic_type_name                        | no     | no          | yes                    | idiomatic   | (min_lengt... |
| identifier_name                          | no     | no          | yes                    | style       | (min_lengt... |
| implicit_getter                          | no     | no          | yes                    | style       | warning       |
| implicit_return                          | yes    | yes         | no                     | style       | warning       |
| implicitly_unwrapped_optional            | yes    | no          | no                     | idiomatic   | warning, m... |
| is_disjoint                              | no     | no          | yes                    | idiomatic   | warning       |
| joined_default_parameter                 | yes    | yes         | no                     | idiomatic   | warning       |
| large_tuple                              | no     | no          | yes                    | metrics     | warning: 2... |
| leading_whitespace                       | no     | yes         | yes                    | style       | warning       |
| legacy_cggeometry_functions              | no     | yes         | yes                    | idiomatic   | warning       |
| legacy_constant                          | no     | yes         | yes                    | idiomatic   | warning       |
| legacy_constructor                       | no     | yes         | yes                    | idiomatic   | warning       |
| legacy_nsgeometry_functions              | no     | yes         | yes                    | idiomatic   | warning       |
| let_var_whitespace                       | yes    | no          | yes                    | style       | warning       |
| line_length                              | no     | no          | yes                    | metrics     | warning: 2... |
| literal_expression_end_indentation       | yes    | no          | yes                    | style       | warning       |
| mark                                     | no     | yes         | yes                    | lint        | warning       |
| multiline_arguments                      | yes    | no          | no                     | style       | warning, f... |
| multiline_parameters                     | yes    | no          | no                     | style       | warning       |
| multiple_closures_with_trailing_closure  | no     | no          | yes                    | style       | warning       |
| nesting                                  | no     | no          | yes                    | metrics     | (type_leve... |
| nimble_operator                          | yes    | yes         | yes                    | idiomatic   | warning       |
| no_extension_access_modifier             | yes    | no          | no                     | idiomatic   | error         |
| no_grouping_extension                    | yes    | no          | no                     | idiomatic   | warning       |
| notification_center_detachment           | no     | no          | yes                    | lint        | warning       |
| number_separator                         | yes    | yes         | yes                    | style       | warning, m... |
| object_literal                           | yes    | no          | yes                    | idiomatic   | warning, i... |
| opening_brace                            | no     | yes         | yes                    | style       | warning       |
| operator_usage_whitespace                | yes    | yes         | yes                    | style       | warning       |
| operator_whitespace                      | no     | no          | yes                    | style       | warning       |
| overridden_super_call                    | yes    | no          | yes                    | lint        | warning, e... |
| override_in_extension                    | yes    | no          | no                     | lint        | warning       |
| pattern_matching_keywords                | yes    | no          | yes                    | idiomatic   | warning       |
| private_outlet                           | yes    | no          | yes                    | lint        | warning, a... |
| private_over_fileprivate                 | no     | yes         | yes                    | idiomatic   | warning, v... |
| private_unit_test                        | no     | no          | yes                    | lint        | warning: X... |
| prohibited_super_call                    | yes    | no          | yes                    | lint        | warning, e... |
| protocol_property_accessors_order        | no     | yes         | yes                    | style       | warning       |
| quick_discouraged_call                   | yes    | no          | no                     | lint        | warning       |
| quick_discouraged_focused_test           | yes    | no          | no                     | lint        | warning       |
| quick_discouraged_pending_test           | yes    | no          | no                     | lint        | warning       |
| redundant_discardable_let                | no     | yes         | yes                    | style       | warning       |
| redundant_nil_coalescing                 | yes    | yes         | yes                    | idiomatic   | warning       |
| redundant_optional_initialization        | no     | yes         | yes                    | idiomatic   | warning       |
| redundant_string_enum_value              | no     | no          | yes                    | idiomatic   | warning       |
| redundant_void_return                    | no     | yes         | yes                    | idiomatic   | warning       |
| return_arrow_whitespace                  | no     | yes         | yes                    | style       | warning       |
| shorthand_operator                       | no     | no          | yes                    | style       | error         |
| single_test_class                        | yes    | no          | no                     | style       | warning       |
| sorted_first_last                        | yes    | no          | no                     | performance | warning       |
| sorted_imports                           | yes    | yes         | yes                    | style       | warning       |
| statement_position                       | no     | yes         | yes                    | style       | (statement... |
| strict_fileprivate                       | yes    | no          | no                     | idiomatic   | warning       |
| superfluous_disable_command              | no     | no          | yes                    | lint        | error         |
| switch_case_alignment                    | no     | no          | yes                    | style       | warning       |
| switch_case_on_newline                   | yes    | no          | no                     | style       | warning       |
| syntactic_sugar                          | no     | no          | yes                    | idiomatic   | warning       |
| todo                                     | no     | no          | yes                    | lint        | warning       |
| trailing_closure                         | yes    | no          | no                     | style       | warning       |
| trailing_comma                           | no     | yes         | yes                    | style       | warning, m... |
| trailing_newline                         | no     | yes         | yes                    | style       | warning       |
| trailing_semicolon                       | no     | yes         | yes                    | idiomatic   | warning       |
| trailing_whitespace                      | no     | yes         | yes                    | style       | warning, i... |
| type_body_length                         | no     | no          | yes                    | metrics     | warning: 2... |
| type_name                                | no     | no          | yes                    | idiomatic   | (min_lengt... |
| unneeded_break_in_switch                 | no     | no          | yes                    | idiomatic   | warning       |
| unneeded_parentheses_in_closure_argument | yes    | yes         | yes                    | style       | warning       |
| unused_closure_parameter                 | no     | yes         | yes                    | lint        | warning       |
| unused_enumerated                        | no     | no          | yes                    | idiomatic   | warning       |
| unused_optional_binding                  | no     | no          | yes                    | style       | warning, i... |
| valid_ibinspectable                      | no     | no          | yes                    | lint        | warning       |
| vertical_parameter_alignment             | no     | no          | yes                    | style       | warning       |
| vertical_parameter_alignment_on_call     | yes    | no          | yes                    | style       | warning       |
| vertical_whitespace                      | no     | yes         | yes                    | style       | warning, m... |
| void_return                              | no     | yes         | yes                    | style       | warning       |
| weak_delegate                            | no     | no          | yes                    | lint        | warning       |
| xctfail_message                          | no     | no          | yes                    | idiomatic   | warning       |
+------------------------------------------+--------+-------------+------------------------+-------------+---------------+
