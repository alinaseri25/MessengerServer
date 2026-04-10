cmake_minimum_required(VERSION 3.16)

# ✅ خواندن VERSION از فایل
file(READ "${CMAKE_SOURCE_DIR}/version.txt" VERSION_STRING)
string(STRIP "${VERSION_STRING}" VERSION_STRING)

# ✅ تجزیه version به اجزای MAJOR.MINOR.PATCH
string(REPLACE "." ";" VERSION_LIST ${VERSION_STRING})
list(GET VERSION_LIST 0 VERSION_MAJOR)
list(GET VERSION_LIST 1 VERSION_MINOR)
list(GET VERSION_LIST 2 VERSION_PATCH)

# ✅ محاسبه versionCode (مثلاً: 1.3.0 → 10300)
math(EXPR VERSION_CODE "${VERSION_MAJOR} * 10000 + ${VERSION_MINOR} * 100 + ${VERSION_PATCH}")

project(MessengerServer VERSION ${VERSION_STRING} LANGUAGES CXX)

configure_file(version.h.in version.h @ONLY)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(OPENSSL_ROOT_DIR    "C:/vcpkg/packages/openssl_x64-mingw-dynamic")
set(OPENSSL_INCLUDE_DIR "C:/vcpkg/packages/openssl_x64-mingw-dynamic/include")
set(OPENSSL_CRYPTO_LIBRARY "C:/vcpkg/packages/openssl_x64-mingw-dynamic/lib/libcrypto.dll.a")
set(OPENSSL_SSL_LIBRARY    "C:/vcpkg/packages/openssl_x64-mingw-dynamic/lib/libssl.dll.a")

find_package(Qt6 REQUIRED COMPONENTS Quick Network Sql)
find_package(OpenSSL REQUIRED)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(MessengerServer
    main.cpp
    backend.h
    backend.cpp
    server.h
    server.cpp
    connections.h connections.cpp
    packetStructs.h
    equipment.h equipment.cpp
    entity.h entity.cpp
    session.h session.cpp
    tlscertificategenerator.h tlscertificategenerator.cpp
#    securesession.h securesession.cpp
)

# ✅ استفاده از qt6_add_resources بجای qt_add_qml_module
qt6_add_resources(MessengerServer "qmlchartsgallery"
    PREFIX "/"
    FILES
        Main.qml
        CComponents/CButton.qml
        StatusIndicator.qml
        icons/icon.png
        version.txt
)


# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(MessengerServer PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.MessengerServer
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(MessengerServer
    PRIVATE Qt6::Quick Qt6::Network Qt6::Sql
    PRIVATE OpenSSL::SSL OpenSSL::Crypto
)

target_include_directories(MessengerServer PRIVATE ${CMAKE_BINARY_DIR})

include(GNUInstallDirs)
install(TARGETS MessengerServer
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
