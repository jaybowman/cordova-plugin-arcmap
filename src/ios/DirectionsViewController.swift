//
//  DirectionsViewController.swift
//  testPluginApp
//
//  Created by WebDev on 1/8/21.
//

import UIKit

class DirectionsViewController: UIViewController, UITableViewDataSource {
    var myDirections: [String]!
    var tableRows = 0
    
    init(directions: [String]){
        super.init(nibName: nil, bundle: nil)
        myDirections = directions
        tableRows = myDirections.count
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let  cell = UITableViewCell()
        cell.textLabel?.text = myDirections[indexPath.row]
        cell.imageView?.image = getDirectionImage(direction: myDirections[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Directions"
    }

    func getDirectionImage(direction: String) -> UIImage {
        var imgName = "square"
        if direction.contains("Turn left") {
            imgName = "arrow.turn.up.left"
        }
        else  if direction.contains("Turn right") {
            imgName = "arrow.turn.up.right"
        }
        else  if direction.contains("Bear left") {
            imgName = "arrow.up.left"
        }
        else  if direction.contains("Bear right") {
            imgName = "arrow.up.right"
        }
        else  if direction.contains("Continue") {
            imgName = "arrow.up"
        }
        else  if direction.contains("Go south") {
            imgName = "arrow.down"
        }
        else  if direction.contains("U-turn") {
            imgName = "arrow.uturn.down"
        }
        else  if direction.contains("Go north") {
            imgName = "arrow.up"
        }
        else  if direction.contains("Go east") {
            imgName = "arrow.right"
        }
        else  if direction.contains("Sharp Left") {
            imgName = "arrow.left"
        }
        else if direction.contains("Finish") {
            imgName = "flag"
        }
        
        return UIImage(systemName: imgName)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
