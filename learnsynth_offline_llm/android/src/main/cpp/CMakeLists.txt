cmake_minimum_required(VERSION 3.22.1)
project(learnsynth_offline_llm)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(learnsynth_offline_llm SHARED
    native-lib.cpp
)

# integra llama.cpp (vendorizada en third_party/llama.cpp)
if(NOT DEFINED LLAMA_DIR)
  set(LLAMA_DIR "${CMAKE_CURRENT_LIST_DIR}/third_party/llama.cpp")
endif()
if(NOT EXISTS "${LLAMA_DIR}/CMakeLists.txt")
  message(FATAL_ERROR "llama.cpp no encontrado en: ${LLAMA_DIR}")
endif()

# Desactiva extras y evita flags 'nativos' del host al cross-compilar
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS   OFF CACHE BOOL "" FORCE)
set(LLAMA_METAL   OFF CACHE BOOL "" FORCE)
set(LLAMA_VULKAN  OFF CACHE BOOL "" FORCE)
set(LLAMA_CUBLAS  OFF CACHE BOOL "" FORCE)
set(LLAMA_CLBLAST OFF CACHE BOOL "" FORCE)
set(LLAMA_MPI     OFF CACHE BOOL "" FORCE)
set(LLAMA_RPC     OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE   OFF CACHE BOOL "" FORCE)

add_subdirectory(${LLAMA_DIR} llama-build)

find_library(log-lib log)

if (TARGET llama)
  target_link_libraries(learnsynth_offline_llm PRIVATE llama ggml ggml-base ggml-cpu ${log-lib})
elseif (TARGET llama_static)
  target_link_libraries(learnsynth_offline_llm PRIVATE llama_static ggml ggml-base ggml-cpu ${log-lib})
else()
  message(FATAL_ERROR "No se encontró el target 'llama' ni 'llama_static'")
endif()

# Fallbacks por si no los define ggml (evita error GGML_VERSION/COMMIT)
foreach(t IN ITEMS llama llama_static)
  if (TARGET ${t})
    target_compile_definitions(${t} PRIVATE GGML_VERSION="0.0.0" GGML_COMMIT="unknown")
  endif()
endforeach()

target_include_directories(learnsynth_offline_llm PRIVATE
  ${LLAMA_DIR}/include
  ${LLAMA_DIR}/ggml/include
)
