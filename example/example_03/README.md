# app3_custom_painter


# Todos
-    Resolve [1]:
   E/flutter ( 4866): This error happens if you call setState() on a State object for a widget that no longer appears in the widget tree (e.g., whose parent widget no longer
   includes the widget in its build). This error can occur when code calls setState() from a timer or an animation callback. The preferred solution is to cancel the timer o
   r stop listening to the animation in the dispose() callback. Another solution is to check the "mounted" property of this object before calling setState() to ensure the ob
   ject is still in the tree.
   E/flutter ( 4866): This error might indicate a memory leak if setState() is being called because another object is retaining a reference to this State object after it has
   been removed from the tree. To avoid memory leaks, consider breaking the reference to this object during dispose().
   E/flutter ( 4866): #0      State.setState.<anonymous closure> (package:flutter/src/widgets/framework.dart:1103:9)
   Resolve [2]:
   Try to store all widgets in a persistent list and only recreate those who need it


