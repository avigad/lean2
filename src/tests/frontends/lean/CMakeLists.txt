add_executable(lean_scanner scanner.cpp ${LEAN_OBJS})
target_link_libraries(lean_scanner ${EXTRA_LIBS})
add_test(lean_scanner "${CMAKE_CURRENT_BINARY_DIR}/lean_scanner")
# add_executable(lean_parser parser.cpp)
# target_link_libraries(lean_parser ${ALL_LIBS})
# add_test(lean_parser "${CMAKE_CURRENT_BINARY_DIR}/lean_parser")
# # add_executable(lean_pp pp.cpp)
# target_link_libraries(lean_pp ${ALL_LIBS})
# add_test(lean_pp "${CMAKE_CURRENT_BINARY_DIR}/lean_pp")
