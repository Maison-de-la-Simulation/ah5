# Ah5

Ah5 (Asynchronous HDF5) is a library enabling the use of a dedicated thread to
write HDF5 files in an asynchronous fashion.

## Usage

There are two ways you can use Ah5 from your project:
*  **In-place**: you can include Ah5 in your project and use it directly from
   there,
*  **Dependancy**: or you can use Ah5 as an external dependancy of your
   project.

Support is provided for using Ah5 from Cmake based projects, but you can use
it from plain Makefiles too.

### In-place usage

Using Ah5 in-place is very simple, just use add_subdirectory from cmake.

### Dependancy usage

Using Ah5 as a dependancy is very simple too, just use find_package from cmake.
You can use a system-wide installed Ah5 or you can just configure Ah5 as a
user, without installation. It should be found anyway.

## Installation

Installing Ah5 is very simple. Inside the Ah5 directory, execute the
following commands:
```
cmake .
make install
```

In order to change the installation path for your project, set the
CMAKE_INSTALL_PREFIX cmake parameter:
```
cmake -DCMAKE_INSTALL_PREFIX=/usr .
```
