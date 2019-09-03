# FIXME `ListOfVariableIndices` is not modified by bridges
#       see https://github.com/JuliaOpt/MathOptInterface.jl/issues/693
#    MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[1.0], [0.0], [0.0]],
#                                                                [1.0]),
#                                  (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[1.0], [0.0], [0.0]],
#                                                                [1.0]),
#                                  (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[0.0], [0.0], [1.0], [0.0]],
#                                                                [2.0]),
#                                  (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[0.0], [0.0], [2.0], [0.0]],
#                                                                [2.0]),
#                                  (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[0.0], [1.0], [0.0], [0.0]],
#                                                                [54.4045, 1.0]),
#                                  (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[0.0], [2.0], [0.0]],
#                                                                [61.2652, 1.0]),
#                                  (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[0.0], [0.0], [2.0]],
#                                                                [79.6537, 2.0]),
#                                  (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[0.0], [1.0], [1.0], [0.0]],
#                                                                [30.9277, 1.5, -0.5]))
#    MOIT.linear1test(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[1.0], [0.0], [0.0]],
                                                            [1.0]))
MOIT.linear2test(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[3.0], [0.0]],
                                                            [-1.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [3.0]],
                                                            [-0.0]))
MOIT.linear3test(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [0.0]],
                                                            [-0.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [0.0]],
                                                            [-0.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [0.0]],
                                                            [-0.0]))
MOIT.linear4test(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[1.3333], [1.3333], [0.0], [0.0]],
                                                            [0.3333, 0.3333]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[2.0], [0.0], [0.0], [2.0]],
                                                            [0.5, -0.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[4.0], [0.0], [0.0]],
                                                            [1.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[2.0], [0.0]],
                                                            [0.5]))
MOIT.linear5test(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [0.0], [0.0 0.0; 0.0 0.0], [0.0 0.0; 0.0 0.0]],
                                                            [-1.0, 1.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [0.0], [168.953 0.0; 0.0 68.9528], [107.78 0.0; 0.0 107.78]],
                                                            [-1.0, 1.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [0.0], [250.152 0.0; 0.0 150.152], [150.152 0.0; 0.0 250.152]],
                                                            [-1.0, 1.0]))
MOIT.linear6test(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [0.0], [0.0 0.0; 0.0 0.0], [0.0 0.0; 0.0 0.0]],
                                                            [-1.0, 1.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [0.0], [168.953 0.0; 0.0 68.9528], [107.78 0.0; 0.0 107.78]],
                                                            [-1.0, 1.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [0.0], [250.152 0.0; 0.0 150.152], [150.152 0.0; 0.0 250.152]],
                                                            [-1.0, 1.0]))
MOIT.linear7test(bridged, config)

MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            MOI.INFEASIBLE,
                                                            tuple(),
                                                            [1.0]))
MOIT.linear8atest(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            MOI.DUAL_INFEASIBLE,
                                                            (MOI.INFEASIBILITY_CERTIFICATE, [[0.7709], [0.2291], [0.3126]])))
MOIT.linear8btest(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            MOI.DUAL_INFEASIBLE,
                                                            (MOI.INFEASIBILITY_CERTIFICATE, [[0.5], [0.5]])))
MOIT.linear8ctest(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[29.0909], [36.3636], [4.5455], [0.0], [0.0001]],
                                                            [-0.0, 11.3636, 0.8636]))
MOIT.linear9test(bridged, config)
# FIXME 5 <= x + y <= 10 is bridged into x + y - z == 0, 5 <= z <= 10 and
# then it tries to add two SingleVariable constraints to `z`. We should drop
# support for MOI.LessThan once variables bridges works.
#    MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[5.0], [5.0], [5.0], [0.0]],
#                                                                [-0.0, 1.0]),
#                                  (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[2.5], [2.5], [0.0], [5.0]],
#                                                                [-1.0, 0.0]),
#                                  (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[1.0], [1.0], [0.0], [10.0]],
#                                                                [-1.0, -0.0]),
#                                  (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[6.0], [6.0], [10.0], [0.0]],
#                                                                [-0.0, 1.0]))
#    MOIT.linear10test(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[1.0], [0.0], [3.2439 0.0; 0.0 2.2439], [3.2439 0.0; 0.0 2.2439]],
                                                            [0.0, -1.0]),
                              (mock) -> MOIU.mock_optimize!(mock,
                                                            [[0.0], [1.0], [1.3765 0.0; 0.0 0.8765], [1.3765 0.0; 0.0 0.8765]],
                                                            [-1.0, 0.0]))
MOIT.linear11test(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            MOI.INFEASIBLE,
                                                            tuple(),
                                                            [1.0, 3.0]))
MOIT.linear12test(bridged, config)
MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
                                                            [[24.0266], [27.6758 0.0; 0.0 22.6705], [27.6758 0.0; 0.0 22.6705]],
                                                            [0.0, 0.0]))
MOIT.linear13test(bridged, config)
# FIXME z >= 0.0 followed by z <= 1.0. We need to drop support for
#       SingleVariable-in-LessThan but we need variable bridge otherwise,
#       it creates a slack
#    MOIU.set_mock_optimize!(mock, (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[0.0], [0.5], [1.0], [0.0], [0.0]],
#                                                                [2.0, 1.0]),
#                                  (mock) -> MOIU.mock_optimize!(mock,
#                                                                [[1.0], [0.0]],
#                                                                [1.0]))
#    MOIT.linear14test(bridged, config)
