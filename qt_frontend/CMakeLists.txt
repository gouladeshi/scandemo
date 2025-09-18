cmake_minimum_required(VERSION 3.16)
project(ScanDemoFrontend)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 查找 Qt5 组件
find_package(Qt5 REQUIRED COMPONENTS Core Widgets Network)

# 设置 Qt5 的 MOC、UIC、RCC 自动处理
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

# 源文件
set(SOURCES
    main.cpp
    mainwindow.cpp
    barcodescanner.cpp
    statsdisplay.cpp
    apiclient.cpp
)

# 头文件
set(HEADERS
    mainwindow.h
    barcodescanner.h
    statsdisplay.h
    apiclient.h
)


# 创建可执行文件（当前项目未使用 .ui 文件）
add_executable(ScanDemoFrontend ${SOURCES} ${HEADERS})

# 链接 Qt5 库
target_link_libraries(ScanDemoFrontend
    Qt5::Core
    Qt5::Widgets
    Qt5::Network
)

# 设置输出目录
set_target_properties(ScanDemoFrontend PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)
