if(BUILD_EXAMPLES)
    add_executable(walking_skeleton
        walking_skeleton/main.c
    )
    # Link against the protocol library when it exists:
    # target_link_libraries(walking_skeleton PRIVATE ${PROJECT_NAME})
endif()
