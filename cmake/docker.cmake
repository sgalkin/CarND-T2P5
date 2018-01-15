set(DOCKER_IMAGE sgalkin/${CMAKE_PROJECT_NAME}-env)
set(DOCKER_BUILD docker build ${CMAKE_SOURCE_DIR}/docker --pull --force-rm -t ${DOCKER_IMAGE})
set(DOCKER_NAME cmake-${CMAKE_PROJECT_NAME}-env)
set(DOCKER_MOUNT -v ${CMAKE_SOURCE_DIR}:/repo:ro) # -v ${CMAKE_BINARY_DIR}:/build")
set(DOCKER_RUN docker run --rm -d -ti ${DOCKER_MOUNT} --name ${DOCKER_NAME} ${DOCKER_IMAGE})

add_custom_target(
  build-docker-env
  test ${CMAKE_BINARY_DIR}/container.stamp -nt ${CMAKE_SOURCE_DIR}/docker/Dockerfile ||
  (docker stop ${DOCKER_NAME} || true && ${DOCKER_BUILD})
  COMMAND touch ${CMAKE_BINARY_DIR}/container.stamp
  DEPENDS ${CMAKE_SOURCE_DIR}/docker/Dockerfile
  SOURCES ${CMAKE_SOURCE_DIR}/docker/Dockerfile)


add_custom_target(
  start-docker-env
  COMMAND docker ps -f name=${DOCKER_NAME} | grep -q ${DOCKER_NAME} || ${DOCKER_RUN}
  DEPENDS build-docker-env)

add_custom_target(
  stop-docker-env docker stop ${DOCKER_NAME})


add_custom_target(docker-build
  COMMAND docker exec -ti ${DOCKER_NAME} sh -c \"test -f CMakeCache.txt || cmake /repo\"
  COMMAND docker exec -ti ${DOCKER_NAME} make -j 
  COMMAND docker exec -ti ${DOCKER_NAME} ctest
  DEPENDS start-docker-env)

add_custom_target(docker-shell
  COMMAND docker exec -ti ${DOCKER_NAME} bash
  DEPENDS start-docker-env)
