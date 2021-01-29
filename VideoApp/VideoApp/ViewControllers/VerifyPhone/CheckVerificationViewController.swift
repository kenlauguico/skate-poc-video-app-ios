//
//  Copyright (C) 2021 Twilio, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

class CheckVerificationViewController: UIViewController {
    
    @IBOutlet var codeField: UITextField! = UITextField()
    @IBOutlet var errorLabel: UILabel! = UILabel()
    
    var countryCode: String?
    var phoneNumber: String?
    var resultMessage: String?
    
    @IBAction func validateCode() {
        self.errorLabel.text = nil // reset
        if let code = codeField.text {
            VerifyAPI.validateVerificationCode(self.countryCode!, self.phoneNumber!, code) { checked in
                if (checked.success) {
                    self.resultMessage = checked.message
                    self.performSegue(withIdentifier: "checkResultSegue", sender: nil)
                } else {
                    self.errorLabel.text = checked.message
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "checkResultSegue",
            let dest = segue.destination as? VerificationResultViewController {
            dest.message = resultMessage
        }
    }
}
