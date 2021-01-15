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
    private var room: Room!
    var roomName: String!
    var viewModel: SettingsViewModel!
    var roomsArrayDict = NSMutableArray()
    private let roomFactory = RoomFactory()
    
    private func resetRoom() {
        room = roomFactory.makeRoom()
    }
    
    func loadRooms() {
        let login = "AC3d6a6fca89c30fedee4940c46662adeb"
        let password = "dee1d9e0a89fc940181f2ef374ec05d1"

        let url = NSURL(string: "https://video.twilio.com/v1/Rooms?Status=in-progress&PageSize=20")
        let request = NSMutableURLRequest(url: url! as URL)

        let config = URLSessionConfiguration.default
        let userPasswordString = "\(login):\(password)"
        let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
        let base64EncodedCredential = userPasswordData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        let authString = "Basic \(base64EncodedCredential)"
        config.httpAdditionalHeaders = ["Authorization" : authString]
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            print(data ?? "")
            //url connection method
            let daData: () = self.startParsing(data: data! as NSData)
            print(daData)
        }
        task.resume()
    }
    
    func startParsing(data :NSData) {
        let dict: NSDictionary!=(try! JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? NSDictionary
        let roomsDict = dict.value(forKey: "rooms") as! NSArray

        for i in 0..<(dict.value(forKey: "rooms") as! NSArray).count
        {
            let roomName = (roomsDict[i] as? NSDictionary)?.value(forKey: "unique_name") as! String
            if !roomName.contains("network-test") {
                roomsArrayDict.add(roomName)
            }
        }
        refresh()
    }

    func refresh() {
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Rooms" // viewModel.title
        
        resetRoom()

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
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        roomsArrayDict.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BasicCell.identifier)!
        cell.textLabel?.text = roomsArrayDict[indexPath.row] as? String
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        roomName = roomsArrayDict[indexPath.row] as? String
        performSegue(withIdentifier: "roomSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "roomSegue":
            let roomViewController = segue.destination as! RoomViewController
            roomViewController.application = .shared
            roomViewController.viewModel = RoomViewModelFactory().makeRoomViewModel(
                roomName: roomName,
                room: room
            )
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let statsViewController = storyboard.instantiateViewController(withIdentifier: "statsViewController") as! StatsViewController
            statsViewController.videoAppRoom = room
            roomViewController.statsViewController = statsViewController
        case "showSettings":
            let navigationController = segue.destination as! UINavigationController
            let settingsViewController = navigationController.viewControllers.first as! SettingsViewController
            settingsViewController.viewModel = GeneralSettingsViewModel(
                appInfoStore: AppInfoStoreFactory().makeAppInfoStore(),
                appSettingsStore: AppSettingsStore.shared,
                authStore: AuthStore.shared
            )
        default:
            break
        }
    }

}
