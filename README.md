HaxeBridges
===========

An experimental library for discrete communication between haxe targets.

Haxe's incredibly powerful compiler allows it to target many platforms, although building different, platform-specific parts of a solution still requires setting up multiple builds (and potentially projects).

Most modern projects require multiple targets to be used (e.g. client/server) or at least multiple executables to be built (e.g. worker threads). Building the interaction code between these multiple processes can be very costly despite it's formulaic nature.

The aim of this project is to consider a standard way of compiling different parts of a single codebase to different target platforms, as well as generating code to facilitate the asychronous communications between the resulting programs.


Use Cases
---------
- Worker/Thread interactions
- Client/Server interactions
- Communication between two or more codebases written for different native platforms

Challenges
----
- Compiling for multiple platforms from a single codebase and compilation command.
- Specifying which code should be run on which platform without building any language barriers between objects/code (i.e. objects should be able to interact in a more-or-less normal OOP manner).
- Generating proxy classes in the other executables (i.e. those which do not contain the class).
- Allowing for threads/connections to be allocated on demand (i.e. when a proxy class is instantiated, it should spawn a new thread or notify the server).
- Potentially using macros to convert synchronous code into asychronous code.

Compiling to multiple platforms at once
----
When specifying bridges to the compiler the following considerations should be taken into account.

Each bridge specified should target a bridge definition (either a class or a definition file) which is read at compile time and specifies a list of available targets. If there are more than one available target and the compilation script has not specified a target, then the main compilation's target should be used (or an error thown if it is unavailable). This will allow JS / Flash worker threads to use the same classes.

The bridge specification must also describe available opposite platforms (these are the platforms from which interaction can originate) and map each of these to a macro class which will generate the proxy classes required in the opposite executable. These classes will be very general, serialising code interactions into whatever format is required and transmitting via the appropriate channel to the worker/server program.

Specifying which classes should act as gateways to another platform
----
Certain classes will act as entry points to the sub-processes. These could either be singleton implementations (as in client to server communication) or regular objects (as in the case of worker threads).

With each bridge specification (for the compiler), a list of these classes should be given. Each of these classes will be included in the bridge executable, along with code to recieve any deserialise code interactions, execute them on the real instances and return results.

Class proxies in opposite executables
----
Proxy classes are added to any other executable which uses/interacts with these objects. These proxy classes collect any interactions, serialise and transmit them to the server/worker and wait for a response.

Allocating additional threads
---
For those classes which are intended to be instantiated (i.e. workers), a mechanism must be built in to the calling process to instantiate new worker threads on demand (i.e. whenever the generated proxy class is instantiated).

Using macros to convert synchronous code to asynchronous code
---
If feasible, it would be beneficial to convert synchronous code to asynchronous.
This will require expression tree analysis to establish what happens with values returned from bridged objects. If return values are not stored or are not used, then the calling method can remain unmodified.

If return values are used further in the calling method but do not influence the return value of the calling method, the return expression can remain as is (i.e. synchronous), but affected expressions should be pushed into a response handler.

If the calling method's return value is influenced by the bridged object's return value, then the method must be modified to only execute it's return statement after recieving a response. This will require the same process to be run on any method which calls the calling method (and so on).

If this amount of function rewriting prooves to be impossible, then proxy class methods should be written to return a "PendingCall" object, and allow the haxe type-checker to prompt the developer to modify their code.


Contact
---
If anyone would like to take help out with this project, please contact me at work@tbyrne.org
