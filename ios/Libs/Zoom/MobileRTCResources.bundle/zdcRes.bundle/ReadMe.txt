//
//  ReadMe.txt
//  whiteboard
//
//  Created by Michael Yuan on 2022/01/24.
//  Copyright © 2022 Zoom. All rights reserved.
//

1. All cloud whiteboard icons should be managed by zdcRes.bundle

2. If any changes for the zdcRes resources, please re-build the target 'zdcRes' in whiteboard.xcodeproj, or re-build the whiteboard.xcodeproj directly.

3. !!!IMPLANTANT!!! Add script job in main project.(main project target -> Build Phases -> Add Script). Otherwise, the resource bundle cannot be moved to the main bundle.

4. After re-build, the 'zdcRes.bundle' is moved to main bundle
