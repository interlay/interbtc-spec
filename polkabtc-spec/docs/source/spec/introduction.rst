How to read this specification
==============================

This specification is a living document. The actual implementation might deviate from the specification. In case of deviations in the code, the code has priority over the specification.

Return types
~~~~~~~~~~~~

Return types MAY return be wrapped in a ``Result`` type, in order to be able to return an error in case of failure. That is, when a return type is described as ``T``, it MAY actually return a value of type ``Result<T, DispatchError>``.

Preconditions, Postconditions and Invariants
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Preconditions are condition that must hold before the function is executed. Unless otherwise stated, if the precondition does not hold, the function MUST return an error. If the function is a dispatchable function (i.e. callable by users), then if the function returns an error, it MUST NOT make any changes to the storage. The postconditions describe the changes the function MAY make to the storage. Additionally, it describes the return value of the function, if any. Invariants describe conditions that must hold both before and after the execution, but the function might not check whether the invariant holds prior to execution if the code assures that it always holds.

Errors and Events
~~~~~~~~~~~~~~~~~

Error listed in the function specification are not necessarily exhaustive - a function MAY return errors not listed. Similarly, events listed in the function specification are not necessarily exhaustive - a function MAY emit other events.


