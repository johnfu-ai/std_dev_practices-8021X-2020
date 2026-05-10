cmake_minimum_required(VERSION 3.16)

project(std_dev_practices_8021X_2020
    VERSION 0.1.0
    DESCRIPTION "IEEE 802.1X-2020 lifecycle documentation and tooling hub"
    LANGUAGES NONE
)

option(BUILD_DOCS "Build repository documentation with Doxygen" OFF)

message(STATUS
    "This repository contains lifecycle documentation and tooling only. "
    "Build IEEE 802.1X-2020 implementation code in ../wpa_supplicant-8021X-2020 "
    "using the wpa_supplicant Makefile."
)

if(BUILD_DOCS)
    find_package(Doxygen REQUIRED)
    doxygen_add_docs(lifecycle_docs
        ${CMAKE_CURRENT_SOURCE_DIR}/docs
        ${CMAKE_CURRENT_SOURCE_DIR}/01-stakeholder-requirements
        ${CMAKE_CURRENT_SOURCE_DIR}/02-requirements
        ${CMAKE_CURRENT_SOURCE_DIR}/03-architecture
        ${CMAKE_CURRENT_SOURCE_DIR}/04-design
        ${CMAKE_CURRENT_SOURCE_DIR}/05-implementation
        ${CMAKE_CURRENT_SOURCE_DIR}/06-integration
        ${CMAKE_CURRENT_SOURCE_DIR}/07-verification-validation
        ${CMAKE_CURRENT_SOURCE_DIR}/08-transition
        ${CMAKE_CURRENT_SOURCE_DIR}/09-operation-maintenance
        COMMENT "Generate lifecycle documentation"
    )
endif()
