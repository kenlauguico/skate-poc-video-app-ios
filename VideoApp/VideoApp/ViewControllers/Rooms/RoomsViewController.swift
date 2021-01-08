//
//  Copyright (C) 2019 Twilio, Inc.
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

class RoomsViewController: UITableViewController {
    var viewModel: SettingsViewModel!
    
    
    func loadRooms() {
        let login = "AC3d6a6fca89c30fedee4940c46662adeb"
        let password = "8bf98c1f474509091bc9907295c3a169"

        let url = NSURL(string: "https://video.twilio.com/v1/Rooms?Status=in-progress&PageSize=20")
        let request = NSMutableURLRequest(URL: url!)

        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let userPasswordString = "\(login):\(password)"
        let userPasswordData = userPasswordString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64EncodedCredential = userPasswordData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        let authString = "Basic \(base64EncodedCredential)"
        config.HTTPAdditionalHeaders = ["Authorization" : authString]
        let session = NSURLSession(configuration: config)
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            print(data)
            //url connection method
            let daData = self.startParsing(data: data! as NSData)
            print(daData)
        }
        task.resume()
    }
    
    func startParsing(data :NSData) {
        let dict: NSDictionary!=(try! JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? NSDictionary

        for i in 0..<(dict.value(forKey: "Marvel") as! NSArray).count
        {
            roomsArrayDict.add((dict.value(forKey: "Marvel") as! NSArray)
        .object(at: i))
        }
        for i in 0..<(dict.value(forKey: "DC") as! NSArray).count
        {
            roomsArrayDict.add((dict.value(forKey: "DC") as! NSArray)
        .object(at: i))
        }
        tableView.reloadData()
    }
    
    var roomsArrayDict = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title

        [BasicCell.self, RightDetailCell.self, SwitchCell.self, DestructiveButtonCell.self].forEach { tableView.register($0) }
        
        navigationController?.navigationBar.prefersLargeTitles = true

        if !(navigationController?.viewControllers.first === self) {
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.rightBarButtonItem = nil
        }
        
        loadRooms()
    }

    @IBAction func doneTap(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        roomsArrayDict.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.row(at: indexPath) {
        case let .info(title, detail):
            let cell = tableView.dequeueReusableCell(withIdentifier: RightDetailCell.identifier)!
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = detail
            cell.selectionStyle = .none
            return cell
        case let .optionList(title, selectedOption, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: RightDetailCell.identifier)!
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = selectedOption
            cell.accessoryType = .disclosureIndicator
            return cell
        case let .toggle(title, isOn, updateHandler):
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell.identifier) as! SwitchCell
            cell.titleLabel.text = title
            cell.switchView.isOn = isOn
            cell.updateHandler = updateHandler
            return cell
        case let .destructiveButton(title, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: DestructiveButtonCell.identifier) as! DestructiveButtonCell
            cell.buttonLabel.text = title
            return cell
        case let .push(title, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: BasicCell.identifier)!
            cell.textLabel?.text = title
            cell.accessoryType = .disclosureIndicator
            return cell
        case let .editableText(title, text, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: RightDetailCell.identifier)!
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = text
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.row(at: indexPath) {
        case .info, .toggle:
            break
        case let .optionList(_, _, viewModelFactory):
            let sender = SelectOptionSegueSender(viewModelFactory: viewModelFactory, indexPath: indexPath)
            performSegue(withIdentifier: "selectOption", sender: sender)
        case let .destructiveButton(_, tapHandler):
            tableView.deselectRow(at: indexPath, animated: true)
            tapHandler()
        case let .push(_, viewControllerFactory):
            navigationController?.pushViewController(viewControllerFactory.makeViewController(), animated: true)
        case let .editableText(_, _, viewModelFactory):
            let sender = EditTextSegueSender(viewModelFactory: viewModelFactory, indexPath: indexPath)
            performSegue(withIdentifier: "editText", sender: sender)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "selectOption":
            let viewController = segue.destination as! SelectOptionViewController
            let sender = sender as! SelectOptionSegueSender
            viewController.viewModel = sender.viewModelFactory.makeSelectOptionViewModel()
            viewController.updateHandler = { self.tableView.cellForRow(at: sender.indexPath)?.detailTextLabel?.text = $0 }
        case "editText":
            let viewController = segue.destination as! EditTextViewController
            let sender = sender as! EditTextSegueSender
            viewController.viewModel = sender.viewModelFactory.makeEditTextViewModel()
            
            viewController.updateHandler = {
                if case let SettingsViewModelSection.Row.editableText(_, text, _) = self.viewModel.row(at: sender.indexPath) {
                    self.tableView.cellForRow(at: sender.indexPath)?.detailTextLabel?.text = text
                }
            }
        default:
            break
        }
    }
}
