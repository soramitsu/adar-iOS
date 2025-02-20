/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import FearlessUtils

extension DrawableIcon {
    func imageWithFillColor(_ color: UIColor, size: CGSize, contentScale: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, contentScale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        drawInContext(context, fillColor: color, size: size)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
