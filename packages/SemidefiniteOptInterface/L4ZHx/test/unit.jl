MOIT.add_variable(bridged, config)
MOIT.add_variables(bridged, config)
MOIT.delete_variable(bridged, config)
MOIT.delete_variable(bridged, config)
MOIT.feasibility_sense(bridged, config)
MOIT.getconstraint(bridged, config)
MOIT.getvariable(bridged, config)
MOIT.max_sense(bridged, config)
MOIT.min_sense(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [0.0 0; 0 0.0]],
                                                            [1.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[1.0], [0.0], [0.624034 0; 0 0.624034]],
                                                            [0.0, 1.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [2.73683 0; 0 1.73683]],
                                                            [1.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[1.88804e-9], [1.0], [3.25375 0; 0 2.25375]],
                                                            [1.0, 0.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [4.47626 0; 0 2.47626]],
                                                            [1.0]))
MOIT.solve_affine_deletion_edge_cases(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[1.72037 0; 0 1.22037]],
                                                            [-0.5]))
MOIT.solve_affine_equalto(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [2.10102 0; 0 1.60102]],
                                                            [-0.5]))
MOIT.solve_affine_greaterthan(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[3.0], [0.0], [4.88931 0; 0 2.88931]],
                                                            [0.0, 1.5]))
MOIT.solve_affine_interval(MOIB.SplitInterval{Float64}(bridged), config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [2.06719 0; 0 1.56719]],
                                                            [0.5]))
MOIT.solve_affine_lessthan(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0]],
                                                            [0.0]))
MOIT.solve_constant_obj(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0]],
                                                            [0.0]))
MOIT.solve_singlevariable_obj(bridged, config)
# FIXME x >= 1.0 followed by x <= 2.0. We need to drop support for
#       SingleVariable-in-LessThan but we need variable bridge otherwise,
#       it creates a slack
#    MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[0.0], [1.0]],
#                                                                [0.0]))
#    MOIT.solve_with_lowerbound(bridged, config)
# FIXME x <= 1.0 followed by x >= 0.0. We need to drop support for
#       SingleVariable-in-LessThan but we need variable bridge otherwise,
#       it creates a slack
#    MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[1.0], [0.0]],
#                                                                [2.0]))
#    MOIT.solve_with_upperbound(bridged, config)
MOIT.variablenames(bridged, config)
